// lib/bloc/mesh_network/mesh_network_state.dart
part of 'mesh_network_bloc.dart';

abstract class MeshNetworkState {}

class MeshNetworkInitial extends MeshNetworkState {}

class MeshNetworkInitializing extends MeshNetworkState {}

class MeshNetworkConnected extends MeshNetworkState {
  final MeshNetwork meshNetwork;
  final Map<String, Device> connectedDevices;

  MeshNetworkConnected({
    required this.meshNetwork,
    required this.connectedDevices,
  });
}

class MeshNetworkDisconnected extends MeshNetworkState {}

class MeshNetworkError extends MeshNetworkState {
  final String error;

  MeshNetworkError(this.error);
}
