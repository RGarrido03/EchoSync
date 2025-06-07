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
  duration: (json['duration'] as num).toInt(),
  coverUrl:
      json['coverUrl'] == null ? null : Uri.parse(json['coverUrl'] as String),
);

Map<String, dynamic> _$SongToJson(Song instance) => <String, dynamic>{
  'hash': instance.hash,
  'title': instance.title,
  'artist': instance.artist,
  'album': instance.album,
  'duration': instance.duration,
  'coverUrl': instance.coverUrl?.toString(),
};
