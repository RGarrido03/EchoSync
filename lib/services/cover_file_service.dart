import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class CoverFileService {
  static late Directory _coversDir;
  static bool _initialized = false;

  /// Initialize the covers directory
  static Future<void> _ensureInitialized() async {
    if (_initialized) return;

    final tempDir = await getTemporaryDirectory();
    _coversDir = Directory('${tempDir.path}/covers');

    if (!await _coversDir.exists()) {
      await _coversDir.create(recursive: true);
      debugPrint('Created covers directory: ${_coversDir.path}');
    }

    _initialized = true;
  }

  /// Save cover bytes to a file using the song's hash as filename
  /// Returns the file path if successful, null otherwise
  static Future<String?> saveCoverToFile(
    String songHash,
    Uint8List coverBytes,
  ) async {
    try {
      await _ensureInitialized();

      // Generate filename using song hash and appropriate extension
      final coverHash = sha256.convert(coverBytes).toString();
      final fileName =
          '${songHash}_$coverHash.jpg'; // Use jpg as default extension
      final file = File('${_coversDir.path}/$fileName');

      // Only write if file doesn't exist
      if (!await file.exists()) {
        await file.writeAsBytes(coverBytes);
        debugPrint('Saved cover to file: ${file.path}');
      }

      return file.path;
    } catch (e) {
      debugPrint('Error saving cover to file: $e');
      return null;
    }
  }

  /// Get the local file path for a cover if it exists
  /// Returns the file path if it exists, null otherwise
  static Future<String?> getCoverFilePath(String songHash) async {
    try {
      await _ensureInitialized();

      // Look for any cover file that starts with the song hash
      final files = await _coversDir.list().toList();
      for (final entity in files) {
        if (entity is File && entity.path.contains('${songHash}_')) {
          if (await entity.exists()) {
            return entity.path;
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error getting cover file path: $e');
      return null;
    }
  }

  /// Load cover bytes from file using the song's hash
  /// Returns the cover bytes if found, null otherwise
  static Future<Uint8List?> loadCoverFromFile(String songHash) async {
    try {
      final filePath = await getCoverFilePath(songHash);
      if (filePath != null) {
        final file = File(filePath);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error loading cover from file: $e');
      return null;
    }
  }

  /// Clean up old/unused cover files
  static Future<void> cleanupCoverFiles(Set<String> activeSongHashes) async {
    try {
      await _ensureInitialized();

      final files = await _coversDir.list().toList();
      for (final entity in files) {
        if (entity is File) {
          final fileName = entity.path.split('/').last;
          final songHash = fileName.split('_').first;

          if (!activeSongHashes.contains(songHash)) {
            await entity.delete();
            debugPrint('Cleaned up unused cover file: ${entity.path}');
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up cover files: $e');
    }
  }

  /// Get the covers directory path (for debugging/testing)
  static Future<String> getCoversDirectoryPath() async {
    await _ensureInitialized();
    return _coversDir.path;
  }
}
