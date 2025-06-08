// lib/services/mesh_network.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:echosync/data/protocol/base.dart';
import 'package:echosync/data/protocol/playback.dart';
import 'package:echosync/data/protocol/queue.dart';
import 'package:echosync/data/song.dart';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../data/device.dart';
import '../data/protocol/device.dart';
import '../data/protocol/sync.dart';

class MeshNetwork {
  late final Device _device;
  late final Directory tempDir;
  final Map<String, Device> _connectedDevices = {};
  late MqttServerClient _client;
  bool _isConnected = false;

  // Topics
  static const String _baseTopic = 'echosync';
  static const String playbackStatusTopic = '$_baseTopic/playback/status';
  static const String queueStatusTopic = '$_baseTopic/queue/status';
  static const String deviceRegistryTopic = '$_baseTopic/devices/status';
  static const String playbackControlTopic = '$_baseTopic/playback/control';
  static const String queueControlTopic = '$_baseTopic/queue/control';
  static const String deviceControlTopic = '$_baseTopic/devices/control';
  static const String timeSyncTopic = '$_baseTopic/time/sync';

  // State storage
  PlaybackStatus? _currentPlaybackStatus;
  QueueStatus? _currentQueueStatus;

  // Getters for current state
  PlaybackStatus? get currentPlaybackStatus => _currentPlaybackStatus;

  QueueStatus? get currentQueueStatus => _currentQueueStatus;

  Map<String, Device> get connectedDevices =>
      Map.unmodifiable(_connectedDevices);

  MeshNetwork({required Device deviceInfo, required this.tempDir}) {
    _device = deviceInfo;
    _setupMqttClient();
  }

  final StreamController<Map<String, Device>> _devicesController =
      StreamController.broadcast();
  final StreamController<PlaybackStatus> _playbackStatusController =
      StreamController.broadcast();
  final StreamController<QueueStatus> _queueStatusController =
      StreamController.broadcast();
  final StreamController<TimeSyncMessage> _timeSyncController =
      StreamController.broadcast();

  // Expose streams for BLoCs to listen to
  Stream<Map<String, Device>> get devicesStream => _devicesController.stream;

  Stream<PlaybackStatus> get playbackStatusStream =>
      _playbackStatusController.stream;

  Stream<QueueStatus> get queueStatusStream => _queueStatusController.stream;

  Stream<TimeSyncMessage> get timeSyncMessageStream =>
      _timeSyncController.stream;

  void _setupMqttClient() {
    _client = MqttServerClient('192.168.1.2', _device.ip);
    _client.port = 1883;
    _client.keepAlivePeriod = 20;
    _client.autoReconnect = true;
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.onSubscribed = (topic) => debugPrint("Subscribed to $topic");
    _client.onSubscribeFail =
        (topic) => debugPrint("Failed to subscribe to $topic");
  }

  Future<void> connect() async {
    if (_isConnected) return;

    final willMessage = DeviceControl.leave(_device);
    _client.connectionMessage =
        MqttConnectMessage()
            .withClientIdentifier(_device.ip)
            .startClean()
            .withWillTopic(deviceControlTopic)
            .withWillMessage(jsonEncode(willMessage.toJson()))
            .withWillQos(MqttQos.atLeastOnce)
            .withWillRetain();

    await _client.connect();

    if (_client.connectionStatus!.state != MqttConnectionState.connected) {
      throw Exception('Failed to connect to MQTT broker');
    }

    _client.updates!.listen(_onMessageReceived);
  }

  void _onConnected() async {
    _isConnected = true;
    debugPrint('Connected to MQTT broker');
    await _subscribeToTopics();
    await _announceDeviceJoin();
  }

