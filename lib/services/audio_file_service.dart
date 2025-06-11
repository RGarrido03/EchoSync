import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:metadata_god/metadata_god.dart';

import '../data/song.dart';
import 'file_server.dart';

class AudioFileService {
  static Future<List<Song>?> pickAudioFiles(
    FileServerService fileServer,
  ) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        List<Song> songs = [];

        for (PlatformFile file in result.files) {
          if (file.path != null) {
            Song? song = await createSongFromFile(file.path!, fileServer);
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

  static Future<Song?> pickSingleAudioFile(FileServerService fileServer) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return await createSongFromFile(result.files.single.path!, fileServer);
      }
    } catch (e) {
      debugPrint('Error picking audio file: $e');
    }
    return null;
  }

  static Future<Song?> createSongFromFile(
    String filePath,
    FileServerService fileServer,
  ) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('File does not exist: $filePath');
        return null;
      }

      final bytes = await file.readAsBytes();
      final hash = sha256.convert(bytes).toString();
      Metadata tag = await MetadataGod.readMetadata(file: filePath);

      await fileServer.addFileToServer(file, hash);

      return Song(
        hash: hash,
        title: tag.title ?? _getFileNameWithoutExtension(filePath),
        artist: tag.artist ?? 'Unknown Artist',
        album: tag.album ?? 'Unknown Album',
        duration: Duration(milliseconds: tag.durationMs?.toInt() ?? 0),
        cover: tag.picture?.data,
        downloadUrl: fileServer.getFileUrl(hash),
      );
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
}
