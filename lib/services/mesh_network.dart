// lib/services/mesh_network.dart
import 'dart:async';
import 'dart:convert';

import 'package:echosync/data/protocol/base.dart';
import 'package:echosync/data/protocol/playback.dart';
import 'package:echosync/data/protocol/queue.dart';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'package:mqtt_server/mqtt_server.dart';
import '../data/device.dart';
import '../data/protocol/device.dart';
import '../data/protocol/sync.dart';
import 'file_server.dart';

// Stream containers for different message types
class MeshNetworkStreams {
  final StreamController<Map<String, Device>> _devicesController =
      StreamController.broadcast();
  final StreamController<PlaybackState> _playbackStateController =
      StreamController.broadcast();
  final StreamController<QueueState> _queueStateController =
      StreamController.broadcast();
  final StreamController<PlaybackCommand> _playbackCommandController =
      StreamController.broadcast();
  final StreamController<QueueCommand> _queueCommandController =
      StreamController.broadcast();
  final StreamController<TimeSyncMessage> _timeSyncController =
      StreamController.broadcast();

  Stream<Map<String, Device>> get devicesStream => _devicesController.stream;

  Stream<PlaybackState> get playbackStateStream =>
      _playbackStateController.stream;

  Stream<QueueState> get queueStateStream => _queueStateController.stream;

  Stream<PlaybackCommand> get playbackCommandStream =>
      _playbackCommandController.stream;

  Stream<QueueCommand> get queueCommandStream => _queueCommandController.stream;

  Stream<TimeSyncMessage> get timeSyncMessageStream =>
      _timeSyncController.stream;

  void dispose() {
    _devicesController.close();
    _playbackStateController.close();
    _queueStateController.close();
    _playbackCommandController.close();
    _queueCommandController.close();
    _timeSyncController.close();
  }
}

class MeshNetwork {
  late final Device _device;
  late final FileServerService _fileServer;
  final Map<String, Device> _connectedDevices = {};
  late MqttServerClient _client;
  late String? brokerIp__;
  late MqttBroker _mqttBroker;
  bool _isConnected = false;
  final MeshNetworkStreams _streams = MeshNetworkStreams();

  // Topics
  static const String _baseTopic = 'echosync';
  static const String playbackStateTopic = '$_baseTopic/playback/state';
  static const String queueStateTopic = '$_baseTopic/queue/state';
  static const String deviceRegistryTopic = '$_baseTopic/devices/registry';
  static const String playbackCommandTopic = '$_baseTopic/playback/command';
  static const String queueCommandTopic = '$_baseTopic/queue/command';
  static const String deviceControlTopic = '$_baseTopic/devices/control';
  static const String timeSyncTopic = '$_baseTopic/time/sync';

  // Getters
  Device get device => _device;

  MeshNetworkStreams get streams => _streams;

  Map<String, Device> get connectedDevices =>
      Map.unmodifiable(_connectedDevices);

  bool get isConnected => _isConnected;

  MeshNetwork({required Device deviceInfo, String? brokerIp}) {
    _device = deviceInfo;
    _fileServer = FileServerService();
    brokerIp__ = brokerIp;
    if (brokerIp == null) {
      brokerIp__ = deviceInfo.ip;
      _setupMqttBroker();
    }
    _setupMqttClient();
  }

  void _setupMqttBroker() {
    // Initialize the MQTT server with the device's IP
    final brokerConfig = MqttBrokerConfig(
      port: 1883,
      sessionExpiryInterval: Duration(hours: 1),
    );
    _mqttBroker = MqttBroker(brokerConfig);

    debugPrint("I am at setupMqttBroker");
  }

  void _setupMqttClient() {
    _client = MqttServerClient(brokerIp__ ?? _device.ip, _device.ip);
    _client.port = 1883;

    _client.keepAlivePeriod = 20;
    _client.autoReconnect = true;
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.onSubscribed = (topic) => debugPrint("Subscribed to $topic");
    _client.onSubscribeFail =
        (topic) => debugPrint("Failed to subscribe to $topic");
    debugPrint("I am at setupMqttClient");
    _client.setProtocolV311();
  }

  Future<void> connect() async {
    debugPrint("I am at connect");
    if (brokerIp__ == _device.ip) {
      await _mqttBroker.start();
    }

    debugPrint("I am at connect2");

    if (_isConnected) return;
    debugPrint("I am at connect3");

    await _fileServer.initialize();
    final serverStarted = await _fileServer.startServer();
    debugPrint("I am at connect4");

    if (!serverStarted) {
      debugPrint('Warning: File server failed to start');
    }
    // For now useless...
    final willMessage = DeviceControl.leave(_device);
    _client.connectionMessage =
        MqttConnectMessage()
            .withClientIdentifier(_device.ip)
            .withProtocolVersion(MqttClientConstants.mqttV311ProtocolVersion)
            .startClean()
            .withWillQos(MqttQos.exactlyOnce)
            .withWillRetain();
    //         .startClean()
    //         .withWillTopic(deviceControlTopic)
    //         .withWillMessage(jsonEncode(willMessage.toJson()))
    //         .withWillQos(MqttQos.atLeastOnce)
    //         .withWillRetain().withProtocolVersion(MqttClientConstants.mqttV311ProtocolVersion);

    debugPrint("I am at connect5");
    await _client.connect();
    debugPrint("I am at connect6");

    if (_client.connectionStatus!.state != MqttConnectionState.connected) {
      throw Exception('Failed to connect to MQTT broker');
    }

    _client.updates!.listen(_onMessageReceived);
  }

