// lib/bloc/mesh_network/mesh_network_event.dart
part of 'mesh_network_bloc.dart';

abstract class MeshNetworkEvent {}

class InitializeMeshNetwork extends MeshNetworkEvent {
  final Device device;

  InitializeMeshNetwork(this.device);
}

class ConnectMeshNetwork extends MeshNetworkEvent {}

class DisconnectMeshNetwork extends MeshNetworkEvent {}

class UpdateConnectedDevices extends MeshNetworkEvent {
  final Map<String, Device> devices;

  UpdateConnectedDevices(this.devices);
}
