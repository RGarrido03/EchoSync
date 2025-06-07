import 'package:json_annotation/json_annotation.dart';

part 'song.g.dart';

@JsonSerializable()
class Song {
  final String hash;
  final String title;
  final String artist;
  final String album;
  final int duration;
  final Uri? coverUrl;

  Song({
    required this.hash,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    this.coverUrl,
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
