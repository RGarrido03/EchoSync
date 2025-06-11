// lib/pages/tabs/devices.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../blocs/mesh_network/mesh_network_bloc.dart';
import '../../blocs/sync_manager/sync_manager_bloc.dart';
import '../../blocs/time_sync/time_sync_bloc.dart';
import '../../data/device.dart';

class DevicesTab extends StatelessWidget {
  const DevicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Devices"),
        actions: [
          BlocBuilder<SyncManagerBloc, SyncManagerState>(
            builder: (context, state) {
              if (state is SyncManagerReady) {
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'leader':
                        context.read<TimeSyncBloc>().add(SetAsTimeSyncLeader());
                        break;
                      case 'follower':
                        context.read<TimeSyncBloc>().add(
                          SetAsTimeSyncFollower(),
                        );
                        break;
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'leader',
                          child: Text('Become Leader'),
                        ),
                        const PopupMenuItem(
                          value: 'follower',
                          child: Text('Become Follower'),
                        ),
                      ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<MeshNetworkBloc, MeshNetworkState>(
        builder: (context, state) {
          final connectedDevices = <String, Device>{};

          if (state is MeshNetworkConnected) {
            connectedDevices.addAll(state.connectedDevices);
          }

          if (state is MeshNetworkError) {
            return Text(
              'Error: ${state.error}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card.filled(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time Sync Status',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        BlocBuilder<TimeSyncBloc, TimeSyncState>(
                          builder: (context, timeState) {
                            String role = 'Unknown';
                            int clockOffset = 0;

                            if (timeState is TimeSyncReady) {
                              role = timeState.isLeader ? 'Leader' : 'Follower';
                              clockOffset = timeState.clockOffset;
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Role: $role'),
                                Text('Clock Offset: ${clockOffset}ms'),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Card.filled(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16.0, 0.0, 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Connected devices',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        const SizedBox(height: 8),
                        connectedDevices.isNotEmpty
                            ? ListView.builder(
                              shrinkWrap: true,
                              itemCount: connectedDevices.length,
                              itemBuilder: (context, index) {
                                final device = connectedDevices.values
                                    .elementAt(index);
                                return ListTile(
                                  title: Text(device.name),
                                  subtitle: Text(device.ip),
                                  leading: const Icon(
                                    Symbols.smartphone_rounded,
                                  ),
                                );
                              },
                            )
                            : const Text('No current devices connected'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  "You're known as: ${context.read<MeshNetworkBloc>().meshNetwork?.device.name ?? 'Unknown'}",
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                Text(
                  context.read<MeshNetworkBloc>().meshNetwork?.device.ip ??
                      'Unknown IP',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Add device',
        child: const Icon(Symbols.mobile_loupe_rounded),
      ),
    );
  }
}
