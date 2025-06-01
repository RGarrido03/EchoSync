import 'dart:async';

import 'package:echosync/services/time_sync.dart';

import '../data/device.dart';
import '../data/protocol/base.dart';
import '../data/protocol/enums.dart';
import '../data/protocol/playback.dart';
import '../data/protocol/queue.dart';
import 'mesh_network.dart';

class SyncManager {
  final MeshNetwork _meshNetwork;
  final TimeSyncService _timeSyncService;
  final String _deviceIp;

  // Current state
  PlaybackStatus? _localPlaybackStatus;
  QueueStatus? _localQueueStatus;
  bool _isLeader = false;

  // Event streams
  final StreamController<PlaybackStatus> _playbackStateStream =
      StreamController.broadcast();
  final StreamController<QueueStatus> _queueStateStream =
      StreamController.broadcast();
  final StreamController<String> _errorStream = StreamController.broadcast();

  // Public streams
  Stream<PlaybackStatus> get playbackStateStream => _playbackStateStream.stream;

  Stream<QueueStatus> get queueStateStream => _queueStateStream.stream;

  Stream<String> get errorStream => _errorStream.stream;

  // Getters
  PlaybackStatus? get currentPlaybackStatus => _localPlaybackStatus;

  QueueStatus? get currentQueueStatus => _localQueueStatus;

  bool get isLeader => _isLeader;

  Map<String, Device> get connectedDevices => _meshNetwork.connectedDevices;

  SyncManager({
    required MeshNetwork meshNetwork,
    required TimeSyncService timeSyncService,
    required String deviceIp,
  }) : _meshNetwork = meshNetwork,
       _timeSyncService = timeSyncService,
       _deviceIp = deviceIp {
    _setupListeners();
  }

  void _setupListeners() {
    // Listen to remote playback controls
    _meshNetwork.playbackControlStream.listen(_handlePlaybackControl);

    // Listen to remote queue controls
    _meshNetwork.queueControlStream.listen(_handleQueueControl);

    // Listen to playback status updates from other devices
    _meshNetwork.playbackStatusStream.listen(_handleRemotePlaybackStatus);

    // Listen to queue status updates from other devices
    _meshNetwork.queueStatusStream.listen(_handleRemoteQueueStatus);
  }

  void _handlePlaybackControl(PlaybackControl control) {
    try {
      // Convert scheduled time to local time
      final localScheduledTime = _timeSyncService.networkToLocalTime(
        control.scheduledTime.millisSinceEpoch,
      );
      final now = DateTime.now().millisecondsSinceEpoch;
      final delay = localScheduledTime - now;

      if (delay > 0) {
        // Schedule the action for future execution
        Timer(Duration(milliseconds: delay), () {
          _executePlaybackControl(control);
        });
      } else {
        // Execute immediately if the time has already passed
        _executePlaybackControl(control);
      }
    } catch (e) {
      _errorStream.add('Error handling playback control: $e');
    }
  }

