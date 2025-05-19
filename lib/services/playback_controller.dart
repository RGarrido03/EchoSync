// lib/services/playback_controller.dart
import 'dart:async';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'mesh_network.dart';
import 'time_sync.dart';

enum PlaybackRole { leader, follower }

class PlaybackController extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final MeshNetwork _meshNetwork;
  final TimeSyncService _timeSync;

  PlaybackRole _role = PlaybackRole.follower;
  String _currentSongId = '';
  String _currentSongHash = '';
  List<Map<String, dynamic>> _playlist = [];
  int _currentIndex = -1;
  bool _isPlaying = false;

  // Command execution delay buffer (milliseconds)
  static const int _commandBuffer = 200;

  PlaybackController({
    required MeshNetwork meshNetwork,
    required TimeSyncService timeSync,
  }) : _meshNetwork = meshNetwork,
       _timeSync = timeSync {
    // Listen to network messages
    _meshNetwork.messageStream.listen(_handleMessage);

    // Listen to playback state changes
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (_role == PlaybackRole.leader) {
          playNext();
        }
      }
    });
  }

  // Getters
  PlaybackRole get role => _role;

  List<Map<String, dynamic>> get playlist => _playlist;

  int get currentIndex => _currentIndex;

  bool get isPlaying => _isPlaying;

  Duration? get duration => _audioPlayer.duration;

  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  // Set this device as the leader
  void setAsLeader() {
    _role = PlaybackRole.leader;
    _timeSync.setAsLeader();
    _timeSync.startPeriodicSync();
    notifyListeners();
  }

  // Set this device as a follower
  void setAsFollower() {
    _role = PlaybackRole.follower;
    _timeSync.startPeriodicSync();
    notifyListeners();
  }

  // Handle incoming network messages
  void _handleMessage(Map<String, dynamic> message) {
    if (!message.containsKey('command')) return;

    switch (message['command']) {
      case 'play':
        _handlePlayCommand(message);
        break;
      case 'pause':
        _handlePauseCommand(message);
        break;
      case 'seek':
        _handleSeekCommand(message);
        break;
      case 'next':
        _handleNextCommand(message);
        break;
      case 'previous':
        _handlePreviousCommand(message);
        break;
      case 'update_playlist':
        _handlePlaylistUpdate(message);
        break;
      case 'sync_state':
        _handleSyncState(message);
        break;
    }
  }

  // Handle play command
  void _handlePlayCommand(Map<String, dynamic> message) {
    final int scheduledTime = message['scheduled_time'];
    final String songId = message['song_id'];
    final String songHash = message['song_hash'];
    final int position = message['position'] ?? 0;

    // Convert network time to local time
    final int localScheduledTime = _timeSync.networkToLocalTime(scheduledTime);
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int delayMs = max(0, localScheduledTime - now);

    // Check if we have this song
    if (_currentSongId != songId || _currentSongHash != songHash) {
      _loadSong(songId, songHash).then((_) {
        _schedulePlay(delayMs, position);
      });
    } else {
      _schedulePlay(delayMs, position);
    }
  }

  // Schedule playback after delay
  void _schedulePlay(int delayMs, int position) {
    Future.delayed(Duration(milliseconds: delayMs), () {
      _audioPlayer.seek(Duration(milliseconds: position));
      _audioPlayer.play();
      _isPlaying = true;
      notifyListeners();
    });
  }

  // Handle pause command
  void _handlePauseCommand(Map<String, dynamic> message) {
    final int scheduledTime = message['scheduled_time'];

    // Convert to local time and schedule pause
    final int localScheduledTime = _timeSync.networkToLocalTime(scheduledTime);
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int delayMs = max(0, localScheduledTime - now);

    Future.delayed(Duration(milliseconds: delayMs), () {
      _audioPlayer.pause();
      _isPlaying = false;
      notifyListeners();
    });
  }

  // Handle seek command
  void _handleSeekCommand(Map<String, dynamic> message) {
    final int scheduledTime = message['scheduled_time'];
    final int position = message['position'];

    // Convert to local time and schedule seek
    final int localScheduledTime = _timeSync.networkToLocalTime(scheduledTime);
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int delayMs = max(0, localScheduledTime - now);

    Future.delayed(Duration(milliseconds: delayMs), () {
      _audioPlayer.seek(Duration(milliseconds: position));
      notifyListeners();
    });
  }

  // Handle next command
  void _handleNextCommand(Map<String, dynamic> message) {
    final int scheduledTime = message['scheduled_time'];
    final int songIndex = message['song_index'];

    // Convert to local time and schedule
    final int localScheduledTime = _timeSync.networkToLocalTime(scheduledTime);
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int delayMs = max(0, localScheduledTime - now);

    Future.delayed(Duration(milliseconds: delayMs), () {
      _currentIndex = songIndex;
      _loadCurrentSong().then((_) {
        _audioPlayer.play();
        _isPlaying = true;
        notifyListeners();
      });
    });
  }

  // Handle previous command
  void _handlePreviousCommand(Map<String, dynamic> message) {
    final int scheduledTime = message['scheduled_time'];
    final int songIndex = message['song_index'];

    // Convert to local time and schedule
    final int localScheduledTime = _timeSync.networkToLocalTime(scheduledTime);
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int delayMs = max(0, localScheduledTime - now);

    Future.delayed(Duration(milliseconds: delayMs), () {
      _currentIndex = songIndex;
      _loadCurrentSong().then((_) {
        _audioPlayer.play();
        _isPlaying = true;
        notifyListeners();
      });
    });
  }

  // Handle playlist update
  void _handlePlaylistUpdate(Map<String, dynamic> message) {
    _playlist = List<Map<String, dynamic>>.from(message['playlist']);
    notifyListeners();
  }

  // Handle sync state request (when a new device joins)
  void _handleSyncState(Map<String, dynamic> message) {
    // Only leader responds to sync state requests
    if (_role != PlaybackRole.leader) return;

    final state = {
      'command': 'sync_state_response',
      'playlist': _playlist,
      'current_index': _currentIndex,
      'is_playing': _isPlaying,
      'position': _audioPlayer.position.inMilliseconds,
      'current_song_id': _currentSongId,
      'current_song_hash': _currentSongHash,
    };

    _meshNetwork.sendToDevice(message['sender_id'], state);
  }

  // Load a song by ID and hash
  Future<void> _loadSong(String songId, String songHash) async {
    // Implementation depends on how songs are stored
    // This is a placeholder
    try {
      await _audioPlayer.setUrl('file:///path/to/songs/$songId.mp3');
      _currentSongId = songId;
      _currentSongHash = songHash;
    } catch (e) {
      print('Error loading song: $e');
    }
  }

  // Load the current song from playlist
  Future<void> _loadCurrentSong() async {
    if (_currentIndex < 0 || _currentIndex >= _playlist.length) return;

    final song = _playlist[_currentIndex];
    await _loadSong(song['id'], song['hash']);
  }

  // Play from the current position (leader only)
  void play() {
    if (_role != PlaybackRole.leader) return;

    final position = _audioPlayer.position.inMilliseconds;
    final scheduledTime =
        DateTime.now().millisecondsSinceEpoch + _commandBuffer;
    final networkScheduledTime = _timeSync.localToNetworkTime(scheduledTime);

    final command = {
      'command': 'play',
      'scheduled_time': networkScheduledTime,
      'song_id': _currentSongId,
      'song_hash': _currentSongHash,
      'position': position,
    };

    _meshNetwork.sendMessage(MeshNetwork.playbackTopic, command);
    _handlePlayCommand(command);
  }

  // Pause playback (leader only)
  void pause() {
    if (_role != PlaybackRole.leader) return;

    final scheduledTime =
        DateTime.now().millisecondsSinceEpoch + _commandBuffer;
    final networkScheduledTime = _timeSync.localToNetworkTime(scheduledTime);

    final command = {
      'command': 'pause',
      'scheduled_time': networkScheduledTime,
    };

    _meshNetwork.sendMessage(MeshNetwork.playbackTopic, command);
    _handlePauseCommand(command);
  }

  void seekTo(Duration position) {
    if (_role != PlaybackRole.leader) return;

    final scheduledTime =
        DateTime.now().millisecondsSinceEpoch + _commandBuffer;
    final networkScheduledTime = _timeSync.localToNetworkTime(scheduledTime);

    final command = {
      'command': 'seek',
      'scheduled_time': networkScheduledTime,
      'position': position.inMilliseconds,
    };

    _meshNetwork.sendMessage(MeshNetwork.playbackTopic, command);
    _handleSeekCommand(command);
  }

  // Play next song (leader only)
  void playNext() {
    if (_role != PlaybackRole.leader || _playlist.isEmpty) return;

    final nextIndex = (_currentIndex + 1) % _playlist.length;
    _currentIndex = nextIndex;

    final scheduledTime =
        DateTime.now().millisecondsSinceEpoch + _commandBuffer;
    final networkScheduledTime = _timeSync.localToNetworkTime(scheduledTime);

    final command = {
      'command': 'next',
      'scheduled_time': networkScheduledTime,
      'song_index': nextIndex,
    };

    _meshNetwork.sendMessage(MeshNetwork.playbackTopic, command);
    _handleNextCommand(command);
  }

  // Play previous song (leader only)
  void playPrevious() {
    if (_role != PlaybackRole.leader || _playlist.isEmpty) return;

    final prevIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    _currentIndex = prevIndex;

    final scheduledTime =
        DateTime.now().millisecondsSinceEpoch + _commandBuffer;
    final networkScheduledTime = _timeSync.localToNetworkTime(scheduledTime);

    final command = {
      'command': 'previous',
      'scheduled_time': networkScheduledTime,
      'song_index': prevIndex,
    };

    _meshNetwork.sendMessage(MeshNetwork.playbackTopic, command);
    _handlePreviousCommand(command);
  }

  // Update playlist (leader only)
  void updatePlaylist(List<Map<String, dynamic>> playlist) {
    if (_role != PlaybackRole.leader) return;

    _playlist = playlist;

    final command = {'command': 'update_playlist', 'playlist': _playlist};
    _meshNetwork.sendMessage(MeshNetwork.queueTopic, command);
  }

  // Request current playlist (follower)
  void requestPlaylist() {
    if (_role == PlaybackRole.leader) return;

    _meshNetwork.sendMessage(MeshNetwork.queueTopic, {
      'command': 'request_playlist',
      'sender_id': 'this_device_id', // Replace with actual device ID
    });
  }

  // Request current playback state (when joining)
  void requestSyncState() {
    _meshNetwork.sendMessage(MeshNetwork.queueTopic, {
      'command': 'sync_state',
      'sender_id': 'this_device_id', // Replace with actual device ID
    });
  }

  // Calculate song hash (MD5)
  String calculateSongHash(List<int> data) {
    final digest = md5.convert(data);
    return digest.toString();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
