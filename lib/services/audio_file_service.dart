import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:metadata_god/metadata_god.dart';

import '../data/song.dart';
import 'cover_file_service.dart';
import 'file_server.dart';

class AudioFileService {
  static Future<List<Song>> pickAudioFiles(FileServerService fileServer) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) {
      debugPrint('No files selected');
      return [];
    }
    return await Future.wait(
      result.files
          .where((f) => f.path != null)
          .map((f) async => (await createSongFromFile(f.path!, fileServer))!),
    );
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

      final extension = filePath.split('.').last.toLowerCase();
      final bytes = await file.readAsBytes();
      final hash = sha256.convert(bytes).toString();
      Metadata tag = await MetadataGod.readMetadata(file: filePath);

      await fileServer.addFileToServer(file, '$hash.$extension');

      if (tag.picture?.data != null) {
        await CoverFileService.saveCoverToFile(hash, tag.picture!.data);
      }

      return Song(
        hash: hash,
        title: tag.title ?? _getFileNameWithoutExtension(filePath),
        artist: tag.artist ?? 'Unknown Artist',
        album: tag.album ?? 'Unknown Album',
        duration: Duration(milliseconds: tag.durationMs?.toInt() ?? 0),
        cover: tag.picture?.data,
        downloadUrl: fileServer.getFileUrl("$hash.$extension"),
        extension: extension,
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
