enum QueueMessageType { moveUp, moveDown }

class QueueMessage {
  final QueueMessageType type;

  QueueMessage({required this.type});

  Map<String, dynamic> toJson() {
    return {'message': 'queue', 'type': type.name};
  }

  factory QueueMessage.fromJson(Map<String, dynamic> json) {
    return QueueMessage(type: json['type']);
  }
}
