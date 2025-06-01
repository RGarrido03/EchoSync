// lib/messages/base.dart
import 'package:json_annotation/json_annotation.dart';

part 'base.g.dart';

abstract class SyncMessage {
  final String command;
  final DateTime timestamp;

  SyncMessage(this.command, {DateTime? timestamp})
    : timestamp = (timestamp ?? DateTime.now());

  Map<String, dynamic> toJson();
}

// Network time representation for synchronization
@JsonSerializable()
class NetworkTime {
  final int millisSinceEpoch;

  const NetworkTime(this.millisSinceEpoch);

  static NetworkTime now() {
    return NetworkTime(DateTime.now().millisecondsSinceEpoch);
  }

  DateTime toDateTime() {
    return DateTime.fromMillisecondsSinceEpoch(millisSinceEpoch);
  }

  factory NetworkTime.fromJson(Map<String, dynamic> json) {
    return NetworkTime(json['millisSinceEpoch'] as int);
  }

  Map<String, dynamic> toJson() {
    return {'millisSinceEpoch': millisSinceEpoch};
  }

  @override
  String toString() => toDateTime().toIso8601String();
}
