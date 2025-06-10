import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../blocs/sync_manager/sync_manager_bloc.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Queue',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                BlocBuilder<SyncManagerBloc, SyncManagerState>(
                  builder: (context, state) {
                    if (state is! SyncManagerReady) {
                      return const SizedBox.shrink();
                    }

                    final queueState = state.queueState;

                    if (queueState == null) {
                      return const Text('Queue not loaded');
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Index: ${queueState.currentIndex}'),
                        Text('Songs: ${queueState.songs.length}'),
                        const SizedBox(height: 8),
                        if (queueState.songs.isNotEmpty) ...[
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              itemCount: queueState.songs.length,
                              itemBuilder: (context, index) {
                                final isCurrentSong =
                                    index == queueState.currentIndex;
                                return ListTile(
                                  title: Text(queueState.songs[index].title),
                                  subtitle: Text(
                                    queueState.songs[index].artist,
                                  ),
                                  onTap: () {
                                    context.read<SyncManagerBloc>().add(
                                      PlayAtIndex(index),
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
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<SyncManagerBloc>().add(PickAndAddSongToQueue());
        },
        tooltip: 'Add song',
        child: const Icon(Symbols.music_note_add_rounded),
      ),
    );
  }
}
