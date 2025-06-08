// lib/bloc/sync_manager/sync_manager_bloc.dart
import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:echosync/data/protocol/playback.dart';
import 'package:echosync/data/protocol/queue.dart';
import 'package:echosync/services/audio_file_service.dart';
import 'package:echosync/services/file_server.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/device.dart';
import '../../data/song.dart';
import '../../services/audio_handler.dart';
import '../../services/mesh_network.dart';
import '../../services/sync_manager.dart';
import '../../services/time_sync.dart';

part 'sync_manager_event.dart';
part 'sync_manager_state.dart';

class SyncManagerBloc extends Bloc<SyncManagerEvent, SyncManagerState> {
  SyncManager? _syncManager;
  Directory? _tempDir;
  StreamSubscription<PlaybackState>? _playbackSubscription;
  StreamSubscription<QueueState>? _queueSubscription;

  SyncManagerBloc() : super(SyncManagerInitial()) {
    on<InitializeSyncManager>(_onInitialize);
    on<PlayMusic>(_onPlayMusic);
    on<PauseMusic>(_onPauseMusic);
    on<SeekMusic>(_onSeekMusic);
    on<NextTrack>(_onNextTrack);
    on<PreviousTrack>(_onPreviousTrack);
    on<AddSongToQueue>(_onAddSongToQueue);
    on<PlayAtIndex>(_onPlayAtIndex);
    on<PlaybackStateUpdated>(_onPlaybackUpdated);
    on<QueueStateUpdated>(_onQueueUpdated);
    on<UpdatePlaybackPosition>(_onUpdatePlaybackPosition);
    on<PickAndAddSongToQueue>(_onPickAndAddSong);
    on<PickAndAddMultipleSongsToQueue>(_onPickAndAddMultipleSongs);
    on<AddSongFromPath>(_onAddSongFromPath);
  }

  Future<void> _onInitialize(
    InitializeSyncManager event,
    Emitter<SyncManagerState> emit,
  ) async {
    try {
      emit(SyncManagerInitializing());

      _tempDir = await getTemporaryDirectory();
      final audioHandler = GetIt.instance<EchoSyncAudioHandler>();
      final fileServer = FileServerService();
      await fileServer.initialize();

      _syncManager = SyncManager(
        meshNetwork: event.meshNetwork,
        timeSyncService: event.timeSyncService,
        deviceId: event.deviceIp,
        audioHandler: audioHandler,
        tempDir: _tempDir!,
        fileServer: fileServer,
      );

      // Subscribe to local state updates
      _playbackSubscription = _syncManager!.playbackStateStream.listen((state) {
        add(PlaybackStateUpdated(state));
      });

      _queueSubscription = _syncManager!.queueStateStream.listen((state) {
        add(QueueStateUpdated(state));
      });

      _syncManager!.initializeState();

      // Emit initial ready state
      emit(
        SyncManagerReady(
          syncManager: _syncManager!,
          playbackState: _syncManager!.currentPlaybackState,
          queueState: _syncManager!.currentQueueState,
          connectedDevices: event.meshNetwork.connectedDevices,
        ),
      );
    } catch (e) {
      emit(SyncManagerError(e.toString()));
    }
  }

  Future<void> _onUpdatePlaybackPosition(
    UpdatePlaybackPosition event,
    Emitter<SyncManagerState> emit,
  ) async {
    if (state is SyncManagerReady && _syncManager != null) {
      final currentState = state as SyncManagerReady;
      if (currentState.playbackState != null) {
        final updatedState = currentState.playbackState!.copyWith(
          position: event.position,
        );

        emit(currentState.copyWith(playbackState: updatedState));
      }
    }
  }

  Future<void> _onPlayMusic(
    PlayMusic event,
    Emitter<SyncManagerState> emit,
  ) async {
    if (_syncManager != null) {
      await _syncManager!.play(song: event.song, position: event.position);
    }
  }

  Future<void> _onPauseMusic(
    PauseMusic event,
    Emitter<SyncManagerState> emit,
  ) async {
    if (_syncManager != null) {
      await _syncManager!.pause();
    }
  }

  Future<void> _onSeekMusic(
    SeekMusic event,
    Emitter<SyncManagerState> emit,
  ) async {
    if (_syncManager != null) {
      await _syncManager!.seek(event.position);
    }
  }

  Future<void> _onNextTrack(
    NextTrack event,
    Emitter<SyncManagerState> emit,
  ) async {
    if (_syncManager != null) {
      await _syncManager!.nextTrack();
    }
  }

  Future<void> _onPreviousTrack(
    PreviousTrack event,
    Emitter<SyncManagerState> emit,
  ) async {
    if (_syncManager != null) {
      await _syncManager!.previousTrack();
    }
  }

  Future<void> _onAddSongToQueue(
    AddSongToQueue event,
    Emitter<SyncManagerState> emit,
  ) async {
    if (_syncManager != null) {
      await _syncManager!.addToQueue(event.song, position: event.position);
    }
  }

  Future<void> _onPlayAtIndex(
    PlayAtIndex event,
    Emitter<SyncManagerState> emit,
  ) async {
    if (_syncManager != null) {
      await _syncManager!.playAtIndex(event.index);
    }
  }

  void _onPlaybackUpdated(
    PlaybackStateUpdated event,
    Emitter<SyncManagerState> emit,
  ) {
    if (state is SyncManagerReady) {
      final currentState = state as SyncManagerReady;
      emit(currentState.copyWith(playbackState: event.state));
    }
  }

  void _onQueueUpdated(
    QueueStateUpdated event,
    Emitter<SyncManagerState> emit,
  ) {
    if (state is SyncManagerReady) {
      final currentState = state as SyncManagerReady;
      emit(currentState.copyWith(queueState: event.state));
    }
  }

  Future<void> _onPickAndAddSong(
    PickAndAddSongToQueue event,
    Emitter<SyncManagerState> emit,
  ) async {
    try {
      Song? song = await AudioFileService.pickSingleAudioFile();
      if (song != null && _syncManager != null) {
        await _syncManager!.addToQueue(song, position: event.position);
      }
    } catch (e) {
      debugPrint('Error picking and adding song: $e');
    }
  }

  Future<void> _onPickAndAddMultipleSongs(
    PickAndAddMultipleSongsToQueue event,
    Emitter<SyncManagerState> emit,
  ) async {
    try {
      List<Song>? songs = await AudioFileService.pickAudioFiles();
      if (songs != null && _syncManager != null) {
        for (int i = 0; i < songs.length; i++) {
          int? position = event.position != null ? event.position! + i : null;
          await _syncManager!.addToQueue(songs[i], position: position);
        }
      }
    } catch (e) {
      debugPrint('Error picking and adding multiple songs: $e');
    }
  }

  Future<void> _onAddSongFromPath(
    AddSongFromPath event,
    Emitter<SyncManagerState> emit,
  ) async {
    try {
      Song? song = await AudioFileService.createSongFromPath(event.filePath);
      if (song != null && _syncManager != null) {
        await _syncManager!.addToQueue(song, position: event.position);
      }
    } catch (e) {
      debugPrint('Error adding song from path: $e');
    }
  }

  @override
  Future<void> close() {
    _playbackSubscription?.cancel();
    _queueSubscription?.cancel();
    _syncManager?.dispose();
    return super.close();
  }
}
