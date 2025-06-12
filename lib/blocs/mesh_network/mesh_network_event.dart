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

class StartDeviceDiscovery extends MeshNetworkEvent {
  final bool isLeader;

  StartDeviceDiscovery({required this.isLeader});
}

class StopDeviceDiscovery extends MeshNetworkEvent {}

class DiscoveredDeviceFound extends MeshNetworkEvent {
  final String deviceId;
  final String deviceName;

  DiscoveredDeviceFound(this.deviceId, this.deviceName);
}

class ConnectToDiscoveredDevice extends MeshNetworkEvent {
  final String deviceId;

  ConnectToDiscoveredDevice(this.deviceId);
}

class ShareNetworkInfo extends MeshNetworkEvent {
  final String targetDeviceId;

  ShareNetworkInfo(this.targetDeviceId);
}
