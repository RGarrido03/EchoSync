// lib/screens/connection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/mesh_network.dart';
import '../../services/qr_connection.dart';
import '../player.dart';

class DevicesTab extends StatefulWidget {
  final bool isJoining;

  const DevicesTab({super.key, this.isJoining = false});

  @override
  _DevicesTabState createState() => _DevicesTabState();
}

class _DevicesTabState extends State<DevicesTab> {
  final List<String> _connectedDevices = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _setupNetwork();
  }

  void _setupNetwork() async {
    final meshNetwork = Provider.of<MeshNetwork>(context, listen: false);

    // Listen for connection events
    meshNetwork.connectionStream.listen((event) {
      if (event['type'] == 'connected') {
        setState(() {
          _connectedDevices.add(event['deviceId']);
        });
      } else if (event['type'] == 'disconnected') {
        setState(() {
          _connectedDevices.remove(event['deviceId']);
        });
      }
    });

    if (widget.isJoining) {
      // Start discovering other devices
      await meshNetwork.startDiscovery();
    } else {
      // Start advertising this device
      await meshNetwork.startAdvertising();
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrService = Provider.of<QRConnectionService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isJoining ? 'Join Session' : 'Create Session'),
      ),
      body: Column(
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
            Expanded(
              flex: 2,
              child: Center(
                child: qrService.generateQRCode(
                  'device_id',
                  MediaQuery.of(context).size,
                ),
              ),
            ),

          if (widget.isJoining && _isScanning)
            Expanded(
              flex: 2,
              child: qrService.buildQRScanner((code) {
                setState(() {
                  _isScanning = false;
                });
                qrService.processScannedQR(code);
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
              child: Text('Continue to Player'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
