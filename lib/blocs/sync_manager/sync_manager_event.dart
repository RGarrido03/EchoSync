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

class SeekMusic extends SyncManagerEvent {
  final Duration position;

  SeekMusic(this.position);
}

class NextTrack extends SyncManagerEvent {}

class PreviousTrack extends SyncManagerEvent {}

class AddSongToQueue extends SyncManagerEvent {
  final Song song;
  final int? position;

  AddSongToQueue(this.song, {this.position});
}

class PlaybackStateUpdated extends SyncManagerEvent {
  final PlaybackState state;

  PlaybackStateUpdated(this.state);
}

class QueueStateUpdated extends SyncManagerEvent {
  final QueueState state;

  QueueStateUpdated(this.state);
}

class PlayAtIndex extends SyncManagerEvent {
  final int index;

  PlayAtIndex(this.index);
}

class UpdatePlaybackPosition extends SyncManagerEvent {
  final Duration position;

  UpdatePlaybackPosition(this.position);
}

class PickAndAddSongToQueue extends SyncManagerEvent {
  final int? position;

  PickAndAddSongToQueue({this.position});
}

class AddSongFromPath extends SyncManagerEvent {
  final String filePath;
  final int? position;

  AddSongFromPath(this.filePath, {this.position});
}
