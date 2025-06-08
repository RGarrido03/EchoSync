// lib/pages/tabs/home.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/sync_manager/sync_manager_bloc.dart';
import '../../blocs/time_sync/time_sync_bloc.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
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
    );
  }

  Widget _buildPlaybackControls(BuildContext context) {
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
            BlocBuilder<SyncManagerBloc, SyncManagerState>(
              builder: (context, state) {
                if (state is! SyncManagerReady) {
                  return const Center(child: CircularProgressIndicator());
                }

                final playbackStatus = state.playbackStatus;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (playbackStatus != null) ...[
                      Text(
                        'Current Song: ${playbackStatus.currentSong?.title ?? 'None'}',
                      ),
                      Text('Position: ${playbackStatus.position}s'),
                      Text('Playing: ${playbackStatus.isPlaying}'),
                      Text('Volume: ${(playbackStatus.volume * 100).toInt()}%'),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            context.read<SyncManagerBloc>().add(
                              PreviousTrack(),
                            );
                          },
                          child: const Icon(Icons.skip_previous),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (playbackStatus?.isPlaying == true) {
                              context.read<SyncManagerBloc>().add(PauseMusic());
                            } else {
                              context.read<SyncManagerBloc>().add(
                                PlayMusic(song: playbackStatus?.currentSong),
                              );
                            }
                          },
                          child: Icon(
                            playbackStatus?.isPlaying == true
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            context.read<SyncManagerBloc>().add(NextTrack());
                          },
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
                            max:
                                state.playbackStatus?.currentSong?.duration
                                    .toDouble() ??
                                180, // 5 minutes
                            onChanged: (value) {
                              context.read<SyncManagerBloc>().add(
                                SeekToPosition(value.toInt()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueSection(BuildContext context) {
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
                    context.read<SyncManagerBloc>().add(
                      PickAndAddSongToQueue(),
                    );
                  },
                  child: const Text('Add Song'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            BlocBuilder<SyncManagerBloc, SyncManagerState>(
              builder: (context, state) {
                if (state is! SyncManagerReady) {
                  return const SizedBox.shrink();
                }

                final queueStatus = state.queueStatus;

                if (queueStatus == null) {
                  return const Text('Queue not loaded');
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Index: ${queueStatus.currentIndex}'),
                    Text('Songs: ${queueStatus.songs.length}'),
                    const SizedBox(height: 8),
                    if (queueStatus.songs.isNotEmpty) ...[
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: queueStatus.songs.length,
                          itemBuilder: (context, index) {
                            final isCurrentSong =
                                index == queueStatus.currentIndex;
                            return ListTile(
                              title: Text(queueStatus.songs[index].title),
                              subtitle: Text(queueStatus.songs[index].artist),
                              onTap: () {
                                context.read<SyncManagerBloc>().add(
                                  PlaySongAtIndex(index),
                                );
                              },
                              leading:
                                  isCurrentSong
                                      ? Icon(
                                        Icons.play_arrow,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      )
                                      : Text('${index + 1}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  // TODO: Add remove from queue event
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
