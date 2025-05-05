import 'package:flutter/material.dart';

class DevicesTab extends StatelessWidget {
  const DevicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Devices', style: Theme.of(context).textTheme.headlineLarge),
    );
  }
}
