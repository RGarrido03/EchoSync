import 'dart:async';
import 'dart:convert';

import 'package:echosync/data/device.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'device_info.dart';

class MeshNetwork {
  late final Device _device;
  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  final Map<String, Device> _connectedDevices = {};

  late MqttServerClient _client;
  bool _isConnected = false;

  static const String _baseTopic = 'echosync';
  late final String _deviceTopic;
  late final String _statusTopic;
  static const String _playbackTopic = '$_baseTopic/playback';
  static const String _queueTopic = '$_baseTopic/queue';

  MeshNetwork() {
    _deviceInfoService.deviceInfo.then((device) {
      _device = device;
      _deviceTopic = '$_baseTopic/device/${_device.ip}';
      _statusTopic = '$_baseTopic/status/${_device.ip}';
      _setupMqttClient();
    });
  }

  void _setupMqttClient() {
    _client = MqttServerClient('broker.hivemq.com', _device.ip);
    _client.port = 1883;
    _client.keepAlivePeriod = 20;
    _client.autoReconnect = true;

    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.onSubscribed = (topic) => print("Subscribed to $topic");
    _client.onSubscribeFail = (topic) => print("Failed to subscribe to $topic");
    _client.pongCallback = () => print('Ping response received');

    _client.updates?.listen(_onMessageReceived);
  }

  Future<void> connect() async {
    if (_isConnected) return;
    _client.connectionMessage =
        MqttConnectMessage()
            .withClientIdentifier(_device.ip)
            .startClean()
            .withWillTopic(_statusTopic)
            .withWillMessage('offline')
            .withWillQos(MqttQos.atLeastOnce)
            .withWillRetain();

    await _client.connect();
    if (_client.connectionStatus!.state != MqttConnectionState.connected) {
      print('Failed to connect to MQTT broker');
    }
  }

  Future<void> _publishDeviceInfo() async {
    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(_device.toJson()));

    _client.publishMessage(
      _deviceTopic,
      MqttQos.atLeastOnce,
      builder.payload!,
      retain: true,
    );
  }

  // Connection callback
  void _onConnected() async {
    _isConnected = true;
    print('Connected to MQTT broker');
    await _publishDeviceInfo();
    _client.subscribe('$_baseTopic/device/#', MqttQos.atLeastOnce);
    _client.subscribe('$_baseTopic/status/#', MqttQos.atLeastOnce);
    _client.subscribe(_playbackTopic, MqttQos.atLeastOnce);
    _client.subscribe(_queueTopic, MqttQos.atLeastOnce);
  }

  void _onDisconnected() {
    print('Disconnected from MQTT broker');
    _isConnected = false;
    _connectedDevices.clear();
  }

  void _onMessageReceived(List<MqttReceivedMessage<MqttMessage>>? c) {
    if (c == null || c.isEmpty) return;

    final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
    final String topic = c[0].topic;
    final String payload = MqttPublishPayload.bytesToStringAsString(
      recMess.payload.message,
    );
    final Map<String, dynamic> data = jsonDecode(payload);
    if (topic.startsWith('$_baseTopic/status/')) {
      _handleDeviceStatus(topic, payload);
    } else if (topic.startsWith('$_baseTopic/device/')) {
      _handleDeviceAdd(topic, data);
    }
  }

  void _handleDeviceStatus(String topic, String data) {
    final deviceIp = topic.split('/').last;
    if (deviceIp == _device.ip) return;
    if (data != 'offline') return;
    _connectedDevices.remove(deviceIp);
  }

  void _handleDeviceAdd(String topic, Map<String, dynamic> data) {
    final deviceIp = topic.split('/').last;
    if (deviceIp == _device.ip) return;
    _connectedDevices[deviceIp] = Device.fromJson(data);
  }

  void _handleAppMessage(Map<String, dynamic> data) {
    if (!data.containsKey('senderId')) {
      data['senderId'] = data['sender_id'] ?? 'unknown';
    }
  }

  // Send message to specific device
  Future<bool> sendToDevice(
    String deviceId,
    Map<String, dynamic> message,
  ) async {
    if (!_isConnected) return false;

    try {
      // Add sender information
      message['senderId'] = _device.ip;
      message['senderName'] = _device.name;

      final builder = MqttClientPayloadBuilder();
      builder.addString(json.encode(message));

      _client.publishMessage(
        '$_baseTopic/device/$deviceId',
        MqttQos.atLeastOnce,
        builder.payload!,
      );
      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  // Create or join a specific session
  Future<bool> joinSession(String sessionId) async {
    if (!_isConnected) return false;

    try {
      // Subscribe to session-specific topics
      _client.subscribe('$_baseTopic/session/$sessionId', MqttQos.atLeastOnce);

      // Announce joining the session
      final message = {
        'type': 'join_session',
        'sessionId': sessionId,
        'deviceId': _device.ip,
        'deviceName': _device.name,
      };

      final builder = MqttClientPayloadBuilder();
      builder.addString(json.encode(message));

      _client.publishMessage(
        '$_baseTopic/session/$sessionId',
        MqttQos.atLeastOnce,
        builder.payload!,
      );
      return true;
    } catch (e) {
      print('Error joining session: $e');
      return false;
    }
  }

  // Leave a session
  Future<void> leaveSession(String sessionId) async {
    if (!_isConnected) return;

    try {
      // Announce leaving the session
      final message = {
        'type': 'leave_session',
        'sessionId': sessionId,
        'deviceId': _device.ip,
      };

      final builder = MqttClientPayloadBuilder();
      builder.addString(json.encode(message));

      _client.publishMessage(
        '$_baseTopic/session/$sessionId',
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      // Unsubscribe from session
      _client.unsubscribe('$_baseTopic/session/$sessionId');
    } catch (e) {
      print('Error leaving session: $e');
    }
  }

  Future<void> disconnect() async {
    if (!_isConnected) {
      return;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString('offline');

    _client.publishMessage(
      '$_baseTopic/status/${_device.ip}',
      MqttQos.atLeastOnce,
      builder.payload!,
      retain: true,
    );
    _client.disconnect();
  }

  // Clean up resources
  void dispose() {
    disconnect();
    _connectionStateController.close();
    _messageController.close();
  }
}
