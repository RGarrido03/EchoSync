// lib/bloc/mesh_network/mesh_network_bloc.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/device.dart';
import '../../services/mesh_network.dart';
import '../../services/nearby.dart';

part 'mesh_network_event.dart';

part 'mesh_network_state.dart';

class MeshNetworkBloc extends Bloc<MeshNetworkEvent, MeshNetworkState> {
  MeshNetwork? _meshNetwork;
  StreamSubscription<Map<String, Device>>? _devicesSubscription;
  String _testBrokerIp = '192.168.1.107';

  NearbyService? _nearbyService;
  StreamSubscription<Map<String, String>>? _nearbyDiscoverySubscription;
  StreamSubscription<Map<String, dynamic>>? _nearbyConnectionSubscription;
  StreamSubscription<Map<String, dynamic>>? _nearbyMessageSubscription;
  Map<String, String> discoveredDevices = {};

  MeshNetwork? get meshNetwork => _meshNetwork;

  MeshNetworkBloc() : super(MeshNetworkInitial()) {
    on<InitializeMeshNetwork>(_onInitialize);
    on<ConnectMeshNetwork>(_onConnect);
    on<DisconnectMeshNetwork>(_onDisconnect);
    on<UpdateConnectedDevices>(_onUpdateDevices);

    on<StartDeviceDiscovery>(_onStartDeviceDiscovery);
    on<StopDeviceDiscovery>(_onStopDeviceDiscovery);
    on<DiscoveredDeviceFound>(_onDiscoveredDeviceFound);
    on<ConnectToDiscoveredDevice>(_onConnectToDiscoveredDevice);
    on<ShareNetworkInfo>(_onShareNetworkInfo);
  }

  Future<void> _onInitialize(
    InitializeMeshNetwork event,
    Emitter<MeshNetworkState> emit,
  ) async {
    try {
      emit(MeshNetworkInitializing());
      _meshNetwork = MeshNetwork(deviceInfo: event.device);
      _devicesSubscription = _meshNetwork!.streams.devicesStream.listen((
        devices,
      ) {
        add(UpdateConnectedDevices(devices));
      });
      await _meshNetwork!.connect();

      emit(
        MeshNetworkConnected(
          meshNetwork: _meshNetwork!,
          connectedDevices: _meshNetwork!.connectedDevices,
        ),
      );
    } catch (e) {
      emit(MeshNetworkError(e.toString()));
    }
  }

  Future<void> _onConnect(
    ConnectMeshNetwork event,
    Emitter<MeshNetworkState> emit,
  ) async {
    if (_meshNetwork != null) {
      try {
        await _meshNetwork!.connect();
        emit(
          MeshNetworkConnected(
            meshNetwork: _meshNetwork!,
            connectedDevices: _meshNetwork!.connectedDevices,
          ),
        );
      } catch (e) {
        emit(MeshNetworkError(e.toString()));
      }
    }
  }

  Future<void> _onDisconnect(
    DisconnectMeshNetwork event,
    Emitter<MeshNetworkState> emit,
  ) async {
    if (_meshNetwork != null) {
      await _meshNetwork!.disconnect();
      emit(MeshNetworkDisconnected());
    }
  }

  void _onUpdateDevices(
    UpdateConnectedDevices event,
    Emitter<MeshNetworkState> emit,
  ) {
    debugPrint("BLOC: Updating connected devices: ${event.devices}");
    if (state is MeshNetworkConnected && _meshNetwork != null) {
      emit(
        MeshNetworkConnected(
          meshNetwork: _meshNetwork!,
          connectedDevices: event.devices,
        ),
      );
    }
  }

