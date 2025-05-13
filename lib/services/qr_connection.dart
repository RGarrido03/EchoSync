// lib/services/qr_connection.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'mesh_network.dart';

class QRConnectionService {
  final MeshNetwork _meshNetwork;

  QRConnectionService({required MeshNetwork meshNetwork})
    : _meshNetwork = meshNetwork;

  // Generate QR code for this device
  Widget generateQRCode(String deviceId, Size size) {
    final Map<String, dynamic> data = {
      'device_id': deviceId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final String qrData = json.encode(data);

    return QrImageView(
      data: qrData,
      version: QrVersions.auto,
      size: size.width * 0.8,
      backgroundColor: Colors.white,
    );
  }

  // Process scanned QR code
  Future<bool> processScannedQR(String scannedData) async {
    try {
      final Map<String, dynamic> data = json.decode(scannedData);

      if (data.containsKey('device_id')) {
        final String deviceId = data['device_id'];

        // Use the device ID to establish connection through Nearby
        // This is a placeholder for the actual connection logic
        // You would use this ID to initiate a connection with the specific device

        return true;
      }
      return false;
    } catch (e) {
      print('Error processing QR code: $e');
      return false;
    }
  }

  // QR Scanner Widget
  Widget buildQRScanner(Function(String) onScan) {
    return QRView(
      key: GlobalKey(debugLabel: 'QR'),
      onQRViewCreated: (QRViewController controller) {
        controller.scannedDataStream.listen((scanData) {
          if (scanData.code != null) {
            onScan(scanData.code!);
            controller.dispose();
          }
        });
      },
    );
  }
}
