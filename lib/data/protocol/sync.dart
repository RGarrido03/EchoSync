import 'package:json_annotation/json_annotation.dart';

import 'base.dart';

part 'sync.g.dart';

@JsonSerializable()
class TimeSyncMessage extends SyncMessage {
  final String syncType;
  final String senderId;
  final int? requestId;
  final int? requestTime;
  final int? responseTime;
  final int? leaderTime;
  final String? targetId;

  TimeSyncMessage({
    required this.syncType,
    required this.senderId,
    this.requestId,
    this.requestTime,
    this.responseTime,
    this.leaderTime,
    this.targetId,
  }) : super('time_sync');

  factory TimeSyncMessage.request({
    required String senderId,
    required int requestId,
    required int requestTime,
  }) {
    return TimeSyncMessage(
      syncType: 'request',
      senderId: senderId,
      requestId: requestId,
      requestTime: requestTime,
    );
  }

  factory TimeSyncMessage.response({
    required String senderId,
    required int requestId,
    required int requestTime,
    required int responseTime,
    required String targetId,
  }) {
    return TimeSyncMessage(
      syncType: 'response',
      senderId: senderId,
      requestId: requestId,
      requestTime: requestTime,
      responseTime: responseTime,
      targetId: targetId,
    );
  }

  factory TimeSyncMessage.responseAck({
    required String senderId,
    required int requestTime,
    required int responseTime,
    required int ackTime,
  }) {
    return TimeSyncMessage(
      syncType: 'response_ack',
      senderId: senderId,
      requestTime: requestTime,
      responseTime: responseTime,
    );
  }

  factory TimeSyncMessage.broadcast({
    required String senderId,
    required int leaderTime,
  }) {
    return TimeSyncMessage(
      syncType: 'broadcast',
      senderId: senderId,
      leaderTime: leaderTime,
    );
  }

  factory TimeSyncMessage.fromJson(Map<String, dynamic> json) =>
      _$TimeSyncMessageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$TimeSyncMessageToJson(this);
}
