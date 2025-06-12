// lib/services/audio_handler.dart
import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:volume_controller/volume_controller.dart';

import '../data/song.dart';

class EchoSyncAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  // Callback to notify sync manager of local changes
  Function(String command, Map<String, dynamic>? params)? onLocalControl;

  EchoSyncAudioHandler() {
    _init();
  }

  Stream<Duration> get positionStream => _player.positionStream;

  void _init() {
    // Listen to player state changes and broadcast them
    _player.playbackEventStream.listen(_broadcastState);

    // Listen to player position changes
    _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(updatePosition: position));
    });

    // Handle player completion
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handleTrackCompletion();
      }
    });
  }

  // Convert Song to MediaItem
  Future<MediaItem> _songToMediaItem(Song song) async {
    return MediaItem(
      id: song.hash,
      album: song.album,
      title: song.title,
      artist: song.artist,
      duration: song.duration,
      artUri: await song.getCoverArtUri(),
    );
  }

  Future<void> executeSyncedPlay({
    Song? song,
    Duration? position,
    DateTime? scheduledTime,
  }) async {
    if (song != null) {
      final Directory tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${song.hash}.${song.extension}');

      if (!await file.exists()) {
        throw Exception('Audio file does not exist: ${file.path}');
      }

      await _player.setAudioSource(AudioSource.file(file.path));
      mediaItem.add(await _songToMediaItem(song));
    }

    if (position != null) {
      await _player.seek(position);
    }

    if (scheduledTime != null) {
      final now = DateTime.now();
      final delay = scheduledTime.difference(now);

      if (delay.inMilliseconds > 0) {
        await Future.delayed(delay);
      }
    }

    await _player.play();
  }

  Future<void> executeSyncedPause({DateTime? scheduledTime}) async {
    try {
      if (scheduledTime != null) {
        final now = DateTime.now();
        final delay = scheduledTime.difference(now);

        if (delay.inMilliseconds > 0) {
          await Future.delayed(delay);
        }
      }

      await _player.pause();
    } catch (e) {
      debugPrint('Error in executeSyncedPause: $e');
    }
  }

  Future<void> executeSyncedSeek({
    required Duration position,
    DateTime? scheduledTime,
  }) async {
    try {
      if (scheduledTime != null) {
        final now = DateTime.now();
        final delay = scheduledTime.difference(now);

        if (delay.inMilliseconds > 0) {
          await Future.delayed(delay);
        }
      }

      debugPrint('Seeking to position: $position');
      await _player.seek(position);
    } catch (e) {
      debugPrint('Error in executeSyncedSeek: $e');
    }
  }

  // Synchronized volume control
  Future<void> executeSyncedSetVolume({
    required double volume,
    DateTime? scheduledTime,
  }) async {
    try {
      debugPrint('Synced set volume: $volume');
      if (scheduledTime != null) {
        final now = DateTime.now();
        final delay = scheduledTime.difference(now);

        if (delay.inMilliseconds > 0) {
          await Future.delayed(delay);
        }
      }

      await VolumeController.instance.setVolume(volume);
    } catch (e) {
      debugPrint('Error in executeSyncedSetVolume: $e');
    }
  }

  // Update queue from sync manager
  Future<void> updateQueueFromSync(List<Song> songs, int currentIndex) async {
    final mediaItems = await Future.wait(songs.map(_songToMediaItem));
    queue.add(mediaItems);

    if (currentIndex >= 0 && currentIndex < mediaItems.length) {
      mediaItem.add(mediaItems[currentIndex]);
    }
  }

  // Standard AudioHandler overrides for local control
  @override
  Future<void> play() async {
    onLocalControl?.call('play', null);
  }

  @override
  Future<void> pause() async {
    onLocalControl?.call('pause', null);
  }

  @override
  Future<void> seek(Duration position) async {
    onLocalControl?.call('seek', {'position': position.inMilliseconds});
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    onLocalControl?.call('stop', null);
  }

  @override
  Future<void> skipToNext() async {
    onLocalControl?.call('next', null);
  }

  @override
  Future<void> skipToPrevious() async {
    onLocalControl?.call('previous', null);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    onLocalControl?.call('play_at_index', {'index': index});
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    // Convert MediaItem back to Song if needed for sync
    onLocalControl?.call('add_to_queue', {
      'song': {
        'hash': mediaItem.id,
        'title': mediaItem.title,
        'artist': mediaItem.artist,
        'album': mediaItem.album,
        'duration': mediaItem.duration?.inSeconds ?? 0,
      },
    });
  }

  void _broadcastState(PlaybackEvent event) {
    final isPlaying = _player.playing;
    final processingState = _player.processingState;
    final position = _player.position;

    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (isPlaying) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState:
            const {
              ProcessingState.idle: AudioProcessingState.idle,
              ProcessingState.loading: AudioProcessingState.loading,
              ProcessingState.buffering: AudioProcessingState.buffering,
              ProcessingState.ready: AudioProcessingState.ready,
              ProcessingState.completed: AudioProcessingState.completed,
            }[processingState]!,
        playing: isPlaying,
        updatePosition: position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: 0, // Update based on current queue position
      ),
    );
  }

  void _handleTrackCompletion() {
    onLocalControl?.call('next', null);
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
