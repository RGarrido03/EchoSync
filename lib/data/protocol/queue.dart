import 'package:json_annotation/json_annotation.dart';

import 'base.dart';
import 'enums.dart';

part 'queue.g.dart';

// Complete queue status (retained message)
@JsonSerializable()
class QueueStatus {
  final List<String> songs; // List of song hashes
  final int currentIndex;
  final bool shuffleMode;
  final RepeatMode repeatMode;
  final NetworkTime lastUpdated;
  final String deviceId; // Which device last updated this

  const QueueStatus({
    required this.songs,
    required this.currentIndex,
    required this.shuffleMode,
    required this.repeatMode,
    required this.lastUpdated,
    required this.deviceId,
  });

  factory QueueStatus.fromJson(Map<String, dynamic> json) =>
      _$QueueStatusFromJson(json);

  Map<String, dynamic> toJson() => _$QueueStatusToJson(this);
}

// Control messages for queue topic
@JsonSerializable()
class QueueControl extends SyncMessage {
  final String deviceId;
  final Map<String, dynamic>? params;

  QueueControl({required String command, required this.deviceId, this.params})
    : super(command);

  factory QueueControl.add({
    required String deviceId,
    required String songHash,
    int? position,
  }) {
    return QueueControl(
      command: 'add',
      deviceId: deviceId,
      params: {
        'songHash': songHash,
        if (position != null) 'position': position,
      },
    );
  }

  factory QueueControl.remove({required String deviceId, required int index}) {
    return QueueControl(
      command: 'remove',
      deviceId: deviceId,
      params: {'index': index},
    );
  }

  factory QueueControl.move({
    required String deviceId,
    required int fromIndex,
    required int toIndex,
  }) {
    return QueueControl(
      command: 'move',
      deviceId: deviceId,
      params: {'fromIndex': fromIndex, 'toIndex': toIndex},
    );
  }

  factory QueueControl.replace({
    required String deviceId,
    required List<String> songs,
  }) {
    return QueueControl(
      command: 'replace',
      deviceId: deviceId,
      params: {'songs': songs},
    );
  }

  factory QueueControl.next({required String deviceId}) {
    return QueueControl(command: 'next', deviceId: deviceId);
  }

  factory QueueControl.previous({required String deviceId}) {
    return QueueControl(command: 'previous', deviceId: deviceId);
  }

  factory QueueControl.fromJson(Map<String, dynamic> json) =>
      _$QueueControlFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$QueueControlToJson(this);
}
