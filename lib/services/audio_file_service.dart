// lib/services/audio_file_service.dart
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:metadata_god/metadata_god.dart';

import '../data/song.dart';
import 'audio_handler.dart';

class AudioFileService {
  static Future<List<Song>?> pickAudioFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        List<Song> songs = [];

        for (PlatformFile file in result.files) {
          if (file.path != null) {
            Song? song = await _createSongFromFile(file.path!);
            if (song != null) {
              songs.add(song);
            }
          }
        }

        return songs.isNotEmpty ? songs : null;
      }
    } catch (e) {
      debugPrint('Error picking audio files: $e');
    }
    return null;
  }

  static Future<Song?> pickSingleAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return await _createSongFromFile(result.files.single.path!);
      }
    } catch (e) {
      debugPrint('Error picking audio file: $e');
    }
    return null;
  }

  static Future<Song?> _createSongFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('File does not exist: $filePath');
        return null;
      }

      final bytes = await file.readAsBytes();
      final hash = sha256.convert(bytes).toString();
      Metadata tag = await MetadataGod.readMetadata(file: filePath);

      final song = Song(
        hash: hash,
        title: tag.title ?? _getFileNameWithoutExtension(filePath),
        artist: tag.artist ?? 'Unknown Artist',
        album: tag.album ?? 'Unknown Album',
        duration: Duration(milliseconds: tag.durationMs?.toInt() ?? 0),
        cover: tag.picture?.data,
        bytes: bytes,
      );

      // Register the song path with the audio handler
      final audioHandler = GetIt.instance<EchoSyncAudioHandler>();
      audioHandler.registerSongPath(hash, filePath);

      return song;
    } catch (e) {
      debugPrint('Error creating song from file: $e');
      return null;
    }
  }

  static String _getFileNameWithoutExtension(String filePath) {
    final fileName = filePath.split('/').last;
    final lastDotIndex = fileName.lastIndexOf('.');
    return lastDotIndex != -1 ? fileName.substring(0, lastDotIndex) : fileName;
  }

  static Future<Song?> createSongFromPath(String filePath) async {
    return await _createSongFromFile(filePath);
  }
}
