import 'dart:async';

import 'package:echosync/services/time_sync.dart';

import '../data/device.dart';
import '../data/protocol/base.dart';
import '../data/protocol/enums.dart';
import '../data/protocol/playback.dart';
import '../data/protocol/queue.dart';
import '../data/song.dart';
import 'audio_handler.dart';
import 'mesh_network.dart';

class SyncManager {
  final MeshNetwork _meshNetwork;
  final TimeSyncService _timeSyncService;
  final String _deviceIp;
  final EchoSyncAudioHandler _audioHandler;

  PlaybackStatus? _localPlaybackStatus;
  QueueStatus? _localQueueStatus;

  final StreamController<PlaybackStatus> _playbackStatusController =
      StreamController.broadcast();
  final StreamController<QueueStatus> _queueStatusController =
      StreamController.broadcast();

  Stream<PlaybackStatus> get playbackStatusStream =>
      _playbackStatusController.stream;

  Stream<QueueStatus> get queueStatusStream => _queueStatusController.stream;

  PlaybackStatus? get currentPlaybackStatus => _localPlaybackStatus;

  QueueStatus? get currentQueueStatus => _localQueueStatus;

  Map<String, Device> get connectedDevices => _meshNetwork.connectedDevices;

  SyncManager({
    required MeshNetwork meshNetwork,
    required TimeSyncService timeSyncService,
    required String deviceIp,
    required EchoSyncAudioHandler audioHandler,
  }) : _meshNetwork = meshNetwork,
       _timeSyncService = timeSyncService,
       _deviceIp = deviceIp,
       _audioHandler = audioHandler {
    // Set up callback for local audio controls
    _audioHandler.onLocalControl = _handleLocalAudioControl;
  }

