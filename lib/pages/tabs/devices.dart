// lib/screens/connection_screen.dart
import 'dart:convert';

import 'package:echosync/data/device.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/device_info.dart';
import '../../services/mesh_network.dart';
import '../../services/qr_connection.dart';
import '../player.dart';

class DevicesTab extends StatefulWidget {
  final bool isJoining;

  const DevicesTab({super.key, this.isJoining = false});

  @override
  DevicesTabState createState() => DevicesTabState();
}

class DevicesTabState extends State<DevicesTab> {
  final List<String> _connectedDevices = [];
  bool _isScanning = false;
  Device? _qrData;
  String _connectionStatus = '';

  @override
  void initState() {
    super.initState();
    _generateQrData();
  }

  Future<void> _generateQrData() async {
    final data =
        await Provider.of<DeviceInfoService>(context, listen: false).deviceInfo;
    setState(() => _qrData = data);
  }

  void _handleQrScan(String data) {
    final parsed = Device.fromJson(jsonDecode(data));
    _connectToDevice(parsed);
  }

  Future<void> _connectToDevice(Device device) async {
    final meshNetwork = Provider.of<MeshNetwork>(context, listen: false);
    setState(() => _connectionStatus = 'Connecting to ${device.name}...');

    final success = await meshNetwork.connectViaWiFi(device.ip);

    if (success) {
      setState(() => _connectionStatus = 'Connected to ${device.name}!');
      Navigator.pushReplacementNamed(context, '/player');
    } else {
      setState(() => _connectionStatus = 'Connection failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrService = Provider.of<QRConnectionService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isJoining ? 'Join Session' : 'Create Session'),
      ),
      body: FutureBuilder<Widget>(
        future: qrService.generateQRCode(MediaQuery.of(context).size),
        builder: (BuildContext context, AsyncSnapshot<Widget> qrCode) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  widget.isJoining
                      ? 'Searching for nearby sessions...'
                      : 'Share this code to connect devices',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),

              // QR code display or scanner
              if (!widget.isJoining)
                Expanded(flex: 2, child: Center(child: qrCode.data)),

              if (widget.isJoining && _isScanning)
                Expanded(
                  flex: 2,
                  child: QRConnectionService.buildQrScanner((code) {
                    setState(() {
                      _isScanning = false;
                    });
                    _handleQrScan(code);
                  }),
                ),

              if (widget.isJoining && !_isScanning)
                Expanded(
                  flex: 1,
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isScanning = true;
                        });
                      },
                      child: Text('Scan QR Code'),
                    ),
                  ),
                ),

              // Connected devices list
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Text(
                      'Connected Devices',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Expanded(
                      child:
                          _connectedDevices.isEmpty
                              ? Center(child: Text('No devices connected'))
                              : ListView.builder(
                                itemCount: _connectedDevices.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    leading: Icon(Icons.smartphone),
                                    title: Text(
                                      'Device ${_connectedDevices[index].substring(0, 6)}',
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),

              // Continue button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed:
                      _connectedDevices.isEmpty && widget.isJoining
                          ? null
                          : () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => PlayerScreen()),
                            );
                          },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: Text('Continue to Player'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
