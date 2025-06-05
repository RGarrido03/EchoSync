// lib/bloc/sync_manager/sync_manager_event.dart
part of 'sync_manager_bloc.dart';

abstract class SyncManagerEvent {}

class InitializeSyncManager extends SyncManagerEvent {
  final MeshNetwork meshNetwork;
  final TimeSyncService timeSyncService;
  final String deviceIp;

  InitializeSyncManager({
    required this.meshNetwork,
    required this.timeSyncService,
    required this.deviceIp,
  });
}

class PlayMusic extends SyncManagerEvent {
  final String? songHash;
  final int? position;

  PlayMusic({this.songHash, this.position});
}

class PauseMusic extends SyncManagerEvent {}

class SeekToPosition extends SyncManagerEvent {
  final int position;

  SeekToPosition(this.position);
}

class NextTrack extends SyncManagerEvent {}

class PreviousTrack extends SyncManagerEvent {}

class AddSongToQueue extends SyncManagerEvent {
  final String songHash;
  final int? position;

  AddSongToQueue(this.songHash, {this.position});
}

class PlaybackStatusUpdated extends SyncManagerEvent {
  final PlaybackStatus status;

  PlaybackStatusUpdated(this.status);
}

class QueueStatusUpdated extends SyncManagerEvent {
  final QueueStatus status;

  QueueStatusUpdated(this.status);
}
