import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class BytesImage extends StatelessWidget {
  final Uint8List? bytes;
  final double size;
  final Color? backgroundColor;
  final Color? fallbackColor;

  BytesImage({
    super.key,
    required this.bytes,
    this.size = 48,
    this.backgroundColor,
    this.fallbackColor,
  }) {
    if (size < 0) {
      throw ArgumentError('Size must be non-negative');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 8),
      child: Image.memory(
        bytes ?? Uint8List(0),
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color:
                backgroundColor ??
                Theme.of(context).colorScheme.surfaceContainerLow,
            height: size,
            width: size,
            child: Center(
              child: Icon(
                Symbols.music_note_rounded,
                size: size / 2,
                color:
                    fallbackColor ??
                    Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        },
      ),
    );
  }
}
