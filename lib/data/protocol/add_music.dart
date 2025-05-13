class AddMusicMessage {
  final String musicId; // Checksum
  final String sourceLocation;

  AddMusicMessage({required this.musicId, required this.sourceLocation});

  Map<String, dynamic> toJson() {
    return {'musicId': musicId, 'sourceLocation': sourceLocation};
  }

  factory AddMusicMessage.fromJson(Map<String, dynamic> json) {
    return AddMusicMessage(
      musicId: json['musicId'],
      sourceLocation: json['sourceLocation'],
    );
  }
}
