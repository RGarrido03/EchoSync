// lib/main.dart
import 'package:dynamic_color/dynamic_color.dart';
import 'package:echosync/pages/tabs/devices.dart';
import 'package:echosync/pages/tabs/home.dart';
import 'package:echosync/pages/tabs/library.dart';
import 'package:echosync/providers/mesh_network_provider.dart';
import 'package:echosync/providers/sync_manager_provider.dart';
import 'package:echosync/providers/time_sync_provider.dart';
import 'package:echosync/services/device_info.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'data/device.dart';
import 'navigation/nav_item.dart';

void main() {
  runApp(const EchoSyncApp());
}

class EchoSyncApp extends StatelessWidget {
  const EchoSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MeshNetworkProvider()),
        ChangeNotifierProvider(create: (_) => TimeSyncProvider()),
        ChangeNotifierProvider(create: (_) => SyncManagerProvider()),
      ],
      child: DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
          return MaterialApp(
            title: 'EchoSync',
            theme: ThemeData(
              iconTheme: const IconThemeData(weight: 600),
              colorScheme:
                  lightDynamic ??
                  ColorScheme.fromSeed(seedColor: Colors.orange),
            ),
            darkTheme: ThemeData(
              iconTheme: const IconThemeData(weight: 600),
              colorScheme:
                  darkDynamic ??
                  ColorScheme.fromSeed(
                    seedColor: Colors.orange,
                    brightness: Brightness.dark,
                  ),
            ),
            home: const EchoSyncHomePage(),
          );
        },
      ),
    );
  }
}

class EchoSyncHomePage extends StatefulWidget {
  const EchoSyncHomePage({super.key});

  @override
  State<EchoSyncHomePage> createState() => _EchoSyncHomePageState();
}

class _EchoSyncHomePageState extends State<EchoSyncHomePage> {
  late DeviceInfoService _deviceInfoService;
  Device? _currentDevice;
  bool _isInitialized = false;
  int currentPageIndex = 0;

  List<NavItem> navItems = [
    NavItem(label: 'Home', icon: Symbols.home_rounded),
    NavItem(label: 'Library', icon: Symbols.library_music_rounded),
    NavItem(label: 'Devices', icon: Symbols.phone_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _deviceInfoService = DeviceInfoService();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      _currentDevice = await _deviceInfoService.deviceInfo;

      final meshProvider = context.read<MeshNetworkProvider>();
      await meshProvider.initialize(_currentDevice!);

      final timeSyncProvider = context.read<TimeSyncProvider>();
      timeSyncProvider.initialize(
        meshProvider.meshNetwork!,
        _currentDevice!.ip,
      );

      final syncManagerProvider = context.read<SyncManagerProvider>();
      syncManagerProvider.initialize(
        meshProvider.meshNetwork!,
        timeSyncProvider.timeSyncService!,
        _currentDevice!.ip,
      );

      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Initialization error: $e');
    }
  }

  @override
  void dispose() {
    context.read<SyncManagerProvider>().disposeManager();
    context.read<TimeSyncProvider>().disposeService();
    context.read<MeshNetworkProvider>().disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syncManagerProvider = context.watch<SyncManagerProvider>();
    final syncManager = syncManagerProvider.syncManager;

    return Scaffold(
      appBar: AppBar(
        title: const Text("EchoSync"),
        actions: [
          if (_isInitialized)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'leader':
                    syncManager?.setAsLeader();
                    setState(() {});
                    break;
                  case 'follower':
                    syncManager?.setAsFollower();
                    setState(() {});
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
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        selectedIndex: currentPageIndex,
        destinations:
            navItems
                .map(
                  (item) => NavigationDestination(
                    selectedIcon: Icon(item.icon, fill: 1),
                    icon: Icon(item.icon),
                    label: item.label,
                  ),
                )
                .toList(),
      ),
      body:
          _isInitialized
              ? Padding(
                padding: EdgeInsets.only(top: 8),
                child:
                    const <Widget>[
                      HomeTab(),
                      LibraryTab(),
                      DevicesTab(),
                    ][currentPageIndex],
              )
              : const Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Player',
        child: const Icon(Symbols.play_arrow_rounded),
      ),
    );
  }
}
