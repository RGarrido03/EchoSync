import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

part 'song.g.dart';

class Uint8ListJsonConverter extends JsonConverter<Uint8List, List<dynamic>> {
  const Uint8ListJsonConverter();

  @override
  Uint8List fromJson(List<dynamic> json) {
    return Uint8List.fromList(
      json.map((e) => int.parse(e.toString())).toList(),
    );
  }

  @override
  List<dynamic> toJson(Uint8List object) {
    return object.map((e) => e.toString()).toList();
  }
}

@JsonSerializable()
@Uint8ListJsonConverter()
class Song {
  final String hash;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String extension;
  final Uint8List? cover;
  final String? downloadUrl;

  Song({
    required this.hash,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    this.extension = 'mp3',
    this.cover,
    this.downloadUrl,
  });

  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);

  Map<String, dynamic> toJson() => _$SongToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song && runtimeType == other.runtimeType && hash == other.hash;

  @override
  int get hashCode => hash.hashCode;

  Song copyWith({
    String? hash,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    Uint8List? cover,
    String? downloadUrl,
  }) {
    return Song(
      hash: hash ?? this.hash,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      cover: cover ?? this.cover,
      downloadUrl: downloadUrl ?? this.downloadUrl,
    );
  }
}
