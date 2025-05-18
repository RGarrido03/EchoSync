import 'dart:async';
import 'dart:convert';

import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/device.dart';
import 'device_info.dart';

class NearbyService {
  static const String _serviceId = 'pt.ua.deti.icm.echosync';
  final Nearby _nearby = Nearby();
  late final Device _device;
  final DeviceInfoService _deviceInfoService = DeviceInfoService();

  // Stream controllers for network events
  final _connectionStateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  // Streams for UI to listen to
  Stream<Map<String, dynamic>> get connectionStream =>
      _connectionStateController.stream;

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  NearbyService() {
    _deviceInfoService.deviceInfo.then((device) {
      _device = device;
    });
  }

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

  Future<void> startAdvertising() async {
    try {
      await _nearby.startAdvertising(
        _device.ip,
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

  Future<void> startDiscovery() async {
    try {
      await _nearby.startDiscovery(
        _device.ip,
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

  void _onEndpointFound(
    String endpointId,
    String endpointName,
    String serviceId,
  ) {
    _nearby.requestConnection(
      _device.ip,
      endpointId,
      onConnectionInitiated: _onConnectionInitiated,
      onConnectionResult: _onConnectionResult,
      onDisconnected: _onDisconnected,
    );
  }

  void _onPayloadReceived(String endpointId, Payload payload) {
    if (payload.type == PayloadType.BYTES) {
      final String message = String.fromCharCodes(payload.bytes!);
      final Map<String, dynamic> data = jsonDecode(message);

      data['senderId'] = endpointId;
      _messageController.add(data);
    }
  }

  void _onConnectionResult(String endpointId, Status status) {
    if (status == Status.CONNECTED) {
      _connectionStateController.add({
        'type': 'connected',
        'deviceId': endpointId,
      });
    }
  }

  // Handle disconnection
  void _onDisconnected(String endpointId) {
    _connectionStateController.add({
      'type': 'disconnected',
      'deviceId': endpointId,
    });
  }

  // Handle lost endpoint
  void _onEndpointLost(String? endpointId) {
    _connectionStateController.add({
      'type': 'endpoint_lost',
      'deviceId': endpointId,
    });
  }

  Future<void> stop() async {
    await _nearby.stopAdvertising();
    await _nearby.stopDiscovery();
    await _nearby.stopAllEndpoints();
  }

  void dispose() {
    _connectionStateController.close();
    _messageController.close();
    stop();
  }
}
