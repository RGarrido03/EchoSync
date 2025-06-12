// lib/pages/add_device_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../blocs/mesh_network/mesh_network_bloc.dart';
import '../blocs/time_sync/time_sync_bloc.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {

  late MeshNetworkBloc _meshNetworkBloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Salvar referência ao BLoC
    _meshNetworkBloc = context.read<MeshNetworkBloc>();
  }

  @override
  void initState() {
    super.initState();
    // Get leader status from TimeSyncBloc and start discovery
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timeSyncState = context.read<TimeSyncBloc>().state;
      final isLeader = timeSyncState is TimeSyncReady ? timeSyncState.isLeader : false;

      debugPrint('AddDeviceScreen: Starting discovery, isLeader: $isLeader');

      _meshNetworkBloc.add(
        StartDeviceDiscovery(isLeader: isLeader),
      );
    });
  }

  @override
  void dispose() {
    // Usar a referência salva em vez de context.read()
    _meshNetworkBloc.add(StopDeviceDiscovery());
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Device'),
        actions: [
          BlocBuilder<TimeSyncBloc, TimeSyncState>(
            builder: (context, state) {
              if (state is TimeSyncReady) {
                return Chip(
                  label: Text(state.isLeader ? 'Leader' : 'Follower'),
                  backgroundColor:
                      state.isLeader
                          ? Colors.green.withOpacity(0.2)
                          : Colors.blue.withOpacity(0.2),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              final bloc = context.read<MeshNetworkBloc>();
              debugPrint('DEBUG: Current state: ${bloc.state}');
              debugPrint('DEBUG: Discovered devices: ${bloc.discoveredDevices}');
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: BlocBuilder<MeshNetworkBloc, MeshNetworkState>(
        builder: (context, state) {
          if (state is MeshNetworkDiscovering) {
            return _buildDiscoveringView(state);
          } else if (state is MeshNetworkError) {
            return _buildErrorView(state);
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildDiscoveringView(MeshNetworkDiscovering state) {
    final timeSyncState = context.read<TimeSyncBloc>().state;
    final isLeader =
        timeSyncState is TimeSyncReady ? timeSyncState.isLeader : false;

    return Padding(
      padding: const EdgeInsets.all(16.0),
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
                  Row(
                    children: [
                      Icon(
                        isLeader ? Symbols.wifi_tethering : Symbols.wifi_find,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isLeader ? 'Advertising' : 'Discovering',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLeader
                        ? 'Other devices can discover and connect to you'
                        : 'Searching for nearby devices...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Discovered Devices',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Expanded(
            child:
                state.discoveredDevices.isEmpty
                    ? _buildEmptyState(isLeader)
                    : _buildDevicesList(state.discoveredDevices),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isLeader) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isLeader ? Symbols.broadcast_on_personal : Symbols.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            isLeader ? 'Waiting for devices to connect...' : 'No devices found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isLeader
                ? 'Make sure other devices are in discovery mode'
                : 'Make sure nearby devices are advertising',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesList(Map<String, String> devices) {
    return ListView.builder(
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final deviceId = devices.keys.elementAt(index);
        final deviceName = devices.values.elementAt(index);

        return Card(
          child: ListTile(
            leading: const Icon(Symbols.smartphone),
            title: Text(deviceName),
            subtitle: Text(deviceId),
            trailing: ElevatedButton(
              onPressed: () {
                context.read<MeshNetworkBloc>().add(
                  ConnectToDiscoveredDevice(deviceId),
                );
              },
              child: const Text('Connect'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectingView(MeshNetworkDeviceConnecting state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Connecting to device...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            state.deviceId,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(MeshNetworkError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.error,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Discovery Error',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<MeshNetworkBloc>().add(
                  StartDeviceDiscovery(
                    isLeader:
                        context.read<TimeSyncBloc>().state is TimeSyncReady
                            ? (context.read<TimeSyncBloc>().state
                                    as TimeSyncReady)
                                .isLeader
                            : false,
                  ),
                );
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
