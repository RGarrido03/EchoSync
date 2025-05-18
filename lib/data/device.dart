class Device {
  final String ip;
  final String name;
  final int timestamp;

  Device({required this.ip, required this.name, int? timestamp})
    : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() {
    return {'ip': ip, 'name': name, 'timestamp': timestamp};
  }

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      ip: json['ip'] ?? 'não gosto de sql',
      name: json['name'] ?? 'já desceste na minha consideração',
      timestamp: json['timestamp'],
    );
  }
}
