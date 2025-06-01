// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QueueStatus _$QueueStatusFromJson(Map<String, dynamic> json) => QueueStatus(
  songs: (json['songs'] as List<dynamic>).map((e) => e as String).toList(),
  currentIndex: (json['currentIndex'] as num).toInt(),
  shuffleMode: json['shuffleMode'] as bool,
  repeatMode: $enumDecode(_$RepeatModeEnumMap, json['repeatMode']),
  lastUpdated: NetworkTime.fromJson(
    json['lastUpdated'] as Map<String, dynamic>,
  ),
  deviceId: json['deviceId'] as String,
);

Map<String, dynamic> _$QueueStatusToJson(QueueStatus instance) =>
    <String, dynamic>{
      'songs': instance.songs,
      'currentIndex': instance.currentIndex,
      'shuffleMode': instance.shuffleMode,
      'repeatMode': _$RepeatModeEnumMap[instance.repeatMode]!,
      'lastUpdated': instance.lastUpdated,
      'deviceId': instance.deviceId,
    };

const _$RepeatModeEnumMap = {
  RepeatMode.none: 'none',
  RepeatMode.one: 'one',
  RepeatMode.all: 'all',
};

QueueControl _$QueueControlFromJson(Map<String, dynamic> json) => QueueControl(
  command: json['command'] as String,
  deviceId: json['deviceId'] as String,
  params: json['params'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$QueueControlToJson(QueueControl instance) =>
    <String, dynamic>{
      'command': instance.command,
      'deviceId': instance.deviceId,
      'params': instance.params,
    };
