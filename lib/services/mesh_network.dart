// lib/services/mesh_network.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class MeshNetwork {
  static const String _serviceId = 'com.musicmesh.service';
  final Nearby _nearby = Nearby();
  final String _deviceId = Uuid().v4();
  final Map<String, String> _connectedDevices = {};

  // Stream controllers for network events
  final _connectionStateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  // Streams for UI to listen to
  Stream<Map<String, dynamic>> get connectionStream =>
      _connectionStateController.stream;

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  // Initialization
  Future<bool> initialize() async {
    final permissions = [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.nearbyWifiDevices,
    ];

    for (var permission in permissions) {
      if (!await permission.isGranted) {
        final status = await permission.request();
        if (!status.isGranted) return false;
      }
    }

    return true;
  }

  // Start advertising this device
  Future<void> startAdvertising() async {
    try {
      await _nearby.startAdvertising(
        _deviceId,
        Strategy.P2P_CLUSTER,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
        serviceId: _serviceId,
      );
    } catch (e) {
      _connectionStateController.add({
        'type': 'error',
        'message': 'Failed to start advertising: $e',
      });
    }
  }

  // Start discovering other devices
  Future<void> startDiscovery() async {
    try {
      await _nearby.startDiscovery(
        _deviceId,
        Strategy.P2P_CLUSTER,
        onEndpointFound: _onEndpointFound,
        onEndpointLost: _onEndpointLost,
        serviceId: _serviceId,
      );
    } catch (e) {
      _connectionStateController.add({
        'type': 'error',
        'message': 'Failed to start discovery: $e',
      });
    }
  }

  // Handle new connection request
  void _onConnectionInitiated(
    String endpointId,
    ConnectionInfo connectionInfo,
  ) {
    _nearby.acceptConnection(
      endpointId,
      onPayLoadRecieved:
          (endpointId, payload) => _onPayloadReceived(endpointId, payload),
      onPayloadTransferUpdate: (endpointId, update) {},
    );
  }

  // Handle successful connection
  void _onConnectionResult(String endpointId, Status status) {
    if (status == Status.CONNECTED) {
      _connectedDevices[endpointId] = endpointId;
      _connectionStateController.add({
        'type': 'connected',
        'deviceId': endpointId,
      });
    }
  }

  // Handle disconnection
  void _onDisconnected(String endpointId) {
    _connectedDevices.remove(endpointId);
    _connectionStateController.add({
      'type': 'disconnected',
      'deviceId': endpointId,
    });
  }

  // Handle discovered endpoint
  void _onEndpointFound(
    String endpointId,
    String endpointName,
    String serviceId,
  ) {
    _nearby.requestConnection(
      _deviceId,
      endpointId,
      onConnectionInitiated: _onConnectionInitiated,
      onConnectionResult: _onConnectionResult,
      onDisconnected: _onDisconnected,
    );
  }

  // Handle lost endpoint
  void _onEndpointLost(String? endpointId) {
    _connectionStateController.add({
      'type': 'endpoint_lost',
      'deviceId': endpointId,
    });
  }

  // Handle received payload
  void _onPayloadReceived(String endpointId, Payload payload) {
    if (payload.type == PayloadType.BYTES) {
      final String message = String.fromCharCodes(payload.bytes!);
      final Map<String, dynamic> data = json.decode(message);

      data['senderId'] = endpointId;
      _messageController.add(data);
    }
  }

  // Send message to specific device
  Future<bool> sendToDevice(
    String endpointId,
    Map<String, dynamic> message,
  ) async {
    try {
      final bytes = Uint8List.fromList(utf8.encode(json.encode(message)));
      await _nearby.sendBytesPayload(endpointId, bytes);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Broadcast message to all connected devices
  Future<void> broadcast(Map<String, dynamic> message) async {
    for (String endpointId in _connectedDevices.keys) {
      await sendToDevice(endpointId, message);
    }
  }

  // Stop advertising and discovery
  Future<void> stop() async {
    await _nearby.stopAdvertising();
    await _nearby.stopDiscovery();
    await _nearby.stopAllEndpoints();
    _connectedDevices.clear();
  }

  // Cleanup resources
  void dispose() {
    _connectionStateController.close();
    _messageController.close();
    stop();
  }
}
