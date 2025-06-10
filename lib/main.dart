// lib/main.dart
import 'package:audio_service/audio_service.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:echosync/components/now_playing_bar.dart';
import 'package:echosync/pages/player.dart';
import 'package:echosync/pages/tabs/devices.dart';
import 'package:echosync/pages/tabs/home.dart';
import 'package:echosync/pages/tabs/library.dart';
import 'package:echosync/services/audio_handler.dart';
import 'package:echosync/services/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:metadata_god/metadata_god.dart';

import 'blocs/mesh_network/mesh_network_bloc.dart';
import 'blocs/sync_manager/sync_manager_bloc.dart';
import 'blocs/time_sync/time_sync_bloc.dart';
import 'data/device.dart';
import 'navigation/nav_item.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MetadataGod.initialize();

  final audioHandler = await AudioService.init(
    builder: () => EchoSyncAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.yourcompany.echosync.channel.audio',
      androidNotificationChannelName: 'EchoSync Audio',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
    ),
  );
  GetIt.instance.registerSingleton<EchoSyncAudioHandler>(audioHandler);

  runApp(const EchoSyncApp());
}

class EchoSyncApp extends StatelessWidget {
  const EchoSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => MeshNetworkBloc()),
        BlocProvider(create: (_) => TimeSyncBloc()),
        BlocProvider(create: (_) => SyncManagerBloc()),
      ],
      child: DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
          return MaterialApp(
            title: 'EchoSync',
            theme: ThemeData(
              iconTheme: const IconThemeData(weight: 600),
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
              bottomSheetTheme: BottomSheetThemeData(showDragHandle: true),
              progressIndicatorTheme: ProgressIndicatorThemeData(
                year2023: false, // ignore: deprecated_member_use
              ),
              sliderTheme: SliderThemeData(
                year2023: false, // ignore: deprecated_member_use
              ),
            ),
            darkTheme: ThemeData(
              iconTheme: const IconThemeData(weight: 600),
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.orange,
                brightness: Brightness.dark,
              ),
              bottomSheetTheme: BottomSheetThemeData(showDragHandle: true),
              progressIndicatorTheme: ProgressIndicatorThemeData(
                year2023: false, // ignore: deprecated_member_use
              ),
              sliderTheme: SliderThemeData(
                year2023: false, // ignore: deprecated_member_use
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

      if (!mounted) return;

      // Initialize mesh network
      context.read<MeshNetworkBloc>().add(
        InitializeMeshNetwork(_currentDevice!),
      );
    } catch (e) {
      debugPrint('Initialization error: $e');
    }
  }

  void show() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Player();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("EchoSync"),
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
      bottomNavigationBar: SingleChildScrollView(
        child: Column(
          children: [
            NowPlayingBar(onTap: show),
            NavigationBar(
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
          ],
        ),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<MeshNetworkBloc, MeshNetworkState>(
            listener: (context, state) {
              if (state is MeshNetworkConnected) {
                // Initialize time sync when mesh network is connected
                context.read<TimeSyncBloc>().add(
                  InitializeTimeSync(state.meshNetwork, _currentDevice!.ip),
                );
              }
            },
          ),
          BlocListener<TimeSyncBloc, TimeSyncState>(
            listener: (context, state) {
              if (state is TimeSyncReady) {
                final meshState = context.read<MeshNetworkBloc>().state;
                if (meshState is MeshNetworkConnected) {
                  // Initialize sync manager when time sync is ready
                  context.read<SyncManagerBloc>().add(
                    InitializeSyncManager(
                      meshNetwork: meshState.meshNetwork,
                      timeSyncService: state.timeSyncService,
                      deviceIp: _currentDevice!.ip,
                    ),
                  );
                }
              }
            },
          ),
        ],
        child: BlocBuilder<SyncManagerBloc, SyncManagerState>(
          builder: (context, state) {
            if (state is SyncManagerReady) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child:
                    const [
                      HomeTab(),
                      LibraryTab(),
                      DevicesTab(),
                    ][currentPageIndex],
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}
