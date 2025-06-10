import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../blocs/sync_manager/sync_manager_bloc.dart';
import 'image.dart';

class NowPlayingBar extends StatelessWidget {
  final Function()? onTap;

  const NowPlayingBar({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncManagerBloc, SyncManagerState>(
      builder: (context, state) {
        if (state is SyncManagerInitial) {
          return Center(child: CircularProgressIndicator());
        }
        if (state is SyncManagerError) {
          return Center(
            child: Text(
              'Error: ${state.error}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          );
        }
        if (state is SyncManagerInitializing) {
          return Center(child: CircularProgressIndicator());
        }
        if (state is! SyncManagerReady) {
          return Center(
            child: Text(
              'Sync Manager is not ready',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
          ),
          tileColor: Theme.of(context).colorScheme.surfaceContainer,
          leading: BytesImage(bytes: state.playbackState?.currentSong?.cover),
          trailing: IconButton(
            icon: const Icon(Symbols.play_arrow_rounded, fill: 1),
            selectedIcon: const Icon(Symbols.pause_rounded, fill: 1),
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            isSelected: state.playbackState?.isPlaying ?? false,
            onPressed: () {
              context.read<SyncManagerBloc>().add(
                state.playbackState!.isPlaying
                    ? PauseMusic()
                    : PlayMusic(song: state.playbackState?.currentSong),
              );
            },
          ),
          onTap: onTap,
          title: Text(
            state.playbackState?.currentSong?.title ?? 'No song playing',
          ),
          subtitle: Text(
            state.playbackState?.currentSong?.artist ??
                'Play a song to show here',
          ),
        );
      },
    );
  }
}
