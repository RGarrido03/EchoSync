// lib/bloc/sync_manager/sync_manager_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/device.dart';
import '../../data/protocol/playback.dart';
import '../../data/protocol/queue.dart';
import '../../services/mesh_network.dart';
import '../../services/sync_manager.dart';
import '../../services/time_sync.dart';

part 'sync_manager_event.dart';
part 'sync_manager_state.dart';

class SyncManagerBloc extends Bloc<SyncManagerEvent, SyncManagerState> {
  SyncManager? _syncManager;

  SyncManager? get syncManager => _syncManager;

  SyncManagerBloc() : super(SyncManagerInitial()) {
    on<InitializeSyncManager>(_onInitialize);
    on<PlayMusic>(_onPlay);
    on<PauseMusic>(_onPause);
    on<SeekToPosition>(_onSeek);
    on<NextTrack>(_onNext);
    on<PreviousTrack>(_onPrevious);
    on<AddSongToQueue>(_onAddToQueue);
    on<PlaybackStatusUpdated>(_onPlaybackUpdated);
    on<QueueStatusUpdated>(_onQueueUpdated);
  }

  Future<void> _onInitialize(
    InitializeSyncManager event,
    Emitter<SyncManagerState> emit,
  ) async {
    try {
      emit(SyncManagerInitializing());

      _syncManager = SyncManager(
        meshNetwork: event.meshNetwork,
        timeSyncService: event.timeSyncService,
        deviceIp: event.deviceIp,
      );

      // Set BLoC reference in the service for direct event emission
      _syncManager!.setBlocReference(this);

      _syncManager!.initializeState();

      // Also set reference in MeshNetwork for playback/queue updates
      event.meshNetwork.setBlocReferences(syncManagerBloc: this);

      emit(
        SyncManagerReady(
          syncManager: _syncManager!,
          playbackStatus: _syncManager!.currentPlaybackStatus,
          queueStatus: _syncManager!.currentQueueStatus,
          connectedDevices: _syncManager!.connectedDevices,
        ),
      );
    } catch (e) {
      emit(SyncManagerError(e.toString()));
    }
  }

  Future<void> _onPlay(PlayMusic event, Emitter<SyncManagerState> emit) async {
    if (_syncManager != null) {
      await _syncManager!.play(
        songHash: event.songHash,
        position: event.position,
      );
    }
  }

  Future<void> _onPause(
    PauseMusic event,
    Emitter<SyncManagerState> emit,
  ) async {
    if (_syncManager != null) {
      await _syncManager!.pause();
    }
  }

  Future<void> _onSeek(
    SeekToPosition event,
    Emitter<SyncManagerState> emit,
  ) async {
    if (_syncManager != null) {
      await _syncManager!.seek(event.position);
    }
  }

  Future<void> _onNext(NextTrack event, Emitter<SyncManagerState> emit) async {
    if (_syncManager != null) {
      await _syncManager!.nextTrack();
    }
  }

  Future<void> _onPrevious(
    PreviousTrack event,
    Emitter<SyncManagerState> emit,
  ) async {
    if (_syncManager != null) {
      await _syncManager!.previousTrack();
    }
  }

  Future<void> _onAddToQueue(
    AddSongToQueue event,
    Emitter<SyncManagerState> emit,
  ) async {
    if (_syncManager != null) {
      await _syncManager!.addToQueue(event.songHash, position: event.position);
    }
  }

  void _onPlaybackUpdated(
    PlaybackStatusUpdated event,
    Emitter<SyncManagerState> emit,
  ) {
    if (state is SyncManagerReady) {
      final currentState = state as SyncManagerReady;
      emit(
        currentState.copyWith(
          playbackStatus: event.status,
          connectedDevices:
              _syncManager?.connectedDevices ?? currentState.connectedDevices,
        ),
      );
    }
  }

  void _onQueueUpdated(
    QueueStatusUpdated event,
    Emitter<SyncManagerState> emit,
  ) {
    if (state is SyncManagerReady) {
      final currentState = state as SyncManagerReady;
      emit(
        currentState.copyWith(
          queueStatus: event.status,
          connectedDevices:
              _syncManager?.connectedDevices ?? currentState.connectedDevices,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _syncManager?.dispose();
    return super.close();
  }
}
