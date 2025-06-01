// lib/pages/tabs/home.dart
import 'package:echosync/providers/time_sync_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/sync_manager_provider.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDeviceInfo(context),
          const SizedBox(height: 20),
          _buildPlaybackControls(context),
          const SizedBox(height: 20),
          _buildQueueSection(context),
        ],
      ),
    );
  }

  Widget _buildDeviceInfo(BuildContext context) {
    final syncManagerProvider = context.watch<SyncManagerProvider>();
    final syncManager = syncManagerProvider.syncManager;
    final timeSyncProvider = context.watch<TimeSyncProvider>();
    final timeSyncService = timeSyncProvider.timeSyncService;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            // Text('Name: ${_currentDevice?.name ?? 'Unknown'}'),
            // Text('IP: ${_currentDevice?.ip ?? 'Unknown'}'),
            // Text('Status: ${_isConnected ? 'Connected' : 'Disconnected'}'),
            Text(
              'Role: ${syncManager?.isLeader == true ? 'Leader' : 'Follower'}',
            ),
            Text('Clock Offset: ${timeSyncService?.clockOffset ?? 0}ms'),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaybackControls(BuildContext context) {
    final syncManagerProvider = context.watch<SyncManagerProvider>();
    final playbackStatus = syncManagerProvider.playbackStatus;
    final syncManager = syncManagerProvider.syncManager;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Playback Controls',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (playbackStatus != null) ...[
              Text('Current Song: ${playbackStatus.currentSong ?? 'None'}'),
              Text('Position: ${playbackStatus.position}ms'),
              Text('Playing: ${playbackStatus.isPlaying}'),
              Text('Volume: ${(playbackStatus.volume * 100).toInt()}%'),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: syncManager?.previousTrack,
                  child: const Icon(Icons.skip_previous),
                ),
                ElevatedButton(
                  onPressed: () {
                    playbackStatus?.isPlaying == true
                        ? syncManager?.pause()
                        : syncManager?.play();
                  },
                  child: Icon(
                    playbackStatus?.isPlaying == true
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                ),
                ElevatedButton(
                  onPressed: syncManager?.nextTrack,
                  child: const Icon(Icons.skip_next),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Seek: '),
                Expanded(
                  child: Slider(
                    value: (playbackStatus?.position ?? 0).toDouble(),
                    min: 0,
                    max: 300000, // 5 minutes
                    onChanged: (value) {
                      syncManager?.seek(value.toInt());
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueSection(BuildContext context) {
    final syncManagerProvider = context.watch<SyncManagerProvider>();
    final queueStatus = syncManagerProvider.queueStatus;
    final syncManager = syncManagerProvider.syncManager;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Queue', style: Theme.of(context).textTheme.titleLarge),
                ElevatedButton(
                  onPressed: () {
                    final songHash =
                        'song_${DateTime.now().millisecondsSinceEpoch}';
                    syncManager?.addToQueue(songHash);
                  },
                  child: const Text('Add Song'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (queueStatus != null) ...[
              Text('Current Index: ${queueStatus.currentIndex}'),
              Text('Songs: ${queueStatus.songs.length}'),
              const SizedBox(height: 8),
              if (queueStatus.songs.isNotEmpty) ...[
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: queueStatus.songs.length,
                    itemBuilder: (context, index) {
                      final isCurrentSong = index == queueStatus.currentIndex;
                      return ListTile(
                        title: Text(queueStatus.songs[index]),
                        leading:
                            isCurrentSong
                                ? const Icon(
                                  Icons.play_arrow,
                                  color: Colors.blue,
                                )
                                : Text('${index + 1}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            // TODO: removeFromQueue method needs to be added to SyncManager
                          },
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                const Text('No songs in queue'),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