  void _executePlaybackControl(PlaybackControl control) {
    if (_localPlaybackStatus == null) return;

    PlaybackStatus newStatus = _localPlaybackStatus!;

    switch (control.command) {
      case 'play':
        final position = control.params?['position'] as int?;
        final songHash = control.params?['songHash'] as String?;

        newStatus = PlaybackStatus(
          currentSong: songHash ?? newStatus.currentSong,
          position: position ?? newStatus.position,
          isPlaying: true,
          currentIndex: newStatus.currentIndex,
          volume: newStatus.volume,
          shuffleMode: newStatus.shuffleMode,
          repeatMode: newStatus.repeatMode,
          lastUpdated: _timeSyncService.getNetworkTime(),
          deviceId: _deviceIp,
        );
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
        break;

      case 'seek':
        final position = control.params?['position'] as int? ?? 0;
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
    _playbackStateStream.add(status);
  }

  void _updateLocalQueueStatus(QueueStatus status) {
    _localQueueStatus = status;
    _meshNetwork.updateQueueStatus(status);
    _queueStateStream.add(status);
  }

  void _handleRemotePlaybackStatus(PlaybackStatus status) {
    // Only update if the remote status is newer than our local status
    if (_localPlaybackStatus == null ||
        status.lastUpdated.millisSinceEpoch >
            _localPlaybackStatus!.lastUpdated.millisSinceEpoch) {
      _localPlaybackStatus = status;
      _playbackStateStream.add(status);
    }
  }

  void _handleRemoteQueueStatus(QueueStatus status) {
    // Only update if the remote status is newer than our local status
    if (_localQueueStatus == null ||
        status.lastUpdated.millisSinceEpoch >
            _localQueueStatus!.lastUpdated.millisSinceEpoch) {
      _localQueueStatus = status;
      _queueStateStream.add(status);
    }
  }

  // Public methods for controlling playback

  Future<void> play({
    String? songHash,
    int? position,
    int delayMs = 100,
  }) async {
    final scheduledTime = NetworkTime(
      _timeSyncService.getNetworkTime().millisSinceEpoch + delayMs,
    );

    final control = PlaybackControl.play(
      scheduledTime: scheduledTime,
      deviceId: _deviceIp,
      songHash: songHash,
      position: position,
    );

    await _meshNetwork.sendPlaybackControl(control);
    _handlePlaybackControl(control);
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
    _handlePlaybackControl(control);
  }

  Future<void> seek(int position, {int delayMs = 100}) async {
    final scheduledTime = NetworkTime(
      _timeSyncService.getNetworkTime().millisSinceEpoch + delayMs,
    );

    final control = PlaybackControl.seek(
      scheduledTime: scheduledTime,
      deviceId: _deviceIp,
      position: position,
    );

    await _meshNetwork.sendPlaybackControl(control);
    _handlePlaybackControl(control);
  }

  Future<void> addToQueue(String songHash, {int? position}) async {
    final control = QueueControl.add(
      deviceId: _deviceIp,
      songHash: songHash,
      position: position,
    );

    await _meshNetwork.sendQueueControl(control);
    _handleQueueControl(control);
  }

  Future<void> nextTrack() async {
    final control = QueueControl.next(deviceId: _deviceIp);
    await _meshNetwork.sendQueueControl(control);
    _handleQueueControl(control);
  }

  Future<void> previousTrack() async {
    final control = QueueControl.previous(deviceId: _deviceIp);
    await _meshNetwork.sendQueueControl(control);
    _handleQueueControl(control);
  }

  void _handleQueueControl(QueueControl control) {
    if (_localQueueStatus == null) return;

    QueueStatus newStatus = _localQueueStatus!;

    switch (control.command) {
      case 'add':
        final songHash = control.params?['songHash'] as String?;
        final position = control.params?['position'] as int?;

        if (songHash != null) {
          final newSongs = List<String>.from(newStatus.songs);
          if (position != null && position < newSongs.length) {
            newSongs.insert(position, songHash);
          } else {
            newSongs.add(songHash);
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
          final newSongs = List<String>.from(newStatus.songs);
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
        final songs = control.params?['songs'] as List<dynamic>?;
        if (songs != null) {
          newStatus = QueueStatus(
            songs: songs.cast<String>(),
            currentIndex: 0,
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
          if (newStatus.repeatMode == 'all') {
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
  }

  // Initialize with default state
  void initializeState() {
    _localPlaybackStatus = PlaybackStatus(
      currentSong: null,
      position: 0,
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

  void setAsLeader() {
    _isLeader = true;
    _timeSyncService.setAsLeader();
  }

  void setAsFollower() {
    _isLeader = false;
    _timeSyncService.setAsFollower();
  }

  void dispose() {
    _playbackStateStream.close();
    _queueStateStream.close();
    _errorStream.close();
    _timeSyncService.dispose();
  }
}
