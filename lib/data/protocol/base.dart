// Base abstract message class

import 'package:json_annotation/json_annotation.dart';

part 'base.g.dart';

abstract class SyncMessage {
  final String command;

  const SyncMessage(this.command);
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
}
