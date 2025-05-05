import 'package:flutter/material.dart';

class LibraryTab extends StatelessWidget {
  const LibraryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Library', style: Theme.of(context).textTheme.headlineLarge),
    );
  }
}
