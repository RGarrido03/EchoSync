import 'package:echosync/data/song.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base.dart';
import 'enums.dart';

part 'queue.g.dart';

// Unified queue state (retained message)
@JsonSerializable()
class QueueState {
  final List<Song> songs;
  final int currentIndex;
  final bool shuffleMode;
  final RepeatMode repeatMode;
  final NetworkTime lastUpdated;
  final String updatedByDevice;

  const QueueState({
    required this.songs,
    required this.currentIndex,
    required this.shuffleMode,
    required this.repeatMode,
    required this.lastUpdated,
    required this.updatedByDevice,
  });

  factory QueueState.fromJson(Map<String, dynamic> json) =>
      _$QueueStateFromJson(json);

  Map<String, dynamic> toJson() => _$QueueStateToJson(this);

  QueueState copyWith({
    List<Song>? songs,
    int? currentIndex,
    bool? shuffleMode,
    RepeatMode? repeatMode,
    NetworkTime? lastUpdated,
    String? updatedByDevice,
  }) {
    return QueueState(
      songs: songs ?? this.songs,
      currentIndex: currentIndex ?? this.currentIndex,
      shuffleMode: shuffleMode ?? this.shuffleMode,
      repeatMode: repeatMode ?? this.repeatMode,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    );
  }
}

// Simplified queue commands (non-retained messages)
@JsonSerializable()
class QueueCommand extends SyncMessage {
  final String senderId;
  final Map<String, dynamic>? params;

  QueueCommand({required String command, required this.senderId, this.params})
    : super(command);

  factory QueueCommand.add({
    required String senderId,
    required Song song,
    int? position,
  }) {
    return QueueCommand(
      command: 'add',
      senderId: senderId,
      params: {
        'song': song.toJson(),
        if (position != null) 'position': position,
      },
    );
  }

  factory QueueCommand.remove({required String senderId, required int index}) {
    return QueueCommand(
      command: 'remove',
      senderId: senderId,
      params: {'index': index},
    );
  }

  factory QueueCommand.move({
    required String senderId,
    required int fromIndex,
    required int toIndex,
  }) {
    return QueueCommand(
      command: 'move',
      senderId: senderId,
      params: {'fromIndex': fromIndex, 'toIndex': toIndex},
    );
  }

  factory QueueCommand.replace({
    required String senderId,
    required List<Song> songs,
  }) {
    return QueueCommand(
      command: 'replace',
      senderId: senderId,
      params: {'songs': songs.map((s) => s.toJson()).toList()},
    );
  }

  factory QueueCommand.setCurrentIndex({
    required String senderId,
    required int index,
  }) {
    return QueueCommand(
      command: 'set_current_index',
      senderId: senderId,
      params: {'index': index},
    );
  }

  factory QueueCommand.setShuffle({
    required String senderId,
    required bool enabled,
  }) {
    return QueueCommand(
      command: 'set_shuffle',
      senderId: senderId,
      params: {'enabled': enabled},
    );
  }

  factory QueueCommand.setRepeat({
    required String senderId,
    required RepeatMode mode,
  }) {
    return QueueCommand(
      command: 'set_repeat',
      senderId: senderId,
      params: {'mode': mode.name},
    );
  }

  factory QueueCommand.fromJson(Map<String, dynamic> json) =>
      _$QueueCommandFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$QueueCommandToJson(this);
}
