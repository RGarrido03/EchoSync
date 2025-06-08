import 'package:json_annotation/json_annotation.dart';

import '../song.dart';
import 'base.dart';
import 'enums.dart';

part 'playback.g.dart';

@JsonSerializable()
class PlaybackStatus {
  final Song? currentSong; // Changed from String? to Song?
  final Duration position;
  final bool isPlaying;
  final int currentIndex;
  final double volume;
  final bool shuffleMode;
  final RepeatMode repeatMode;
  final NetworkTime lastUpdated;
  final String deviceId;

  const PlaybackStatus({
    this.currentSong,
    required this.position,
    required this.isPlaying,
    required this.currentIndex,
    required this.volume,
    required this.shuffleMode,
    required this.repeatMode,
    required this.lastUpdated,
    required this.deviceId,
  });

  factory PlaybackStatus.fromJson(Map<String, dynamic> json) =>
      _$PlaybackStatusFromJson(json);

  Map<String, dynamic> toJson() => _$PlaybackStatusToJson(this);

  PlaybackStatus copyWith({
    Song? currentSong,
    Duration? position,
    bool? isPlaying,
    int? currentIndex,
    double? volume,
    bool? shuffleMode,
    RepeatMode? repeatMode,
    NetworkTime? lastUpdated,
    String? deviceId,
  }) {
    return PlaybackStatus(
      currentSong: currentSong ?? this.currentSong,
      position: position ?? this.position,
      isPlaying: isPlaying ?? this.isPlaying,
      currentIndex: currentIndex ?? this.currentIndex,
      volume: volume ?? this.volume,
      shuffleMode: shuffleMode ?? this.shuffleMode,
      repeatMode: repeatMode ?? this.repeatMode,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}

@JsonSerializable()
class PlaybackControl extends SyncMessage {
  final NetworkTime scheduledTime;
  final String deviceIp;
  final Map<String, dynamic>? params;

  PlaybackControl({
    required String command,
    required this.scheduledTime,
    required this.deviceIp,
    this.params,
  }) : super(command, timestamp: scheduledTime.toDateTime());

  factory PlaybackControl.play({
    required NetworkTime scheduledTime,
    required String deviceId,
    Song? song,
    Duration? position,
  }) {
    return PlaybackControl(
      command: 'play',
      scheduledTime: scheduledTime,
      deviceIp: deviceId,
      params: {
        if (song != null) 'song': song.toJson(),
        if (position != null) 'position': position,
      },
    );
  }

  factory PlaybackControl.pause({
    required NetworkTime scheduledTime,
    required String deviceId,
  }) {
    return PlaybackControl(
      command: 'pause',
      scheduledTime: scheduledTime,
      deviceIp: deviceId,
    );
  }

  factory PlaybackControl.seek({
    required NetworkTime scheduledTime,
    required String deviceId,
    required Duration position,
  }) {
    return PlaybackControl(
      command: 'seek',
      scheduledTime: scheduledTime,
      deviceIp: deviceId,
      params: {'position': position},
    );
  }

  factory PlaybackControl.setVolume({
    required NetworkTime scheduledTime,
    required String deviceId,
    required double volume,
  }) {
    return PlaybackControl(
      command: 'set_volume',
      scheduledTime: scheduledTime,
      deviceIp: deviceId,
      params: {'volume': volume},
    );
  }

  factory PlaybackControl.fromJson(Map<String, dynamic> json) =>
      _$PlaybackControlFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$PlaybackControlToJson(this);
}
