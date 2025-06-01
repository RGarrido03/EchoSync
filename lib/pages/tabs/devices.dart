// lib/pages/tabs/devices.dart
import 'package:echosync/providers/mesh_network_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DevicesTab extends StatelessWidget {
  const DevicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final meshNetworkProvider = context.watch<MeshNetworkProvider>();
    final connectedDevices =
        meshNetworkProvider.meshNetwork?.connectedDevices ?? {};

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connected Devices (${connectedDevices.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (connectedDevices.isNotEmpty) ...[
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        itemCount: connectedDevices.length,
                        itemBuilder: (context, index) {
                          final device = connectedDevices.values.elementAt(
                            index,
                          );
                          return ListTile(
                            title: Text(device.name),
                            subtitle: Text(device.ip),
                            leading: const Icon(Icons.devices),
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    const Text('No other devices connected'),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
