import 'package:json_annotation/json_annotation.dart';

import '../device.dart';
import 'base.dart';

part 'device.g.dart';

// Complete device registry (retained message)
@JsonSerializable()
class DeviceRegistry {
  final Map<String, Device> devices;
  final NetworkTime lastUpdated;

  const DeviceRegistry({required this.devices, required this.lastUpdated});

  factory DeviceRegistry.fromJson(Map<String, dynamic> json) =>
      _$DeviceRegistryFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceRegistryToJson(this);
}

@JsonSerializable()
class DeviceControl extends SyncMessage {
  final Device device;
  final String action; // 'join', 'leave', 'update'

  DeviceControl({required this.device, required this.action})
    : super('device_control');

  factory DeviceControl.join(Device device) {
    return DeviceControl(device: device, action: 'join');
  }

  factory DeviceControl.leave(Device device) {
    return DeviceControl(device: device, action: 'leave');
  }

  factory DeviceControl.update(Device device) {
    return DeviceControl(device: device, action: 'update');
  }

  factory DeviceControl.fromJson(Map<String, dynamic> json) =>
      _$DeviceControlFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$DeviceControlToJson(this);
}
