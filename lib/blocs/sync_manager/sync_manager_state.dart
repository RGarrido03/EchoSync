part of 'sync_manager_bloc.dart';

abstract class SyncManagerState {}

class SyncManagerInitial extends SyncManagerState {}

class SyncManagerInitializing extends SyncManagerState {}

class SyncManagerReady extends SyncManagerState {
  final SyncManager syncManager;
  final PlaybackState? playbackState;
  final QueueState? queueState;
  final Map<String, Device> connectedDevices;

  SyncManagerReady({
    required this.syncManager,
    this.playbackState,
    this.queueState,
    required this.connectedDevices,
  });

  SyncManagerReady copyWith({
    SyncManager? syncManager,
    PlaybackState? playbackState,
    QueueState? queueState,
    bool? isLeader,
    Map<String, Device>? connectedDevices,
  }) {
    return SyncManagerReady(
      syncManager: syncManager ?? this.syncManager,
      playbackState: playbackState ?? this.playbackState,
      queueState: queueState ?? this.queueState,
      connectedDevices: connectedDevices ?? this.connectedDevices,
    );
  }
}

class SyncManagerError extends SyncManagerState {
  final String error;

  SyncManagerError(this.error);
}
