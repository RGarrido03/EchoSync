// lib/bloc/mesh_network/mesh_network_bloc.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/device.dart';
import '../../services/mesh_network.dart';

part 'mesh_network_event.dart';
part 'mesh_network_state.dart';

class MeshNetworkBloc extends Bloc<MeshNetworkEvent, MeshNetworkState> {
  MeshNetwork? _meshNetwork;
  StreamSubscription<Map<String, Device>>? _devicesSubscription;

  MeshNetwork? get meshNetwork => _meshNetwork;

  MeshNetworkBloc() : super(MeshNetworkInitial()) {
    on<InitializeMeshNetwork>(_onInitialize);
    on<ConnectMeshNetwork>(_onConnect);
    on<DisconnectMeshNetwork>(_onDisconnect);
    on<UpdateConnectedDevices>(_onUpdateDevices);
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

  @override
  Future<void> close() {
    _devicesSubscription?.cancel();
    _meshNetwork?.disconnect();
    return super.close();
  }
}
