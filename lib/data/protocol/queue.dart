import 'package:json_annotation/json_annotation.dart';

import 'base.dart';

part 'queue.g.dart';

@JsonSerializable()
class UpdatePlaylistMessage extends SyncMessage {
  final List<String> playlist;

  const UpdatePlaylistMessage({required this.playlist})
    : super('update_playlist');

  factory UpdatePlaylistMessage.fromJson(Map<String, dynamic> json) =>
      _$UpdatePlaylistMessageFromJson(json);

  Map<String, dynamic> toJson() => _$UpdatePlaylistMessageToJson(this);
}

@JsonSerializable()
class RequestPlaylistMessage extends SyncMessage {
  final String senderId;

  const RequestPlaylistMessage({required this.senderId})
    : super('request_playlist');

  factory RequestPlaylistMessage.fromJson(Map<String, dynamic> json) =>
      _$RequestPlaylistMessageFromJson(json);

  Map<String, dynamic> toJson() => _$RequestPlaylistMessageToJson(this);
}
