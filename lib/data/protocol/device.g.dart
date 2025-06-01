// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceRegistry _$DeviceRegistryFromJson(Map<String, dynamic> json) =>
    DeviceRegistry(
      devices: (json['devices'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, Device.fromJson(e as Map<String, dynamic>)),
      ),
      lastUpdated: NetworkTime.fromJson(
        json['lastUpdated'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$DeviceRegistryToJson(DeviceRegistry instance) =>
    <String, dynamic>{
      'devices': instance.devices,
      'lastUpdated': instance.lastUpdated,
    };

DeviceControl _$DeviceControlFromJson(Map<String, dynamic> json) =>
    DeviceControl(
      device: Device.fromJson(json['device'] as Map<String, dynamic>),
      action: json['action'] as String,
    );

Map<String, dynamic> _$DeviceControlToJson(DeviceControl instance) =>
    <String, dynamic>{'device': instance.device, 'action': instance.action};
