import 'package:json_annotation/json_annotation.dart';

import 'base.dart';

part 'sync.g.dart';

@JsonSerializable()
class PlaybackState {
  final List<String> playlist;
  final int currentIndex;
  final bool isPlaying;
  final int position;
  final String? currentSong;

  const PlaybackState({
    required this.playlist,
    required this.currentIndex,
    required this.isPlaying,
    required this.position,
    this.currentSong,
  });

  factory PlaybackState.fromJson(Map<String, dynamic> json) =>
      _$PlaybackStateFromJson(json);

  Map<String, dynamic> toJson() => _$PlaybackStateToJson(this);
}

@JsonSerializable()
class SyncStateRequest extends SyncMessage {
  final String deviceId;

  const SyncStateRequest({required this.deviceId}) : super('sync_state');

  factory SyncStateRequest.fromJson(Map<String, dynamic> json) =>
      _$SyncStateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SyncStateRequestToJson(this);
}

@JsonSerializable()
class SyncStateResponse extends SyncMessage {
  final PlaybackState state;

  const SyncStateResponse({required this.state}) : super('sync_state_response');

  factory SyncStateResponse.fromJson(Map<String, dynamic> json) =>
      _$SyncStateResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SyncStateResponseToJson(this);
}
