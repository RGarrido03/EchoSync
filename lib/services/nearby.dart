import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/device.dart';
import 'device_info.dart';

class NearbyService {
  static const String _serviceId = 'pt.ua.deti.icm.echosync';
  final Nearby _nearby = Nearby();
  Device? _device;
  final DeviceInfoService _deviceInfoService = DeviceInfoService();

  // Stream controllers for network events
  final _connectionStateController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _discoveredDevicesController = StreamController<Map<String, String>>.broadcast();

  // Streams for UI to listen to
  Stream<Map<String, dynamic>> get connectionStream => _connectionStateController.stream;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, String>> get discoveredDevicesStream => _discoveredDevicesController.stream;

  Map<String, String> _discoveredDevices = {};

  Future<bool> initialize() async {
    try {
      _device = await _deviceInfoService.deviceInfo;

      // Solicitar todas as permissões necessárias
      final permissions = await _requestAllPermissions();
      if (!permissions) {
        debugPrint('NearbyService: Permissions denied');
        return false;
      }

      debugPrint('NearbyService: Initialized successfully with device: ${_device?.name}');
      return true;
    } catch (e) {
      debugPrint('NearbyService: Initialization failed: $e');
      return false;
    }
  }

  Future<bool> _requestAllPermissions() async {
    final permissions = [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.nearbyWifiDevices,
    ];

    // Verificar versão do Android para permissões específicas
    for (var permission in permissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        debugPrint('NearbyService: Requesting permission: $permission');
        final result = await permission.request();
        if (!result.isGranted) {
          debugPrint('NearbyService: Permission denied: $permission');
          return false;
        }
      }
    }
    return true;
  }

  Future<bool> startAdvertising() async {
    if (_device == null) {
      debugPrint('NearbyService: Device not initialized');
      return false;
    }

    try {
      debugPrint('NearbyService: Starting advertising as ${_device!.name}');

      bool result = await _nearby.startAdvertising(
        _device!.ip,
        Strategy.P2P_CLUSTER,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
        serviceId: _serviceId,
      );

      debugPrint('NearbyService: Advertising started: $result');
      return result;
    } catch (e) {
      debugPrint('NearbyService: Failed to start advertising: $e');
      _connectionStateController.add({
        'type': 'error',
        'message': 'Failed to start advertising: $e',
      });
      return false;
    }
  }

  Future<bool> startDiscovery() async {
    if (_device == null) {
      debugPrint('NearbyService: Device not initialized');
      return false;
    }

    try {
      debugPrint('NearbyService: Starting discovery as ${_device!.name}');

      bool result = await _nearby.startDiscovery(
        _device!.name, // Use device name instead of IP
        Strategy.P2P_CLUSTER,
        onEndpointFound: _onEndpointFound,
        onEndpointLost: _onEndpointLost,
        serviceId: _serviceId,
      );

      debugPrint('NearbyService: Discovery started: $result');
      return result;
    } catch (e) {
      debugPrint('NearbyService: Failed to start discovery: $e');
      _connectionStateController.add({
        'type': 'error',
        'message': 'Failed to start discovery: $e',
      });
      return false;
    }
  }

  void _onConnectionInitiated(String endpointId, ConnectionInfo connectionInfo) {
    debugPrint('NearbyService: Connection initiated with $endpointId');

    _nearby.acceptConnection(
      endpointId,
      onPayLoadRecieved: (endpointId, payload) => _onPayloadReceived(endpointId, payload),
      onPayloadTransferUpdate: (endpointId, update) {
        debugPrint('NearbyService: Payload transfer update: $endpointId');
      },
    );
  }

  void _onEndpointFound(String endpointId, String endpointName, String serviceId) {
    debugPrint('NearbyService: Endpoint found - ID: $endpointId, Name: $endpointName, Service: $serviceId');

    // Adicionar à lista de dispositivos descobertos
    _discoveredDevices[endpointId] = endpointName;
    _discoveredDevicesController.add(Map.from(_discoveredDevices));

  }

  Future<void> requestConnectionToEndpoint(String endpointId) async {
    if (_device == null) return;

    debugPrint('NearbyService: Requesting connection to ($endpointId)');
    await _nearby.requestConnection(
      _device!.name,
      endpointId,
      onConnectionInitiated: _onConnectionInitiated,
      onConnectionResult: _onConnectionResult,
      onDisconnected: _onDisconnected,
    );
  }


  void _onPayloadReceived(String endpointId, Payload payload) {
    if (payload.type == PayloadType.BYTES) {
      try {
        final String message = String.fromCharCodes(payload.bytes!);
        final Map<String, dynamic> data = jsonDecode(message);
        data['senderId'] = endpointId;
        _messageController.add(data);
        debugPrint('NearbyService: Message received from $endpointId: $data');
      } catch (e) {
        debugPrint('NearbyService: Failed to parse message: $e');
      }
    }
  }

  void _onConnectionResult(String endpointId, Status status) {
    debugPrint('NearbyService: Connection result with $endpointId: $status');

    if (status == Status.CONNECTED) {
      _connectionStateController.add({
        'type': 'connected',
        'deviceId': endpointId,
      });

      // Enviar informações MQTT quando conectado
      _sendMqttInfo(endpointId);
    } else {
      debugPrint('NearbyService: Connection failed with $endpointId');
    }
  }

  void _sendMqttInfo(String endpointId) {
    if (_device == null) return;

    final mqttInfo = {
      'type': 'mqtt_info',
      'brokerIp': _device!.ip,
      'port': 1883,
      'deviceInfo': _device!.toJson(),
    };

    final message = jsonEncode(mqttInfo);
    _nearby.sendBytesPayload(endpointId, Uint8List.fromList(message.codeUnits));
    debugPrint('NearbyService: Sent MQTT info to $endpointId');
  }

  void _onDisconnected(String endpointId) {
    debugPrint('NearbyService: Disconnected from $endpointId');

    _discoveredDevices.remove(endpointId);
    _discoveredDevicesController.add(Map.from(_discoveredDevices));

    _connectionStateController.add({
      'type': 'disconnected',
      'deviceId': endpointId,
    });
  }

  void _onEndpointLost(String? endpointId) {
    if (endpointId != null) {
      debugPrint('NearbyService: Endpoint lost: $endpointId');

      _discoveredDevices.remove(endpointId);
      _discoveredDevicesController.add(Map.from(_discoveredDevices));

      _connectionStateController.add({
        'type': 'endpoint_lost',
        'deviceId': endpointId,
      });
    }
  }

  Future<void> stop() async {
    debugPrint('NearbyService: Stopping all services');
    await _nearby.stopAdvertising();
    await _nearby.stopDiscovery();
    await _nearby.stopAllEndpoints();
    _discoveredDevices.clear();
    _discoveredDevicesController.add({});
  }

  void dispose() {
    _connectionStateController.close();
    _messageController.close();
    _discoveredDevicesController.close();
    stop();
  }
}
