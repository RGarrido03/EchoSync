import 'dart:async';
import 'dart:io';

import 'package:echosync/services/time_sync.dart';
import 'package:flutter/foundation.dart';

import '../data/device.dart';
import '../data/protocol/base.dart';
import '../data/protocol/enums.dart';
import '../data/protocol/playback.dart';
import '../data/protocol/queue.dart';
import '../data/song.dart';
import 'audio_handler.dart';
import 'cover_file_service.dart';
import 'file_download.dart';
import 'file_server.dart';
import 'mesh_network.dart';

class SyncManager {
  final MeshNetwork _meshNetwork;
  final TimeSyncService _timeSyncService;
  final String _deviceId;
  final EchoSyncAudioHandler _audioHandler;
  late final Directory tempDir;
  late final FileServerService fileServer;

  PlaybackState? _localPlaybackState;
  QueueState? _localQueueState;

  late final StreamSubscription _playbackStateSubscription;
  late final StreamSubscription _queueStateSubscription;
  late final StreamSubscription _playbackCommandSubscription;
  late final StreamSubscription _queueCommandSubscription;

  final StreamController<PlaybackState> _playbackStateController =
      StreamController.broadcast();
  final StreamController<QueueState> _queueStateController =
      StreamController.broadcast();

  Stream<PlaybackState> get playbackStateStream =>
      _playbackStateController.stream;

  Stream<QueueState> get queueStateStream => _queueStateController.stream;

  PlaybackState? get currentPlaybackState => _localPlaybackState;

  QueueState? get currentQueueState => _localQueueState;

  Map<String, Device> get connectedDevices => _meshNetwork.connectedDevices;

  SyncManager({
    required MeshNetwork meshNetwork,
    required TimeSyncService timeSyncService,
    required String deviceId,
    required EchoSyncAudioHandler audioHandler,
    required this.tempDir,
    required this.fileServer,
  }) : _meshNetwork = meshNetwork,
       _timeSyncService = timeSyncService,
       _deviceId = deviceId,
       _audioHandler = audioHandler {
    // Set up callback for local audio controls
    _audioHandler.onLocalControl = _handleLocalAudioControl;
    _initializeStreamSubscriptions();
  }

  void _initializeStreamSubscriptions() {
    // Subscribe to remote state updates
    _playbackStateSubscription = _meshNetwork.streams.playbackStateStream
        .listen(_handleRemotePlaybackState);
    _queueStateSubscription = _meshNetwork.streams.queueStateStream.listen(
      _handleRemoteQueueState,
    );

    // Subscribe to remote commands
    _playbackCommandSubscription = _meshNetwork.streams.playbackCommandStream
        .listen(_handleRemotePlaybackCommand);
    _queueCommandSubscription = _meshNetwork.streams.queueCommandStream.listen(
      _handleRemoteQueueCommand,
    );
  }

  void _handleLocalAudioControl(String command, Map<String, dynamic>? params) {
    switch (command) {
      case 'play':
        play(song: _localPlaybackState?.currentSong);
        break;
      case 'pause':
        pause();
        break;
      case 'seek':
        final positionMs = params?['position'] as int?;
        if (positionMs != null) {
          seek(Duration(milliseconds: positionMs));
        }
        break;
      case 'next':
        nextTrack();
        break;
      case 'previous':
        previousTrack();
        break;
      case 'play_at_index':
        final index = params?['index'] as int? ?? 0;
        playAtIndex(index);
        break;
    }
  }

  void _handleRemotePlaybackCommand(PlaybackCommand command) {
    debugPrint(
      'Received remote playback command: ${command.command} from ${command.senderId}',
    );
    try {
      final localScheduledTime = _timeSyncService.networkToLocalTime(
        command.scheduledTime.millisSinceEpoch,
      );
      final now = DateTime.now().millisecondsSinceEpoch;
      final delay = localScheduledTime - now;

      Timer(Duration(milliseconds: delay > 0 ? delay : 0), () {
        {
          if (_localPlaybackState == null) return;

          PlaybackState newState = _localPlaybackState!;

          switch (command.command) {
            case 'play':
              final positionMs = command.params?['position'] as int?;
              final position =
                  positionMs != null
                      ? Duration(milliseconds: positionMs)
                      : null;
              final songData = command.params?['song'] as Map<String, dynamic>?;
              final song = songData != null ? Song.fromJson(songData) : null;

              newState = _localPlaybackState!.copyWith(
                currentSong: song ?? newState.currentSong,
                position: position ?? newState.position,
                isPlaying: true,
                lastUpdated: _timeSyncService.getNetworkTime(),
                updatedByDevice: _deviceId,
              );

              if (song != null) {
                _audioHandler.executeSyncedPlay(
                  song: song,
                  position: position,
                  scheduledTime: DateTime.fromMillisecondsSinceEpoch(
                    command.scheduledTime.millisSinceEpoch,
                  ),
                );
              }
              break;

            case 'pause':
              newState = _localPlaybackState!.copyWith(
                isPlaying: false,
                lastUpdated: _timeSyncService.getNetworkTime(),
                updatedByDevice: _deviceId,
              );

              _audioHandler.executeSyncedPause(
                scheduledTime: DateTime.fromMillisecondsSinceEpoch(
                  command.scheduledTime.millisSinceEpoch,
                ),
              );
              break;

            case 'seek':
              final positionMs = command.params?['position'] as int? ?? 0;
              final position = Duration(milliseconds: positionMs);

              newState = _localPlaybackState!.copyWith(
                position: position,
                lastUpdated: _timeSyncService.getNetworkTime(),
                updatedByDevice: _deviceId,
              );

              _audioHandler.executeSyncedSeek(position: position);
              break;

            case 'set_volume':
              final volume = command.params?['volume'] as double? ?? 1.0;
              newState = _localPlaybackState!.copyWith(
                volume: volume,
                lastUpdated: _timeSyncService.getNetworkTime(),
                updatedByDevice: _deviceId,
              );
              break;
          }

          _updateLocalPlaybackState(newState);
        }
      });
    } catch (e) {
      debugPrint('Error handling remote playback command: $e');
    }
  }

