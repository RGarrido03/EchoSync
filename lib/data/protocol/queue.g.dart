// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QueueState _$QueueStateFromJson(Map<String, dynamic> json) => QueueState(
  songs:
      (json['songs'] as List<dynamic>)
          .map((e) => Song.fromJson(e as Map<String, dynamic>))
          .toList(),
  currentIndex: (json['currentIndex'] as num).toInt(),
  shuffleMode: json['shuffleMode'] as bool,
  repeatMode: $enumDecode(_$RepeatModeEnumMap, json['repeatMode']),
  lastUpdated: NetworkTime.fromJson(
    json['lastUpdated'] as Map<String, dynamic>,
  ),
  updatedByDevice: json['updatedByDevice'] as String,
);

Map<String, dynamic> _$QueueStateToJson(QueueState instance) =>
    <String, dynamic>{
      'songs': instance.songs,
      'currentIndex': instance.currentIndex,
      'shuffleMode': instance.shuffleMode,
      'repeatMode': _$RepeatModeEnumMap[instance.repeatMode]!,
      'lastUpdated': instance.lastUpdated,
      'updatedByDevice': instance.updatedByDevice,
    };

const _$RepeatModeEnumMap = {
  RepeatMode.none: 'none',
  RepeatMode.one: 'one',
  RepeatMode.all: 'all',
};

QueueCommand _$QueueCommandFromJson(Map<String, dynamic> json) => QueueCommand(
  command: json['command'] as String,
  senderId: json['senderId'] as String,
  params: json['params'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$QueueCommandToJson(QueueCommand instance) =>
    <String, dynamic>{
      'command': instance.command,
      'senderId': instance.senderId,
      'params': instance.params,
    };
