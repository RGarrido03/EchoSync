import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class FileServerService {
  HttpServer? _server;
  final int port;
  String? _deviceIp;
  late Directory _tempDir;
  bool _isRunning = false;

  FileServerService({this.port = 8080});

  Future<void> initialize() async {
    _tempDir = await getTemporaryDirectory();

    // Get device IP
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          _deviceIp = addr.address;
          break;
        }
      }
      if (_deviceIp != null) break;
    }

    debugPrint('Device IP: $_deviceIp');
  }

  Future<bool> startServer() async {
    if (_isRunning) return true;

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _isRunning = true;

      debugPrint('File server started on ${_deviceIp}:$port');

      _server!.listen((HttpRequest request) async {
        await _handleRequest(request);
      });

      return true;
    } catch (e) {
      debugPrint('Failed to start file server: $e');
      return false;
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      if (request.method == 'GET' && request.uri.path.startsWith('/file/')) {
        await _handleFileRequest(request);
      } else if (request.method == 'GET' && request.uri.path == '/health') {
        // Health check endpoint
        request.response
          ..statusCode = HttpStatus.ok
          ..write('Server is running')
          ..close();
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('Not found')
          ..close();
      }
    } catch (e) {
      debugPrint('Error handling request: $e');
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..close();
    }
  }

  Future<void> _handleFileRequest(HttpRequest request) async {
    try {
      final fileHash = request.uri.path.split('/').last;
      final file = File('${_tempDir.path}/$fileHash');

      if (await file.exists()) {
        final bytes = await file.readAsBytes();

        request.response
          ..headers.set('Content-Type', 'audio/mpeg')
          ..headers.set('Content-Length', bytes.length)
          ..headers.set('Accept-Ranges', 'bytes')
          ..add(bytes)
          ..close();

        debugPrint('Served file: $fileHash (${bytes.length} bytes)');
      } else {
        debugPrint('File not found: $fileHash');
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('File not found')
          ..close();
      }
    } catch (e) {
      debugPrint('Error serving file: $e');
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..close();
    }
  }

  String? getFileUrl(String fileHash) {
    if (_deviceIp == null || !_isRunning) return null;
    return 'http://$_deviceIp:$port/file/$fileHash';
  }

  Future<String?> addFileToServer(File sourceFile, String hash) async {
    try {
      final targetFile = File('${_tempDir.path}/$hash');

      if (!await targetFile.exists()) {
        await sourceFile.copy(targetFile.path);
        debugPrint('Copied file to server: ${targetFile.path}');
      }

      return getFileUrl(hash);
    } catch (e) {
      debugPrint('Error adding file to server: $e');
      return null;
    }
  }

  void stopServer() {
    _server?.close();
    _isRunning = false;
    debugPrint('File server stopped');
  }

  void dispose() {
    stopServer();
  }
}
