// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Song _$SongFromJson(Map<String, dynamic> json) => Song(
  hash: json['hash'] as String,
  title: json['title'] as String,
  artist: json['artist'] as String,
  album: json['album'] as String,
  duration: Duration(microseconds: (json['duration'] as num).toInt()),
  cover: _$JsonConverterFromJson<List<dynamic>, Uint8List>(
    json['cover'],
    const Uint8ListJsonConverter().fromJson,
  ),
  downloadUrl: json['downloadUrl'] as String?,
);

Map<String, dynamic> _$SongToJson(Song instance) => <String, dynamic>{
  'hash': instance.hash,
  'title': instance.title,
  'artist': instance.artist,
  'album': instance.album,
  'duration': instance.duration.inMicroseconds,
  'cover': _$JsonConverterToJson<List<dynamic>, Uint8List>(
    instance.cover,
    const Uint8ListJsonConverter().toJson,
  ),
  'downloadUrl': instance.downloadUrl,
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
