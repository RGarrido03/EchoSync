import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_server/mqtt_server.dart';



Future<void> main() async {
  debugPrint('Starting MQTT broker with persistence...');

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

  debugPrint('MQTT broker with persistence running on port 1883');
  debugPrint('Press Enter to stop the broker');
  // await stdin.first;
  //
  // // Stop the broker - this will save sessions automatically
  // await broker.stop();
  // debugPrint('Persistent MQTT broker stopped');

  // let's make a client to subscribe to a topic
  final client = MqttServerClient('192.168.191.59', 'maPIXA');
  client.port = 1883;

  client.onDisconnected = () {
    debugPrint('Client disconnected');
  };

  client.onConnected = () {
    debugPrint('Client connected');
  };
  client.setProtocolV311();

  try {
    await client.connect();
    debugPrint('Client connected to broker');

    // Subscribe to a topic
    client.subscribe('echosync/queue/command', MqttQos.atLeastOnce);
    final pixa = "echosync";
    // publish some messages
    final builder = MqttClientPayloadBuilder();
    for (int i = 0; i < 5; i++) {
      builder.addString('Message $i');
      client.publishMessage('$pixa/queue/command', MqttQos.atLeastOnce, builder.payload!);
      debugPrint('Published message: Message $i');
      await Future.delayed(Duration(seconds: 1)); // Delay to simulate message sending
    }

    // Listen for messages
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (var message in messages) {
        final payload = message.payload as MqttPublishMessage;
        final messageContent = MqttPublishPayload.bytesToStringAsString(payload.payload.message);
        debugPrint('Received message: $messageContent on topic: ${message.topic}');
      }
    });
  } catch (e) {
    debugPrint('Error connecting client: $e');
  }


}
