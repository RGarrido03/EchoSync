// lib/services/file_download_service.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FileDownloadService {
  static Future<bool> downloadFile(String url, String savePath) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Download error: $e');
      return false;
    }
  }

  static Future<bool> downloadFileWithProgress(
    String url,
    String savePath,
    Function(int received, int total)? onProgress,
  ) async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode == 200) {
        final file = File(savePath);
        final sink = file.openWrite();
        int received = 0;
        final total = response.contentLength;

        await response.listen((chunk) {
          sink.add(chunk);
          received += chunk.length;
          onProgress?.call(received, total);
        }).asFuture();

        await sink.close();
        client.close();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Download error: $e');
      return false;
    }
  }
}
