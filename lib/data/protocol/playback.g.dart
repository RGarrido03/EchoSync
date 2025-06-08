// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaybackState _$PlaybackStateFromJson(Map<String, dynamic> json) =>
    PlaybackState(
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
      updatedByDevice: json['updatedByDevice'] as String,
    );

Map<String, dynamic> _$PlaybackStateToJson(PlaybackState instance) =>
    <String, dynamic>{
      'currentSong': instance.currentSong,
      'position': instance.position.inMicroseconds,
      'isPlaying': instance.isPlaying,
      'currentIndex': instance.currentIndex,
      'volume': instance.volume,
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

PlaybackCommand _$PlaybackCommandFromJson(Map<String, dynamic> json) =>
    PlaybackCommand(
      command: json['command'] as String,
      scheduledTime: NetworkTime.fromJson(
        json['scheduledTime'] as Map<String, dynamic>,
      ),
      senderId: json['senderId'] as String,
      params: json['params'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$PlaybackCommandToJson(PlaybackCommand instance) =>
    <String, dynamic>{
      'command': instance.command,
      'scheduledTime': instance.scheduledTime,
      'senderId': instance.senderId,
      'params': instance.params,
    };
