// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaybackState _$PlaybackStateFromJson(Map<String, dynamic> json) =>
    PlaybackState(
      playlist:
          (json['playlist'] as List<dynamic>).map((e) => e as String).toList(),
      currentIndex: (json['currentIndex'] as num).toInt(),
      isPlaying: json['isPlaying'] as bool,
      position: (json['position'] as num).toInt(),
      currentSong: json['currentSong'] as String?,
    );

Map<String, dynamic> _$PlaybackStateToJson(PlaybackState instance) =>
    <String, dynamic>{
      'playlist': instance.playlist,
      'currentIndex': instance.currentIndex,
      'isPlaying': instance.isPlaying,
      'position': instance.position,
      'currentSong': instance.currentSong,
    };

SyncStateRequest _$SyncStateRequestFromJson(Map<String, dynamic> json) =>
    SyncStateRequest(deviceId: json['deviceId'] as String);

Map<String, dynamic> _$SyncStateRequestToJson(SyncStateRequest instance) =>
    <String, dynamic>{'deviceId': instance.deviceId};

SyncStateResponse _$SyncStateResponseFromJson(Map<String, dynamic> json) =>
    SyncStateResponse(
      state: PlaybackState.fromJson(json['state'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SyncStateResponseToJson(SyncStateResponse instance) =>
    <String, dynamic>{'state': instance.state};