  Future<void> _onStartDeviceDiscovery(
    StartDeviceDiscovery event,
    Emitter<MeshNetworkState> emit,
  ) async {
    try {
      _nearbyService ??= NearbyService();

      final initialized = await _nearbyService!.initialize();
      if (!initialized) {
        emit(
          MeshNetworkError(
            'Failed to initialize Nearby Connections - check permissions',
          ),
        );
        return;
      }

      // Setup connection listener apenas (sem emit)
      _nearbyConnectionSubscription = _nearbyService!.connectionStream.listen((
        data,
      ) {
        debugPrint('NearbyBloc: Connection event: $data');
        if (data['type'] == 'connected') {
          debugPrint('Device connected: ${data['deviceId']}');
        } else if (data['type'] == 'disconnected') {
          // Para este listener, podemos adicionar um evento em vez de emit direto
          add(DiscoveredDeviceFound('', '')); // Trigger refresh
        }
      });

      // Setup message listener apenas (sem emit)
      _nearbyMessageSubscription = _nearbyService!.messageStream.listen((data) {
        debugPrint('NearbyBloc: Message received: $data');
        _handleNearbyMessage(data);
      });

      // Start discovery or advertising
      bool started = false;
      if (event.isLeader) {
        started = await _nearbyService!.startAdvertising();
        // _meshNetwork = await _reconnectToSharedBroker(_testBrokerIp);
        // emit(
        //   MeshNetworkConnected(
        //     meshNetwork: _meshNetwork!,
        //     connectedDevices: _meshNetwork!.connectedDevices,
        //   ),
        // );
        _meshNetwork?.reconnectToBroker("192.168.1.107");
        debugPrint('NearbyBloc: Started advertising as leader: $started');
      } else {
        started = await _nearbyService!.startDiscovery();
        debugPrint('NearbyBloc: Started discovery as follower: $started');
      }

      if (!started) {
        // emit(
        //   MeshNetworkError(
        //     'Failed to start ${event.isLeader ? "advertising" : "discovery"}',
        //   ),
        // );
        return;
      }

      // Usar emit.forEach para lidar com o stream de discovered devices
      await emit.forEach<Map<String, String>>(
        _nearbyService!.discoveredDevicesStream,
        onData: (devices) {
          debugPrint(
            'NearbyBloc: Discovered devices updated via forEach: $devices',
          );
          discoveredDevices = Map.from(devices);
          return MeshNetworkDiscovering(Map.from(discoveredDevices));
        },
        onError: (error, stackTrace) {
          debugPrint('NearbyBloc: Error in discovered devices stream: $error');
          return MeshNetworkError(
            'Discovery stream error: ${error.toString()}',
          );
        },
      );
    } catch (e) {
      debugPrint('NearbyBloc: Error in start discovery: $e');
      emit(
        MeshNetworkError('Failed to start device discovery: ${e.toString()}'),
      );
    }
  }

  Future<void> _onStopDeviceDiscovery(
    StopDeviceDiscovery event,
    Emitter<MeshNetworkState> emit,
  ) async {
    await _nearbyService?.stop();
    _nearbyConnectionSubscription?.cancel();
    _nearbyMessageSubscription?.cancel();
    _nearbyDiscoverySubscription?.cancel(); // Adicionar esta linha
    // discoveredDevices.clear();

    if (state is MeshNetworkConnected) {

      emit(
        MeshNetworkConnected(
          meshNetwork: _meshNetwork!,
          connectedDevices: _meshNetwork!.connectedDevices,
        ),
      );
    }
  }

  void _onDiscoveredDeviceFound(
    DiscoveredDeviceFound event,
    Emitter<MeshNetworkState> emit,
  ) {
    discoveredDevices[event.deviceId] = event.deviceName;
    emit(MeshNetworkDiscovering(Map.from(discoveredDevices)));
  }

  Future<void> _onConnectToDiscoveredDevice(
    ConnectToDiscoveredDevice event,
    Emitter<MeshNetworkState> emit,
  ) async {
    print('Connecting to discovered device: ${event.deviceId}');
    emit(MeshNetworkDeviceConnecting(event.deviceId));
    // Connection logic is handled by NearbyService callbacks

    if (_nearbyService != null &&
        discoveredDevices.containsKey(event.deviceId)) {
      // await _reconnectToSharedBroker(discoveredDevices[event.deviceId]!);
      // _meshNetwork = await _reconnectToSharedBroker(_testBrokerIp);
      await _nearbyService?.stop();
      // discoveredDevices.clear();

      // emit(
      //   MeshNetworkConnected(
      //     meshNetwork: _meshNetwork!,
      //     connectedDevices: _meshNetwork!.connectedDevices,
      //   ),
      // );
    }
  }

  Future<void> _onShareNetworkInfo(
    ShareNetworkInfo event,
    Emitter<MeshNetworkState> emit,
  ) async {
    if (_meshNetwork != null && _nearbyService != null) {
      final networkInfo = {
        'type': 'mqtt_info',
        'brokerIp': _meshNetwork!.device.ip,
        'port': 1883,
        'deviceInfo': _meshNetwork!.device.toJson(),
      };

      // Send network info via Nearby Connections
      // Implementation depends on your NearbyService
      debugPrint('Sharing network info: $networkInfo');
    }
  }

  void _handleNearbyMessage(Map<String, dynamic> data) {
    if (data['type'] == 'mqtt_info') {
      // Received MQTT broker information from another device
      final brokerIp = data['brokerIp'] as String;
      // Reconnect to the shared MQTT broker
      _reconnectToSharedBroker(brokerIp);
    }
  }

  Future<MeshNetwork?> _reconnectToSharedBroker(String brokerIp) async {
    if (_meshNetwork != null) {
      try {
        await _meshNetwork!.disconnect();

        _meshNetwork = MeshNetwork(
          deviceInfo: _meshNetwork!.device,
          brokerIp: _testBrokerIp,
          // brokerIp: brokerIp
        );

        await _meshNetwork!.connect();

        debugPrint('Successfully reconnected to broker at $brokerIp');
        return _meshNetwork!;
      } catch (e) {
        debugPrint('Failed to reconnect to broker at $brokerIp: $e');
        // Emit error state if needed
        return null;
      }
    }
  }

  @override
  Future<void> close() {
    _devicesSubscription?.cancel();
    _meshNetwork?.disconnect();
    return super.close();
  }
}
