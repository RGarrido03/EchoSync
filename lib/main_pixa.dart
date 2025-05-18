import 'dart:io';

import 'package:mqtt_server/mqtt_server.dart';

Future<void> main() async {
  print('Starting MQTT broker with persistence...');

  // Create a temporary directory for session data
  final tempDir = Directory('mqtt_data');
  if (!await tempDir.exists()) {
    await tempDir.create();
  }

  // Create a broker with persistence enabled
  final config = MqttBrokerConfig(
    port: 1883,
    enablePersistence: true,
    persistencePath: 'mqtt_data/sessions.json',
    sessionExpiryInterval: Duration(hours: 1),
  );

  final broker = MqttBroker(config);

  // Start the broker
  await broker.start();

  print('MQTT broker with persistence running on port 1883');
  print('Press Enter to stop the broker');
  await stdin.first;

  // Stop the broker - this will save sessions automatically
  await broker.stop();
  print('Persistent MQTT broker stopped');
}
