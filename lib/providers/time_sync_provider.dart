// lib/services/time_sync_provider.dart
import 'package:echosync/services/time_sync.dart';
import 'package:flutter/foundation.dart';

import '../services/mesh_network.dart';

class TimeSyncProvider extends ChangeNotifier {
  TimeSyncService? _timeSyncService;

  TimeSyncService? get timeSyncService => _timeSyncService;

  void initialize(MeshNetwork meshNetwork, String deviceIp) {
    _timeSyncService = TimeSyncService(
      meshNetwork: meshNetwork,
      deviceIp: deviceIp,
    );
    _timeSyncService!.startPeriodicSync();
    notifyListeners();
  }

  void disposeService() {
    _timeSyncService?.dispose();
    _timeSyncService = null;
    notifyListeners();
  }
}