  void _onConnected() async {
    debugPrint("I am at _onConnect");

    _isConnected = true;
    debugPrint('Connected to MQTT broker');
    await _subscribeToTopics();
    await _announceDeviceJoin();
  }

  Future<void> _subscribeToTopics() async {
    _client.subscribe(playbackStateTopic, MqttQos.atLeastOnce);
    _client.subscribe(queueStateTopic, MqttQos.atLeastOnce);
    _client.subscribe(deviceRegistryTopic, MqttQos.atLeastOnce);
    _client.subscribe(playbackCommandTopic, MqttQos.atLeastOnce);
    _client.subscribe(queueCommandTopic, MqttQos.atLeastOnce);
    _client.subscribe(deviceControlTopic, MqttQos.atLeastOnce);
    _client.subscribe(timeSyncTopic, MqttQos.atLeastOnce);
  }

  Future<void> _announceDeviceJoin() async {
    final joinMessage = DeviceControl.join(_device);
    await _publishMessage(
      deviceControlTopic,
      joinMessage.toJson(),
      retain: false,
    );
  }

  void _onDisconnected() {
    debugPrint('Disconnected from MQTT broker');
    _isConnected = false;
    _connectedDevices.clear();
    _streams._devicesController.add({});
  }

  void _onMessageReceived(List<MqttReceivedMessage<MqttMessage>>? c) {
    if (c == null || c.isEmpty) return;

    for (final message in c) {
      final MqttPublishMessage pubMessage =
          message.payload as MqttPublishMessage;
      final String topic = message.topic;
      final String payload = MqttPublishPayload.bytesToStringAsString(
        pubMessage.payload.message,
      );

      try {
        final Map<String, dynamic> data = jsonDecode(payload);
        _handleMessage(topic, data);
      } catch (e) {
        debugPrint('Error parsing message from $topic: $e');
      }
    }
  }

  void _handleMessage(String topic, Map<String, dynamic> data) {
    debugPrint("Received message on topic: $topic at ${DateTime.now()}");

    switch (topic) {
      case playbackStateTopic:
        final state = PlaybackState.fromJson(data);
        _streams._playbackStateController.add(state);
        break;

      case queueStateTopic:
        final state = QueueState.fromJson(data);
        _streams._queueStateController.add(state);
        break;

      case deviceRegistryTopic:
        final registry = DeviceRegistry.fromJson(data);
        _connectedDevices.clear();
        _connectedDevices.addAll(registry.devices);
        _streams._devicesController.add(Map.from(_connectedDevices));
        break;

      case playbackCommandTopic:
        final command = PlaybackCommand.fromJson(data);
        _streams._playbackCommandController.add(command);
        break;

      case queueCommandTopic:
        final command = QueueCommand.fromJson(data);
        if (command.senderId != _device.ip) {
          _streams._queueCommandController.add(command);
        }
        break;

      case deviceControlTopic:
        final control = DeviceControl.fromJson(data);
        if (control.device.ip != _device.ip) {
          _handleDeviceControl(control);
        }
        break;

      case timeSyncTopic:
        final syncMessage = TimeSyncMessage.fromJson(data);
        if (syncMessage.senderId != _device.ip) {
          _streams._timeSyncController.add(syncMessage);
        }
        break;
    }
  }

  void _handleDeviceControl(DeviceControl control) {
    debugPrint(
      "Handling device control: ${control.action} for ${control.device.ip}",
    );

    switch (control.action) {
      case 'join':
        _connectedDevices[control.device.ip] = control.device;
        break;
      case 'leave':
        _connectedDevices.remove(control.device.ip);
        break;
      case 'update':
        _connectedDevices[control.device.ip] = control.device;
        break;
    }
    _updateDeviceRegistry();
  }

  Future<void> _updateDeviceRegistry() async {
    final registry = DeviceRegistry(
      devices: Map.from(_connectedDevices),
      lastUpdated: NetworkTime.now(),
    );
    await _publishMessage(deviceRegistryTopic, registry.toJson(), retain: true);
    _streams._devicesController.add(Map.from(_connectedDevices));
  }

  Future<void> _publishMessage(
    String topic,
    Map<String, dynamic> message, {
    bool retain = false,
  }) async {
    if (!_isConnected) return;

    try {
      final builder = MqttClientPayloadBuilder();
      builder.addString(jsonEncode(message));
      _client.publishMessage(
        topic,
        MqttQos.atLeastOnce,
        builder.payload!,
        retain: retain,
      );
    } catch (e) {
      debugPrint('Error publishing message to $topic: $e');
    }
  }

  // Public methods for publishing messages
  Future<void> publishPlaybackCommand(PlaybackCommand command) async {
    await _publishMessage(playbackCommandTopic, command.toJson());
  }

  Future<void> publishQueueCommand(QueueCommand command) async {
    await _publishMessage(queueCommandTopic, command.toJson());
  }

  Future<void> publishTimeSyncMessage(TimeSyncMessage message) async {
    await _publishMessage(timeSyncTopic, message.toJson());
  }

  Future<void> publishPlaybackState(PlaybackState state) async {
    await _publishMessage(playbackStateTopic, state.toJson(), retain: true);
  }

  Future<void> publishQueueState(QueueState state) async {
    await _publishMessage(queueStateTopic, state.toJson(), retain: true);
  }

  Future<void> disconnect() async {
    if (!_isConnected) return;

    final leaveMessage = DeviceControl.leave(_device);
    await _publishMessage(deviceControlTopic, leaveMessage.toJson());
    _client.disconnect();
  }

  void dispose() {
    disconnect();
    _streams.dispose();
  }
}
