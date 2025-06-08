import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../blocs/sync_manager/sync_manager_bloc.dart';

class Player extends StatelessWidget {
  const Player({super.key});

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
        return Wrap(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: Image.memory(
                      state.playbackState?.currentSong?.cover ?? Uint8List(0),
                      fit: BoxFit.cover,
                      width: MediaQuery.sizeOf(context).width / 2,
                      height: MediaQuery.sizeOf(context).width / 2,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHigh,
                          height: MediaQuery.sizeOf(context).width / 2,
                          width: MediaQuery.sizeOf(context).width / 2,
                          child: Center(
                            child: Icon(
                              Symbols.music_note_rounded,
                              size: 48,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    state.playbackState?.currentSong?.title ?? 'Wasted Love',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    state.playbackState?.currentSong?.artist ?? 'JJ',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    spacing: 16,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Symbols.skip_previous_rounded),
                        onPressed: () {
                          context.read<SyncManagerBloc>().add(PreviousTrack());
                        },
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Symbols.play_arrow_rounded, fill: 1),
                        selectedIcon: const Icon(
                          Symbols.pause_rounded,
                          fill: 1,
                        ),
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        isSelected: state.playbackState?.isPlaying ?? false,
                        onPressed: () {
                          context.read<SyncManagerBloc>().add(
                            state.playbackState!.isPlaying
                                ? PauseMusic()
                                : PlayMusic(
                                  song: state.playbackState?.currentSong,
                                ),
                          );
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(
                            Theme.of(context).colorScheme.primaryContainer,
                          ),
                          fixedSize: WidgetStateProperty.all(
                            const Size(96, 96),
                          ),
                          iconSize: WidgetStateProperty.all(48),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Symbols.skip_next_rounded),
                        onPressed: () {
                          context.read<SyncManagerBloc>().add(NextTrack());
                        },
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Slider(
                    value:
                        state.playbackState?.position.inMilliseconds
                            .toDouble() ??
                        0.0,
                    min: 0,
                    max:
                        state
                            .playbackState
                            ?.currentSong
                            ?.duration
                            .inMilliseconds
                            .toDouble() ??
                        0.0,
                    onChanged: (value) {
                      context.read<SyncManagerBloc>().add(
                        SeekMusic(Duration(milliseconds: value.toInt())),
                      );
                    },
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).viewPadding.bottom + 16,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
