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
class Song {
  final String hash;
  final String title;
  final String artist;
  final String album;
  final int duration;
  @Uint8ListJsonConverter()
  final Uint8List? cover;

  Song({
    required this.hash,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    this.cover,
  });

  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);

  Map<String, dynamic> toJson() => _$SongToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song && runtimeType == other.runtimeType && hash == other.hash;

  @override
  int get hashCode => hash.hashCode;
}
