// lib/pages/player.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/playback_controller.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playbackController = Provider.of<PlaybackController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Music Player'),
        actions: [
          IconButton(
            icon: Icon(Icons.playlist_play),
            onPressed: () {
              _showPlaylistDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Album art and song info
          Expanded(
            flex: 3,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.music_note,
                      size: 120,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 40),
                  Text(
                    playbackController.currentIndex >= 0 &&
                            playbackController.playlist.isNotEmpty
                        ? playbackController.playlist[playbackController
                                .currentIndex]['title'] ??
                            'Unknown Song'
                        : 'No Song Selected',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(
                    playbackController.currentIndex >= 0 &&
                            playbackController.playlist.isNotEmpty
                        ? playbackController.playlist[playbackController
                                .currentIndex]['artist'] ??
                            'Unknown Artist'
                        : 'Select a song from the playlist',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),

          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: StreamBuilder<Duration>(
              stream: playbackController.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = playbackController.duration ?? Duration.zero;

                return Column(
                  children: [
                    Slider(
                      value: position.inMilliseconds.toDouble(),
                      max: duration.inMilliseconds.toDouble(),
                      onChanged:
                          playbackController.role == PlaybackRole.leader
                              ? (value) {
                                playbackController.seekTo(
                                  Duration(milliseconds: value.toInt()),
                                );
                              }
                              : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(position)),
                          Text(_formatDuration(duration)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Playback controls
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.skip_previous),
                  iconSize: 36,
                  onPressed:
                      playbackController.role == PlaybackRole.leader
                          ? () => playbackController.playPrevious()
                          : null,
                ),
                SizedBox(width: 16),
                IconButton(
                  icon: Icon(
                    playbackController.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                  ),
                  iconSize: 64,
                  onPressed:
                      playbackController.role == PlaybackRole.leader
                          ? () {
                            if (playbackController.isPlaying) {
                              playbackController.pause();
                            } else {
                              playbackController.play();
                            }
                          }
                          : null,
                ),
                SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.skip_next),
                  iconSize: 36,
                  onPressed:
                      playbackController.role == PlaybackRole.leader
                          ? () => playbackController.playNext()
                          : null,
                ),
              ],
            ),
          ),

          // Connected devices indicator
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.speaker_group, color: Colors.green),
                SizedBox(width: 8),
                Text('3 connected devices'), // Replace with actual count
                SizedBox(width: 16),
                Text(
                  playbackController.role == PlaybackRole.leader
                      ? 'Leader'
                      : 'Follower',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        playbackController.role == PlaybackRole.leader
                            ? Colors.deepPurple
                            : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPlaylistDialog(BuildContext context) {
    final playbackController = Provider.of<PlaybackController>(
      context,
      listen: false,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          builder: (context, scrollController) {
            return Consumer<PlaybackController>(
              builder: (context, controller, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Playlist',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (controller.role == PlaybackRole.leader)
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () {
                                // Add song to playlist
                              },
                            ),
                        ],
                      ),
                    ),
                    Divider(),
                    Expanded(
                      child:
                          controller.playlist.isEmpty
                              ? Center(child: Text('No songs in playlist'))
                              : ListView.builder(
                                controller: scrollController,
                                itemCount: controller.playlist.length,
                                itemBuilder: (context, index) {
                                  final song = controller.playlist[index];
                                  final bool isPlaying =
                                      index == controller.currentIndex;

                                  return ListTile(
                                    leading:
                                        isPlaying
                                            ? Icon(
                                              Icons.play_circle_filled,
                                              color: Colors.deepPurple,
                                            )
                                            : Icon(Icons.music_note),
                                    title: Text(
                                      song['title'] ?? 'Unknown Song',
                                      style: TextStyle(
                                        fontWeight:
                                            isPlaying
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                    ),
                                    subtitle: Text(
                                      song['artist'] ?? 'Unknown Artist',
                                    ),
                                    onTap:
                                        controller.role == PlaybackRole.leader
                                            ? () {
                                              // Play this song
                                            }
                                            : null,
                                  );
                                },
                              ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