  void _handleLocalAudioControl(String command, Map<String, dynamic>? params) {
    switch (command) {
      case 'play':
        play(song: _localPlaybackStatus?.currentSong);
        break;
      case 'pause':
        pause();
        break;
      case 'seek':
        seek(Duration(milliseconds: params?['position']));
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

  void handlePlaybackControl(PlaybackControl control) {
    try {
      final localScheduledTime = _timeSyncService.networkToLocalTime(
        control.scheduledTime.millisSinceEpoch,
      );
      final now = DateTime.now().millisecondsSinceEpoch;
      final delay = localScheduledTime - now;

      if (delay > 0) {
        Timer(Duration(milliseconds: delay), () {
          _executePlaybackControl(control);
        });
      } else {
        _executePlaybackControl(control);
      }
    } catch (e) {
      print('Error handling playback control: $e');
    }
  }

  void _executePlaybackControl(PlaybackControl control) {
    if (_localPlaybackStatus == null) return;

    PlaybackStatus newStatus = _localPlaybackStatus!;

    switch (control.command) {
      case 'play':
        final position = control.params?['position'] as Duration?;
        final songData = control.params?['song'] as Map<String, dynamic>?;
        final song = songData != null ? Song.fromJson(songData) : null;

        newStatus = PlaybackStatus(
          currentSong: song ?? newStatus.currentSong,
          position: position ?? newStatus.position,
          isPlaying: true,
          currentIndex: newStatus.currentIndex,
          volume: newStatus.volume,
          shuffleMode: newStatus.shuffleMode,
          repeatMode: newStatus.repeatMode,
          lastUpdated: _timeSyncService.getNetworkTime(),
          deviceId: _deviceIp,
        );
        if (song != null || position != null) {
          print(
            "PIXA SYNC MANAGER: Playing song: ${song?.title}, position: $position",
          );
          _audioHandler.executeSyncedPlay(
            song: song,
            position: position,
            scheduledTime: DateTime.fromMillisecondsSinceEpoch(
              control.scheduledTime.millisSinceEpoch,
            ),
          );
        }
        break;

      case 'pause':
        newStatus = PlaybackStatus(
          currentSong: newStatus.currentSong,
          position: newStatus.position,
          isPlaying: false,
          currentIndex: newStatus.currentIndex,
          volume: newStatus.volume,
          shuffleMode: newStatus.shuffleMode,
          repeatMode: newStatus.repeatMode,
          lastUpdated: _timeSyncService.getNetworkTime(),
          deviceId: _deviceIp,
        );
        _audioHandler.executeSyncedPause(
          scheduledTime: DateTime.fromMillisecondsSinceEpoch(
            control.scheduledTime.millisSinceEpoch,
          ),
        );
        break;

      case 'seek':
        final position = control.params?['position'] as Duration? ?? Duration();
        newStatus = PlaybackStatus(
          currentSong: newStatus.currentSong,
          position: position,
          isPlaying: newStatus.isPlaying,
          currentIndex: newStatus.currentIndex,
          volume: newStatus.volume,
          shuffleMode: newStatus.shuffleMode,
          repeatMode: newStatus.repeatMode,
          lastUpdated: _timeSyncService.getNetworkTime(),
          deviceId: _deviceIp,
        );
        _audioHandler.executeSyncedSeek(position: position);
        break;

      case 'set_volume':
        final volume = control.params?['volume'] as double? ?? 1.0;
        newStatus = PlaybackStatus(
          currentSong: newStatus.currentSong,
          position: newStatus.position,
          isPlaying: newStatus.isPlaying,
          currentIndex: newStatus.currentIndex,
          volume: volume,
          shuffleMode: newStatus.shuffleMode,
          repeatMode: newStatus.repeatMode,
          lastUpdated: _timeSyncService.getNetworkTime(),
          deviceId: _deviceIp,
        );
        break;
    }

    _updateLocalPlaybackStatus(newStatus);
  }

  void _updateLocalPlaybackStatus(PlaybackStatus status) {
    _localPlaybackStatus = status;
    _meshNetwork.updatePlaybackStatus(status);
    _playbackStatusController.add(status);
  }

  void _updateLocalQueueStatus(QueueStatus status) {
    _localQueueStatus = status;
    _meshNetwork.updateQueueStatus(status);
    _queueStatusController.add(status);
  }

  void handleRemotePlaybackStatus(PlaybackStatus status) {
    if (_localPlaybackStatus == null ||
        status.lastUpdated.millisSinceEpoch >
            _localPlaybackStatus!.lastUpdated.millisSinceEpoch) {
      _localPlaybackStatus = status;
      _playbackStatusController.add(status);
    }
  }

  void handleRemoteQueueStatus(QueueStatus status) {
    if (_localQueueStatus == null ||
        status.lastUpdated.millisSinceEpoch >
            _localQueueStatus!.lastUpdated.millisSinceEpoch) {
      _localQueueStatus = status;
      _queueStatusController.add(status);
    }
  }

  Future<void> playAtIndex(int index, {int delayMs = 100}) async {
    if (_localQueueStatus == null ||
        index < 0 ||
        index >= _localQueueStatus!.songs.length) {
      return;
    }

    // Update queue to set the new current index
    final control = QueueControl.playAtIndex(deviceId: _deviceIp, index: index);
    await _meshNetwork.sendQueueControl(control);
    handleQueueControl(control);

    // Get the song at the specified index and play it
    final song = _localQueueStatus!.songs[index];
    await play(song: song, position: Duration(), delayMs: delayMs);
  }

  // Updated public methods for controlling playback
  Future<void> play({Song? song, Duration? position, int delayMs = 100}) async {
    print(
      "PIXA SYNC MANAGER v2: Playing song: ${song?.title}, position: $position",
    );
    final scheduledTime = NetworkTime(
      _timeSyncService.getNetworkTime().millisSinceEpoch + delayMs,
    );
    final control = PlaybackControl.play(
      scheduledTime: scheduledTime,
      deviceId: _deviceIp,
      song: song,
      position: position,
    );
    await _meshNetwork.sendPlaybackControl(control);
    handlePlaybackControl(control);
  }

  Future<void> pause({int delayMs = 100}) async {
    final scheduledTime = NetworkTime(
      _timeSyncService.getNetworkTime().millisSinceEpoch + delayMs,
    );
    final control = PlaybackControl.pause(
      scheduledTime: scheduledTime,
      deviceId: _deviceIp,
    );
    await _meshNetwork.sendPlaybackControl(control);
    handlePlaybackControl(control);
  }

  Future<void> seek(Duration position, {int delayMs = 100}) async {
    final scheduledTime = NetworkTime(
      _timeSyncService.getNetworkTime().millisSinceEpoch + delayMs,
    );
    final control = PlaybackControl.seek(
      scheduledTime: scheduledTime,
      deviceId: _deviceIp,
      position: position,
    );
    print("WHAT DA FUCK IS THIS SEEKING: $position");
    handlePlaybackControl(control);
    await _meshNetwork.sendPlaybackControl(control);
  }

  Future<void> addToQueue(Song song, {int? position}) async {
    final control = QueueControl.add(
      deviceId: _deviceIp,
      song: song,
      position: position,
    );
    await _meshNetwork.sendQueueControl(control);
    handleQueueControl(control);
  }

  Future<void> nextTrack() async {
    final control = QueueControl.next(deviceId: _deviceIp);
    await _meshNetwork.sendQueueControl(control);
    handleQueueControl(control);
  }

  Future<void> previousTrack() async {
    final control = QueueControl.previous(deviceId: _deviceIp);
    await _meshNetwork.sendQueueControl(control);
    handleQueueControl(control);
  }

  void handleQueueControl(QueueControl control) {
    if (_localQueueStatus == null) return;

    QueueStatus newStatus = _localQueueStatus!;

    switch (control.command) {
      case 'add':
        final songData = control.params?['song'] as Map<String, dynamic>?;
        final position = control.params?['position'] as int?;
        if (songData != null) {
          final song = Song.fromJson(songData);
          final newSongs = List<Song>.from(newStatus.songs);
          if (position != null && position < newSongs.length) {
            newSongs.insert(position, song);
          } else {
            newSongs.add(song);
          }

          newStatus = QueueStatus(
            songs: newSongs,
            currentIndex: newStatus.currentIndex,
            shuffleMode: newStatus.shuffleMode,
            repeatMode: newStatus.repeatMode,
            lastUpdated: _timeSyncService.getNetworkTime(),
            deviceId: _deviceIp,
          );
        }
        break;

      case 'remove':
        final index = control.params?['index'] as int?;
        if (index != null && index < newStatus.songs.length) {
          final newSongs = List<Song>.from(newStatus.songs);
          newSongs.removeAt(index);
          int newCurrentIndex = newStatus.currentIndex;
          if (index <= newCurrentIndex && newCurrentIndex > 0) {
            newCurrentIndex--;
          }

          newStatus = QueueStatus(
            songs: newSongs,
            currentIndex: newCurrentIndex,
            shuffleMode: newStatus.shuffleMode,
            repeatMode: newStatus.repeatMode,
            lastUpdated: _timeSyncService.getNetworkTime(),
            deviceId: _deviceIp,
          );
        }
        break;

      case 'replace':
        final songsData = control.params?['songs'] as List?;
        if (songsData != null) {
          final songs =
              songsData
                  .map(
                    (songData) =>
                        Song.fromJson(songData as Map<String, dynamic>),
                  )
                  .toList();
          newStatus = QueueStatus(
            songs: songs,
            currentIndex: 0,
            shuffleMode: newStatus.shuffleMode,
            repeatMode: newStatus.repeatMode,
            lastUpdated: _timeSyncService.getNetworkTime(),
            deviceId: _deviceIp,
          );
        }
        break;

      case 'play_at_index': // Add this new case
        final index = control.params?['index'] as int?;
        if (index != null && index >= 0 && index < newStatus.songs.length) {
          newStatus = QueueStatus(
            songs: newStatus.songs,
            currentIndex: index,
            shuffleMode: newStatus.shuffleMode,
            repeatMode: newStatus.repeatMode,
            lastUpdated: _timeSyncService.getNetworkTime(),
            deviceId: _deviceIp,
          );
        }
        break;

      case 'next':
        int newIndex = newStatus.currentIndex + 1;
        if (newIndex >= newStatus.songs.length) {
          if (newStatus.repeatMode == RepeatMode.all) {
            newIndex = 0;
          } else {
            newIndex = newStatus.songs.length - 1;
          }
        }

        newStatus = QueueStatus(
          songs: newStatus.songs,
          currentIndex: newIndex,
          shuffleMode: newStatus.shuffleMode,
          repeatMode: newStatus.repeatMode,
          lastUpdated: _timeSyncService.getNetworkTime(),
          deviceId: _deviceIp,
        );
        break;

      case 'previous':
        int newIndex = newStatus.currentIndex - 1;
        if (newIndex < 0) {
          if (newStatus.repeatMode == RepeatMode.all) {
            newIndex = newStatus.songs.length - 1;
          } else {
            newIndex = 0;
          }
        }

        newStatus = QueueStatus(
          songs: newStatus.songs,
          currentIndex: newIndex,
          shuffleMode: newStatus.shuffleMode,
          repeatMode: newStatus.repeatMode,
          lastUpdated: _timeSyncService.getNetworkTime(),
          deviceId: _deviceIp,
        );
        break;
    }

    _updateLocalQueueStatus(newStatus);
    if (_localQueueStatus != null) {
      _audioHandler.updateQueueFromSync(
        _localQueueStatus!.songs,
        _localQueueStatus!.currentIndex,
      );
    }
  }

  void initializeState() {
    _localPlaybackStatus = PlaybackStatus(
      currentSong: null,
      position: Duration(),
      isPlaying: false,
      currentIndex: 0,
      volume: 1.0,
      shuffleMode: false,
      repeatMode: RepeatMode.none,
      lastUpdated: _timeSyncService.getNetworkTime(),
      deviceId: _deviceIp,
    );

    _localQueueStatus = QueueStatus(
      songs: [],
      currentIndex: 0,
      shuffleMode: false,
      repeatMode: RepeatMode.none,
      lastUpdated: _timeSyncService.getNetworkTime(),
      deviceId: _deviceIp,
    );

    _meshNetwork.updatePlaybackStatus(_localPlaybackStatus!);
    _meshNetwork.updateQueueStatus(_localQueueStatus!);
  }

  void registerSongFile(String hash, String filePath) {
    _audioHandler.registerSongPath(hash, filePath);
  }

  void dispose() {
    _playbackStatusController.close();
    _queueStatusController.close();
    _timeSyncService.dispose();
  }
}
