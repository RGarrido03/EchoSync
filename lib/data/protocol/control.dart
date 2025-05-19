import 'package:json_annotation/json_annotation.dart';

import 'base.dart';

part 'control.g.dart';

@JsonSerializable()
class PlayMessage extends SyncMessage {
  final NetworkTime scheduledTime;
  final String song; // hash
  final int position; // Position in milliseconds

  const PlayMessage({
    required this.scheduledTime,
    required this.song,
    required this.position,
  }) : super('play');

  factory PlayMessage.fromJson(Map<String, dynamic> json) =>
      _$PlayMessageFromJson(json);

  Map<String, dynamic> toJson() => _$PlayMessageToJson(this);
}

@JsonSerializable()
class PauseMessage extends SyncMessage {
  final NetworkTime scheduledTime;

  const PauseMessage({required this.scheduledTime}) : super('pause');

  factory PauseMessage.fromJson(Map<String, dynamic> json) =>
      _$PauseMessageFromJson(json);

  Map<String, dynamic> toJson() => _$PauseMessageToJson(this);
}

@JsonSerializable()
class SeekMessage extends SyncMessage {
  final NetworkTime scheduledTime;
  final int position; // Position in milliseconds

  const SeekMessage({required this.scheduledTime, required this.position})
    : super('seek');

  factory SeekMessage.fromJson(Map<String, dynamic> json) =>
      _$SeekMessageFromJson(json);

  Map<String, dynamic> toJson() => _$SeekMessageToJson(this);
}

@JsonSerializable()
class NextTrackMessage extends SyncMessage {
  final NetworkTime scheduledTime;
  final int songIndex;

  const NextTrackMessage({required this.scheduledTime, required this.songIndex})
    : super('next');

  factory NextTrackMessage.fromJson(Map<String, dynamic> json) =>
      _$NextTrackMessageFromJson(json);

  Map<String, dynamic> toJson() => _$NextTrackMessageToJson(this);
}

@JsonSerializable()
class PreviousTrackMessage extends SyncMessage {
  final NetworkTime scheduledTime;
  final int songIndex;

  const PreviousTrackMessage({
    required this.scheduledTime,
    required this.songIndex,
  }) : super('previous');

  factory PreviousTrackMessage.fromJson(Map<String, dynamic> json) =>
      _$PreviousTrackMessageFromJson(json);

  Map<String, dynamic> toJson() => _$PreviousTrackMessageToJson(this);
}
