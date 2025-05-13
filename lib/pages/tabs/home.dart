import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/mesh_network.dart';
import '../../services/playback_controller.dart';
import 'devices.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final meshNetwork = Provider.of<MeshNetwork>(context, listen: false);

    final bool initialized = await meshNetwork.initialize();
    setState(() {
      _isInitialized = initialized;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Initializing Music Mesh...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Music Mesh')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to Music Mesh',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                final playbackController = Provider.of<PlaybackController>(
                  context,
                  listen: false,
                );
                playbackController.setAsLeader();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DevicesTab(),
                  ), // TODO: Change tab
                );
              },
              child: Text('Create New Session'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final playbackController = Provider.of<PlaybackController>(
                  context,
                  listen: false,
                );
                playbackController.setAsFollower();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DevicesTab(isJoining: true),
                  ), // TODO: Change tab
                );
              },
              child: Text('Join Session'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