  void _handleRemoteQueueCommand(QueueCommand command) {
    if (_localQueueState == null) return;

    QueueState newState = _localQueueState!;

    switch (command.command) {
      case 'add':
        final songData = command.params?['song'] as Map<String, dynamic>?;
        final position = command.params?['position'] as int?;

        if (songData == null) {
          debugPrint('No song data provided for add command');
          return;
        }

        final song = Song.fromJson(songData);
        _downloadSongIfNeeded(song);

        final newSongs = List<Song>.from(newState.songs);
        if (position != null && position < newSongs.length) {
          newSongs.insert(position, song);
        } else {
          newSongs.add(song);
        }

        newState = newState.copyWith(
          songs: newSongs,
          lastUpdated: _timeSyncService.getNetworkTime(),
          updatedByDevice: _deviceId,
        );
        break;

      case 'remove':
        final index = command.params?['index'] as int?;
        if (index != null && index < newState.songs.length) {
          final newSongs = List<Song>.from(newState.songs);
          newSongs.removeAt(index);

          int newCurrentIndex = newState.currentIndex;
          if (index <= newCurrentIndex && newCurrentIndex > 0) {
            newCurrentIndex--;
          }

          newState = newState.copyWith(
            songs: newSongs,
            currentIndex: newCurrentIndex,
            lastUpdated: _timeSyncService.getNetworkTime(),
            updatedByDevice: _deviceId,
          );
        }
        break;

      case 'replace':
        final songsData = command.params?['songs'] as List?;
        if (songsData != null) {
          final songs =
              songsData
                  .map(
                    (songData) =>
                        Song.fromJson(songData as Map<String, dynamic>),
                  )
                  .toList();

          for (final song in songs) {
            _downloadSongIfNeeded(song);
          }

          newState = newState.copyWith(
            songs: songs,
            currentIndex: 0,
            lastUpdated: _timeSyncService.getNetworkTime(),
            updatedByDevice: _deviceId,
          );
        }
        break;

      case 'set_current_index':
        final index = command.params?['index'] as int?;
        if (index != null && index >= 0 && index < newState.songs.length) {
          newState = newState.copyWith(
            currentIndex: index,
            lastUpdated: _timeSyncService.getNetworkTime(),
            updatedByDevice: _deviceId,
          );
        }
        break;

      case 'set_shuffle':
        final enabled = command.params?['enabled'] as bool? ?? false;
        newState = newState.copyWith(
          shuffleMode: enabled,
          lastUpdated: _timeSyncService.getNetworkTime(),
          updatedByDevice: _deviceId,
        );
        break;

      case 'set_repeat':
        final modeString = command.params?['mode'] as String?;
        final mode = RepeatMode.values.firstWhere(
          (m) => m.name == modeString,
          orElse: () => RepeatMode.none,
        );
        newState = newState.copyWith(
          repeatMode: mode,
          lastUpdated: _timeSyncService.getNetworkTime(),
          updatedByDevice: _deviceId,
        );
        break;
    }

    _updateLocalQueueState(newState);
  }

  Future<void> _downloadSongIfNeeded(Song song) async {
    if (song.downloadUrl != null) {
      final localPath = '${tempDir.path}/${song.hash}.${song.extension}';
      final success = await FileDownloadService.downloadFile(
        song.downloadUrl!,
        localPath,
      );

      if (!success) {
        throw Exception('Failed to download song: ${song.title}');
      }

      if (song.cover != null) {
        final existingCoverPath = await CoverFileService.getCoverFilePath(
          song.hash,
        );
        if (existingCoverPath == null) {
          await CoverFileService.saveCoverToFile(song.hash, song.cover!);
        }
      }
    }
  }

  void _updateLocalPlaybackState(PlaybackState state) {
    _localPlaybackState = state;
    _meshNetwork.publishPlaybackState(state);
    _playbackStateController.add(state);
  }

