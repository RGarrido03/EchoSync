// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaybackStatus _$PlaybackStatusFromJson(Map<String, dynamic> json) =>
    PlaybackStatus(
      currentSong:
          json['currentSong'] == null
              ? null
              : Song.fromJson(json['currentSong'] as Map<String, dynamic>),
      position: Duration(microseconds: (json['position'] as num).toInt()),
      isPlaying: json['isPlaying'] as bool,
      currentIndex: (json['currentIndex'] as num).toInt(),
      volume: (json['volume'] as num).toDouble(),
      shuffleMode: json['shuffleMode'] as bool,
      repeatMode: $enumDecode(_$RepeatModeEnumMap, json['repeatMode']),
      lastUpdated: NetworkTime.fromJson(
        json['lastUpdated'] as Map<String, dynamic>,
      ),
      deviceId: json['deviceId'] as String,
    );

Map<String, dynamic> _$PlaybackStatusToJson(PlaybackStatus instance) =>
    <String, dynamic>{
      'currentSong': instance.currentSong,
      'position': instance.position.inMicroseconds,
      'isPlaying': instance.isPlaying,
      'currentIndex': instance.currentIndex,
      'volume': instance.volume,
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

PlaybackControl _$PlaybackControlFromJson(Map<String, dynamic> json) =>
    PlaybackControl(
      command: json['command'] as String,
      scheduledTime: NetworkTime.fromJson(
        json['scheduledTime'] as Map<String, dynamic>,
      ),
      deviceIp: json['deviceIp'] as String,
      params: json['params'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$PlaybackControlToJson(PlaybackControl instance) =>
    <String, dynamic>{
      'command': instance.command,
      'scheduledTime': instance.scheduledTime,
      'deviceIp': instance.deviceIp,
      'params': instance.params,
    };
