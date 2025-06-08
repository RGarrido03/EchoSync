import 'package:json_annotation/json_annotation.dart';

import '../song.dart';
import 'base.dart';
import 'enums.dart';

part 'playback.g.dart';

@JsonSerializable()
class PlaybackState {
  final Song? currentSong;
  final Duration position;
  final bool isPlaying;
  final int currentIndex;
  final double volume;
  final bool shuffleMode;
  final RepeatMode repeatMode;
  final NetworkTime lastUpdated;
  final String updatedByDevice;

  const PlaybackState({
    this.currentSong,
    required this.position,
    required this.isPlaying,
    required this.currentIndex,
    required this.volume,
    required this.shuffleMode,
    required this.repeatMode,
    required this.lastUpdated,
    required this.updatedByDevice,
  });

  factory PlaybackState.fromJson(Map<String, dynamic> json) =>
      _$PlaybackStateFromJson(json);

  Map<String, dynamic> toJson() => _$PlaybackStateToJson(this);

  PlaybackState copyWith({
    Song? currentSong,
    Duration? position,
    bool? isPlaying,
    int? currentIndex,
    double? volume,
    bool? shuffleMode,
    RepeatMode? repeatMode,
    NetworkTime? lastUpdated,
    String? updatedByDevice,
  }) {
    return PlaybackState(
      currentSong: currentSong ?? this.currentSong,
      position: position ?? this.position,
      isPlaying: isPlaying ?? this.isPlaying,
      currentIndex: currentIndex ?? this.currentIndex,
      volume: volume ?? this.volume,
      shuffleMode: shuffleMode ?? this.shuffleMode,
      repeatMode: repeatMode ?? this.repeatMode,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    );
  }
}

@JsonSerializable()
class PlaybackCommand extends SyncMessage {
  final NetworkTime scheduledTime;
  final String senderId;
  final Map<String, dynamic>? params;

  PlaybackCommand({
    required String command,
    required this.scheduledTime,
    required this.senderId,
    this.params,
  }) : super(command, timestamp: scheduledTime.toDateTime());

  factory PlaybackCommand.play({
    required NetworkTime scheduledTime,
    required String senderId,
    Song? song,
    Duration? position,
  }) {
    return PlaybackCommand(
      command: 'play',
      scheduledTime: scheduledTime,
      senderId: senderId,
      params: {
        if (song != null) 'song': song.toJson(),
        if (position != null) 'position': position.inMilliseconds,
      },
    );
  }

  factory PlaybackCommand.pause({
    required NetworkTime scheduledTime,
    required String senderId,
  }) {
    return PlaybackCommand(
      command: 'pause',
      scheduledTime: scheduledTime,
      senderId: senderId,
    );
  }

  factory PlaybackCommand.seek({
    required NetworkTime scheduledTime,
    required String senderId,
    required Duration position,
  }) {
    return PlaybackCommand(
      command: 'seek',
      scheduledTime: scheduledTime,
      senderId: senderId,
      params: {'position': position.inMilliseconds},
    );
  }

  factory PlaybackCommand.setVolume({
    required NetworkTime scheduledTime,
    required String senderId,
    required double volume,
  }) {
    return PlaybackCommand(
      command: 'set_volume',
      scheduledTime: scheduledTime,
      senderId: senderId,
      params: {'volume': volume},
    );
  }

  factory PlaybackCommand.fromJson(Map<String, dynamic> json) =>
      _$PlaybackCommandFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$PlaybackCommandToJson(this);
}