  void _updateLocalQueueState(QueueState state) {
    debugPrint("updateLocalQueueState");
    _localQueueState = state;
    _meshNetwork.publishQueueState(state);
    _queueStateController.add(state);

    _audioHandler.updateQueueFromSync(state.songs, state.currentIndex);
  }

  void _handleRemotePlaybackState(PlaybackState state) {
    if (_localPlaybackState == null ||
        state.lastUpdated.millisSinceEpoch >
            _localPlaybackState!.lastUpdated.millisSinceEpoch) {
      _localPlaybackState = state;
      _playbackStateController.add(state);
    }
  }

  void _handleRemoteQueueState(QueueState state) {
    if (_localQueueState == null ||
        state.lastUpdated.millisSinceEpoch >
            _localQueueState!.lastUpdated.millisSinceEpoch) {
      _localQueueState = state;
      _queueStateController.add(state);
    }
  }

  // Public control methods
  Future<void> play({Song? song, Duration? position, int delayMs = 100}) async {
    debugPrint("Playing song: ${song?.title}, position: $position");
    final scheduledTime = NetworkTime(
      _timeSyncService.getNetworkTime().millisSinceEpoch + delayMs,
    );

    final command = PlaybackCommand.play(
      scheduledTime: scheduledTime,
      senderId: _deviceId,
      song: song,
      position: position,
    );

    await _meshNetwork.publishPlaybackCommand(command);
  }

  Future<void> pause({int delayMs = 100}) async {
    final scheduledTime = NetworkTime(
      _timeSyncService.getNetworkTime().millisSinceEpoch + delayMs,
    );

    final command = PlaybackCommand.pause(
      scheduledTime: scheduledTime,
      senderId: _deviceId,
    );

    await _meshNetwork.publishPlaybackCommand(command);
  }

  Future<void> seek(Duration position, {int delayMs = 100}) async {
    final scheduledTime = NetworkTime(
      _timeSyncService.getNetworkTime().millisSinceEpoch + delayMs,
    );

    final command = PlaybackCommand.seek(
      scheduledTime: scheduledTime,
      senderId: _deviceId,
      position: position,
    );

    await _meshNetwork.publishPlaybackCommand(command);
  }

  Future<void> addToQueue(Song song, {int? position}) async {
    final downloadUrl = fileServer.getFileUrl('${song.hash}.${song.extension}');
    final songWithUrl = song.copyWith(downloadUrl: downloadUrl);

    final command = QueueCommand.add(
      senderId: _deviceId,
      song: songWithUrl,
      position: position,
    );

    await _meshNetwork.publishQueueCommand(command);
  }

  Future<void> playAtIndex(int index, {int delayMs = 100}) async {
    if (_localQueueState == null ||
        index < 0 ||
        index >= _localQueueState!.songs.length) {
      return;
    }

    // Update queue current index
    final queueCommand = QueueCommand.setCurrentIndex(
      senderId: _deviceId,
      index: index,
    );
    await _meshNetwork.publishQueueCommand(queueCommand);

    // Play the song at the specified index
    final song = _localQueueState!.songs[index];
    await play(song: song, position: Duration.zero, delayMs: delayMs);
  }

  Future<void> nextTrack() async {
    if (_localQueueState == null) return;

    int newIndex = _localQueueState!.currentIndex + 1;
    if (newIndex >= _localQueueState!.songs.length) {
      if (_localQueueState!.repeatMode == RepeatMode.all) {
        newIndex = 0;
      } else {
        return; // Don't go past the end
      }
    }

    await playAtIndex(newIndex);
  }

  Future<void> previousTrack() async {
    if (_localQueueState == null) return;

    int newIndex = _localQueueState!.currentIndex - 1;
    if (newIndex < 0) {
      if (_localQueueState!.repeatMode == RepeatMode.all) {
        newIndex = _localQueueState!.songs.length - 1;
      } else {
        newIndex = 0;
      }
    }

    await playAtIndex(newIndex);
  }

  void initializeState() {
    debugPrint("initializeState");
    _localPlaybackState = PlaybackState(
      currentSong: null,
      position: Duration.zero,
      isPlaying: false,
      currentIndex: 0,
      volume: 1.0,
      shuffleMode: false,
      repeatMode: RepeatMode.none,
      lastUpdated: _timeSyncService.getNetworkTime(),
      updatedByDevice: _deviceId,
    );

    _localQueueState = QueueState(
      songs: [],
      currentIndex: -1,
      shuffleMode: false,
      repeatMode: RepeatMode.none,
      lastUpdated: _timeSyncService.getNetworkTime(),
      updatedByDevice: _deviceId,
    );

    _meshNetwork.publishPlaybackState(_localPlaybackState!);
    _meshNetwork.publishQueueState(_localQueueState!);
  }

  void dispose() {
    _playbackStateSubscription.cancel();
    _queueStateSubscription.cancel();
    _playbackCommandSubscription.cancel();
    _queueCommandSubscription.cancel();
    _playbackStateController.close();
    _queueStateController.close();
  }
}
