enum ControlMessageType {
  play,
  pause,
  volumeUp,
  volumeDown,
  next,
  previous,
  selectTrack,
}

class ControlMessage {
  final ControlMessageType type;
  final String trackId;
  final double volumeLevel;

  const ControlMessage({
    required this.type,
    required this.trackId,
    required this.volumeLevel,
  });

  Map<String, dynamic> toJson() => {
    'message': 'control',
    'type': type.name,
    'trackId': trackId,
    'volumeLevel': volumeLevel,
  };

  factory ControlMessage.fromJson(Map<String, dynamic> json) {
    return ControlMessage(
      type: ControlMessageType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      trackId: json['trackId'],
      volumeLevel: json['volumeLevel'],
    );
  }
}
