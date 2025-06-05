part of 'sync_manager_bloc.dart';

abstract class SyncManagerState {}

class SyncManagerInitial extends SyncManagerState {}

class SyncManagerInitializing extends SyncManagerState {}

class SyncManagerReady extends SyncManagerState {
  final SyncManager syncManager;
  final PlaybackStatus? playbackStatus;
  final QueueStatus? queueStatus;
  final bool isLeader;
  final Map<String, Device> connectedDevices;

  SyncManagerReady({
    required this.syncManager,
    this.playbackStatus,
    this.queueStatus,
    required this.isLeader,
    required this.connectedDevices,
  });

  SyncManagerReady copyWith({
    SyncManager? syncManager,
    PlaybackStatus? playbackStatus,
    QueueStatus? queueStatus,
    bool? isLeader,
    Map<String, Device>? connectedDevices,
  }) {
    return SyncManagerReady(
      syncManager: syncManager ?? this.syncManager,
      playbackStatus: playbackStatus ?? this.playbackStatus,
      queueStatus: queueStatus ?? this.queueStatus,
      isLeader: isLeader ?? this.isLeader,
      connectedDevices: connectedDevices ?? this.connectedDevices,
    );
  }
}

class SyncManagerError extends SyncManagerState {
  final String error;

  SyncManagerError(this.error);
}
