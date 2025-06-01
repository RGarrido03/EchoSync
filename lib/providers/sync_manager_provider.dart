// lib/services/sync_manager_provider.dart
import 'package:echosync/services/sync_manager.dart';
import 'package:flutter/foundation.dart';

import '../data/protocol/playback.dart';
import '../data/protocol/queue.dart';
import '../services/mesh_network.dart';
import '../services/time_sync.dart';

class SyncManagerProvider extends ChangeNotifier {
  SyncManager? _syncManager;
  PlaybackStatus? _playbackStatus;
  QueueStatus? _queueStatus;

  SyncManager? get syncManager => _syncManager;

  PlaybackStatus? get playbackStatus => _playbackStatus;

  QueueStatus? get queueStatus => _queueStatus;

  void initialize(
    MeshNetwork meshNetwork,
    TimeSyncService timeSyncService,
    String deviceIp,
  ) {
    _syncManager = SyncManager(
      meshNetwork: meshNetwork,
      timeSyncService: timeSyncService,
      deviceIp: deviceIp,
    );
    _syncManager!.initializeState();
    _syncManager!.playbackStateStream.listen((status) {
      _playbackStatus = status;
      notifyListeners();
    });
    _syncManager!.queueStateStream.listen((status) {
      _queueStatus = status;
      notifyListeners();
    });
    notifyListeners();
  }

  void disposeManager() {
    _syncManager?.dispose();
    _syncManager = null;
    _playbackStatus = null;
    _queueStatus = null;
    notifyListeners();
  }
}
