// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdatePlaylistMessage _$UpdatePlaylistMessageFromJson(
  Map<String, dynamic> json,
) => UpdatePlaylistMessage(
  playlist:
      (json['playlist'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$UpdatePlaylistMessageToJson(
  UpdatePlaylistMessage instance,
) => <String, dynamic>{'playlist': instance.playlist};

RequestPlaylistMessage _$RequestPlaylistMessageFromJson(
  Map<String, dynamic> json,
) => RequestPlaylistMessage(senderId: json['senderId'] as String);

Map<String, dynamic> _$RequestPlaylistMessageToJson(
  RequestPlaylistMessage instance,
) => <String, dynamic>{'senderId': instance.senderId};
