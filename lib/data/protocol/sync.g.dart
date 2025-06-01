// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimeSyncMessage _$TimeSyncMessageFromJson(Map<String, dynamic> json) =>
    TimeSyncMessage(
      syncType: json['syncType'] as String,
      senderId: json['senderId'] as String,
      requestId: (json['requestId'] as num?)?.toInt(),
      requestTime: (json['requestTime'] as num?)?.toInt(),
      responseTime: (json['responseTime'] as num?)?.toInt(),
      leaderTime: (json['leaderTime'] as num?)?.toInt(),
      targetId: json['targetId'] as String?,
    );

Map<String, dynamic> _$TimeSyncMessageToJson(TimeSyncMessage instance) =>
    <String, dynamic>{
      'syncType': instance.syncType,
      'senderId': instance.senderId,
      'requestId': instance.requestId,
      'requestTime': instance.requestTime,
      'responseTime': instance.responseTime,
      'leaderTime': instance.leaderTime,
      'targetId': instance.targetId,
    };
