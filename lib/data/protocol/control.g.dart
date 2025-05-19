// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'control.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlayMessage _$PlayMessageFromJson(Map<String, dynamic> json) => PlayMessage(
  scheduledTime: NetworkTime.fromJson(
    json['scheduledTime'] as Map<String, dynamic>,
  ),
  song: json['song'] as String,
  position: (json['position'] as num).toInt(),
);

Map<String, dynamic> _$PlayMessageToJson(PlayMessage instance) =>
    <String, dynamic>{
      'scheduledTime': instance.scheduledTime,
      'song': instance.song,
      'position': instance.position,
    };

PauseMessage _$PauseMessageFromJson(Map<String, dynamic> json) => PauseMessage(
  scheduledTime: NetworkTime.fromJson(
    json['scheduledTime'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$PauseMessageToJson(PauseMessage instance) =>
    <String, dynamic>{'scheduledTime': instance.scheduledTime};

SeekMessage _$SeekMessageFromJson(Map<String, dynamic> json) => SeekMessage(
  scheduledTime: NetworkTime.fromJson(
    json['scheduledTime'] as Map<String, dynamic>,
  ),
  position: (json['position'] as num).toInt(),
);

Map<String, dynamic> _$SeekMessageToJson(SeekMessage instance) =>
    <String, dynamic>{
      'scheduledTime': instance.scheduledTime,
      'position': instance.position,
    };

NextTrackMessage _$NextTrackMessageFromJson(Map<String, dynamic> json) =>
    NextTrackMessage(
      scheduledTime: NetworkTime.fromJson(
        json['scheduledTime'] as Map<String, dynamic>,
      ),
      songIndex: (json['songIndex'] as num).toInt(),
    );

Map<String, dynamic> _$NextTrackMessageToJson(NextTrackMessage instance) =>
    <String, dynamic>{
      'scheduledTime': instance.scheduledTime,
      'songIndex': instance.songIndex,
    };

PreviousTrackMessage _$PreviousTrackMessageFromJson(
  Map<String, dynamic> json,
) => PreviousTrackMessage(
  scheduledTime: NetworkTime.fromJson(
    json['scheduledTime'] as Map<String, dynamic>,
  ),
  songIndex: (json['songIndex'] as num).toInt(),
);

Map<String, dynamic> _$PreviousTrackMessageToJson(
  PreviousTrackMessage instance,
) => <String, dynamic>{
  'scheduledTime': instance.scheduledTime,
  'songIndex': instance.songIndex,
};
