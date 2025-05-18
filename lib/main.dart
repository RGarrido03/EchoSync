import 'package:dynamic_color/dynamic_color.dart';
import 'package:echosync/pages/tabs/devices.dart';
import 'package:echosync/pages/tabs/home.dart';
import 'package:echosync/pages/tabs/library.dart';
import 'package:echosync/services/mesh_network.dart';
import 'package:echosync/services/playback_controller.dart';
import 'package:echosync/services/qr_connection.dart';
import 'package:echosync/services/sensor_controls.dart';
import 'package:echosync/services/time_sync.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'navigation/nav_item.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(
          create: (_) => MeshNetwork(),
          dispose: (_, meshNetwork) => meshNetwork.disconnect(),
        ),
        ProxyProvider<MeshNetwork, TimeSyncService>(
          update:
              (_, meshNetwork, __) =>
                  TimeSyncService(sendMessage: meshNetwork.broadcast),
          dispose: (_, timeSync) => timeSync.dispose(),
        ),
        ProxyProvider2<MeshNetwork, TimeSyncService, PlaybackController>(
          update:
              (_, meshNetwork, timeSync, __) => PlaybackController(
                meshNetwork: meshNetwork,
                timeSync: timeSync,
              ),
          dispose: (_, controller) => controller.dispose(),
        ),
        ProxyProvider<PlaybackController, SensorControls>(
          update:
              (_, playbackController, __) =>
                  SensorControls(playbackController: playbackController)
                    ..initialize(),
          dispose: (_, sensorControls) => sensorControls.dispose(),
        ),
        ProxyProvider<MeshNetwork, QRConnectionService>(
          update: (_, meshNetwork, __) => QRConnectionService(),
        ),
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
            home: const MyHomePage(),
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int currentPageIndex = 0;

  List<NavItem> navItems = [
    NavItem(label: 'Home', icon: Symbols.home_rounded),
    NavItem(label: 'Library', icon: Symbols.library_music_rounded),
    NavItem(label: 'Devices', icon: Symbols.phone_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("EchoSync")),
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
      body: Padding(
        padding: EdgeInsets.only(top: 8),
        child:
            const <Widget>[
              HomeTab(),
              LibraryTab(),
              DevicesTab(),
            ][currentPageIndex],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Player',
        child: const Icon(Symbols.play_arrow_rounded),
      ),
    );
  }
}