  Future<void> _subscribeToTopics() async {
    _client.subscribe(playbackStatusTopic, MqttQos.atLeastOnce);
    _client.subscribe(queueStatusTopic, MqttQos.atLeastOnce);
    _client.subscribe(deviceRegistryTopic, MqttQos.atLeastOnce);
    _client.subscribe(playbackControlTopic, MqttQos.atLeastOnce);
    _client.subscribe(queueControlTopic, MqttQos.atLeastOnce);
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
    // Emit to stream instead of directly notifying BLoC
    _devicesController.add({});
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
      case playbackStatusTopic:
        final status = PlaybackStatus.fromJson(data);
        _currentPlaybackStatus = status;
        // Emit to stream instead of directly notifying BLoC
        _playbackStatusController.add(status);
        break;

      case queueStatusTopic:
        final status = QueueStatus.fromJson(data);
        _currentQueueStatus = status;
        _queueStatusController.add(status);
        break;

      case deviceRegistryTopic:
        final registry = DeviceRegistry.fromJson(data);
        _connectedDevices.clear();
        _connectedDevices.addAll(registry.devices);
        // Emit to stream instead of directly notifying BLoC
        _devicesController.add(Map.from(_connectedDevices));
        break;

      case playbackControlTopic:
        final control = PlaybackControl.fromJson(data);
        if (control.deviceIp != _device.ip) {
          // Handle playback control in SyncManager logic
          _handlePlaybackControl(control);
        }
        break;

      case queueControlTopic:
        final control = QueueControl.fromJson(data);
        if (control.deviceId != _device.ip) {
          // Handle queue control in SyncManager logic
          _handleQueueControl(control);
        }
        break;

      case deviceControlTopic:
        final control = DeviceControl.fromJson(data);
        debugPrint(
          "Received device control: ${control.device.ip}, host is ${_device.ip}",
        );
        if (control.device.ip != _device.ip) {
          debugPrint("Adding IP ${control.device.ip}");
          _handleDeviceControl(control);
        }
        break;

      case timeSyncTopic:
        final syncMessage = TimeSyncMessage.fromJson(data);
        if (syncMessage.senderId != _device.ip) {
          _timeSyncController.add(syncMessage);
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
    // Emit to stream instead of directly notifying BLoC
    _devicesController.add(Map.from(_connectedDevices));
  }

  // Forward playback control to SyncManager
  void _handlePlaybackControl(PlaybackControl control) {
    // This will be handled by SyncManager when it receives the message
    // For now, we could store it and let SyncManager retrieve it
    debugPrint('Received playback control: ${control.command}');
  }

  // Forward queue control to SyncManager
  void _handleQueueControl(QueueControl control) {
    if (control.deviceId == _device.ip) {
      return;
    }
    final song = control.params?['song'] as Song?;
    if (song == null) {
      return;
    }
    if (song.bytes != null) {
      final file = File('${tempDir.path}/${song.hash}');
      file.writeAsBytesSync(song.bytes!);
      debugPrint('Saved song ${song.title} to ${file.path}');
    }
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

  // Public methods for sending messages
  Future<void> sendPlaybackControl(PlaybackControl control) async {
    await _publishMessage(playbackControlTopic, control.toJson());
  }

  Future<void> sendQueueControl(QueueControl control) async {
    await _publishMessage(queueControlTopic, control.toJson());
  }

  Future<void> sendTimeSyncMessage(TimeSyncMessage message) async {
    await _publishMessage(timeSyncTopic, message.toJson());
  }

  Future<void> updatePlaybackStatus(PlaybackStatus status) async {
    _currentPlaybackStatus = status;
    await _publishMessage(playbackStatusTopic, status.toJson(), retain: true);
  }

  Future<void> updateQueueStatus(QueueStatus status) async {
    _currentQueueStatus = status;
    await _publishMessage(queueStatusTopic, status.toJson(), retain: true);
  }

  Future<void> disconnect() async {
    if (!_isConnected) return;

    final leaveMessage = DeviceControl.leave(_device);
    await _publishMessage(deviceControlTopic, leaveMessage.toJson());
    _client.disconnect();
  }

  void dispose() {
    disconnect();
    _devicesController.close();
    _playbackStatusController.close();
    _queueStatusController.close();
    _timeSyncController.close();
  }
}
