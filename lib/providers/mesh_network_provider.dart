// lib/services/mesh_network_provider.dart
import 'package:echosync/services/mesh_network.dart';
import 'package:flutter/foundation.dart';

import '../data/device.dart';

class MeshNetworkProvider extends ChangeNotifier {
  MeshNetwork? _meshNetwork;

  MeshNetwork? get meshNetwork => _meshNetwork;

  Future<void> initialize(Device device) async {
    _meshNetwork = MeshNetwork(deviceInfo: device);
    await _meshNetwork!.connect();
    notifyListeners();
  }

  void disconnect() {
    _meshNetwork?.disconnect();
    _meshNetwork = null;
    notifyListeners();
  }
}
