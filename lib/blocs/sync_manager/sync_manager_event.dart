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
  final Song? song;
  final Duration? position;

  PlayMusic({this.song, this.position});
}

class PauseMusic extends SyncManagerEvent {}

class SeekToPosition extends SyncManagerEvent {
  final Duration position;

  SeekToPosition(this.position);
}

class NextTrack extends SyncManagerEvent {}

class PreviousTrack extends SyncManagerEvent {}

class AddSongToQueue extends SyncManagerEvent {
  final Song song;
  final int? position;

  AddSongToQueue(this.song, {this.position});
}

class PlaybackStatusUpdated extends SyncManagerEvent {
  final PlaybackStatus status;

  PlaybackStatusUpdated(this.status);
}

class QueueStatusUpdated extends SyncManagerEvent {
  final QueueStatus status;

  QueueStatusUpdated(this.status);
}

class PlaySongAtIndex extends SyncManagerEvent {
  final int index;

  PlaySongAtIndex(this.index);
}

class PickAndAddSongToQueue extends SyncManagerEvent {
  final int? position;

  PickAndAddSongToQueue({this.position});
}

class PickAndAddMultipleSongsToQueue extends SyncManagerEvent {
  final int? position;

  PickAndAddMultipleSongsToQueue({this.position});
}

class AddSongFromPath extends SyncManagerEvent {
  final String filePath;
  final int? position;

  AddSongFromPath(this.filePath, {this.position});
}
