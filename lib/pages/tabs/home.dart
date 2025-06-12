import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../blocs/sync_manager/sync_manager_bloc.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Queue")),
      body: BlocBuilder<SyncManagerBloc, SyncManagerState>(
        builder: (context, state) {
          if (state is! SyncManagerReady) {
            return const SizedBox.shrink();
          }

          final queueState = state.queueState;

          if (queueState == null) {
            return const Text('Queue not loaded');
          }

          return queueState.songs.isNotEmpty
              ? ListView.builder(
                itemCount: queueState.songs.length,
                itemBuilder: (context, index) {
                  final isCurrentSong = index == queueState.currentIndex;
                  return ListTile(
                    title: Text(
                      queueState.songs[index].title,
                      style:
                          isCurrentSong
                              ? Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)
                              : null,
                    ),
                    subtitle: Text(queueState.songs[index].artist),
                    onTap: () {
                      context.read<SyncManagerBloc>().add(PlayAtIndex(index));
                    },
                    leading: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: Center(
                          child:
                              isCurrentSong
                                  ? Icon(
                                    Symbols.play_arrow_rounded,
                                    fill: 1,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  )
                                  : Text(
                                    (index + 1).toString(),
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                        ),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Symbols.delete_rounded),
                      onPressed: () {
                        // TODO: Add remove from queue event
                      },
                    ),
                  );
                },
              )
              : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Symbols.queue_music_rounded,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No songs in queue',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add songs to your queue to get started.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
        },
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
