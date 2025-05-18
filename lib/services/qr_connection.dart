// lib/services/qr_connection.dart
import 'dart:convert';

import 'package:echosync/services/device_info.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRConnectionService {
  final DeviceInfoService _deviceInfoService = DeviceInfoService();

  QRConnectionService();

  Future<Widget> generateQRCode(Size size) async {
    return QrImageView(
      data: jsonEncode((await _deviceInfoService.deviceInfo).toJson()),
      version: QrVersions.auto,
      size: size.width * 0.8,
      backgroundColor: Colors.white,
    );
  }

  static Widget buildQrScanner(Function(String) onScan) {
    return QRView(
      key: GlobalKey(debugLabel: 'QR'),
      onQRViewCreated: (controller) {
        controller.scannedDataStream.listen((data) {
          onScan(data.code ?? '');
        });
      },
      overlay: QrScannerOverlayShape(
        borderColor: Colors.blue,
        borderRadius: 10,
        borderWidth: 5,
        cutOutSize: 300,
      ),
    );
  }
}
