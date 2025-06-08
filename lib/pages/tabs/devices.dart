// lib/pages/tabs/devices.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/mesh_network/mesh_network_bloc.dart';
import '../../data/device.dart';

class DevicesTab extends StatelessWidget {
  const DevicesTab({super.key});

  @override
  Widget build(BuildContext context) {
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
                  BlocBuilder<MeshNetworkBloc, MeshNetworkState>(
                    builder: (context, state) {
                      final connectedDevices = <String, Device>{};

                      if (state is MeshNetworkConnected) {
                        debugPrint(
                          "Connected devices: ${state.connectedDevices}",
                        );
                        connectedDevices.addAll(state.connectedDevices);
                      }

                      return Column(
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
                                  final device = connectedDevices.values
                                      .elementAt(index);
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
                          if (state is MeshNetworkError) ...[
                            Text(
                              'Error: ${state.error}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
