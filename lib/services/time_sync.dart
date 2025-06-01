import 'dart:async';
import 'dart:math';

import 'package:echosync/data/protocol/base.dart';
import 'package:echosync/data/protocol/sync.dart';

import 'mesh_network.dart';

class TimeSyncService {
  final MeshNetwork _meshNetwork;
  final String _deviceIp;
  bool _isLeader = false;

  // Clock offset relative to leader (in milliseconds)
  int _clockOffset = 0;

  // For leader: store RTT measurements for each device
  final Map<String, List<int>> _rttMeasurements = {};

  // For followers: store sync requests for calculation
  final Map<int, int> _pendingSyncRequests = {};

  Timer? _syncTimer;
  Timer? _broadcastTimer;

  TimeSyncService({required MeshNetwork meshNetwork, required String deviceIp})
    : _meshNetwork = meshNetwork,
      _deviceIp = deviceIp {
    // Listen to time sync messages
    _meshNetwork.timeSyncStream.listen(_processTimeMessage);
  }

  bool get isLeader => _isLeader;

  int get clockOffset => _clockOffset;

  void setAsLeader() {
    _isLeader = true;
    _clockOffset = 0; // Leader's clock is the reference
    print('Device $_deviceIp is now the time sync leader');
  }

  void setAsFollower() {
    _isLeader = false;
    print('Device $_deviceIp is now a time sync follower');
  }

  // Convert timestamp from local time to network time
  int localToNetworkTime(int localTime) {
    return localTime + _clockOffset;
  }

  // Convert timestamp from network time to local time
  int networkToLocalTime(int networkTime) {
    return networkTime - _clockOffset;
  }

  // Get current network time
  NetworkTime getNetworkTime() {
    return NetworkTime(
      localToNetworkTime(DateTime.now().millisecondsSinceEpoch),
    );
  }

  // Process incoming time sync messages
  void _processTimeMessage(TimeSyncMessage message) {
    if (_isLeader) {
      if (message.syncType == 'request') {
        _handleSyncRequest(message);
      } else if (message.syncType == 'response_ack') {
        _processResponseAck(message);
      }
    } else {
      if (message.syncType == 'response' && message.targetId == _deviceIp) {
        _processSyncResponse(message);
      } else if (message.syncType == 'broadcast') {
        _processBroadcast(message);
      }
    }
  }

  // Leader: handle sync request from follower
  void _handleSyncRequest(TimeSyncMessage message) {
    if (message.requestId == null || message.requestTime == null) return;

    final receiveTime = DateTime.now().millisecondsSinceEpoch;

    final response = TimeSyncMessage.response(
      senderId: _deviceIp,
      requestId: message.requestId!,
      requestTime: message.requestTime!,
      responseTime: receiveTime,
      targetId: message.senderId,
    );

    _meshNetwork.sendTimeSyncMessage(response);
  }

  // Leader: process acknowledgment to measure RTT
  void _processResponseAck(TimeSyncMessage message) {
    if (message.requestTime == null) return;

    final receiveTime = DateTime.now().millisecondsSinceEpoch;
    final rtt = receiveTime - message.requestTime!;

    // Store RTT for this device (keep last 5 measurements)
    _rttMeasurements.putIfAbsent(message.senderId, () => <int>[]);
    _rttMeasurements[message.senderId]!.add(rtt);

    if (_rttMeasurements[message.senderId]!.length > 5) {
      _rttMeasurements[message.senderId]!.removeAt(0);
    }

    print('RTT to ${message.senderId}: ${rtt}ms');
  }

  // Follower: process sync response from leader
  void _processSyncResponse(TimeSyncMessage message) {
    if (message.requestId == null ||
        message.requestTime == null ||
        message.responseTime == null)
      return;

    final requestId = message.requestId!;
    final requestTime = message.requestTime!;
    final responseTime = message.responseTime!;
    final receiveTime = DateTime.now().millisecondsSinceEpoch;

    // Remove from pending requests
    _pendingSyncRequests.remove(requestId);

    // Calculate one-way delay (assuming symmetric network)
    final roundTripTime = receiveTime - requestTime;
    final oneWayDelay = roundTripTime ~/ 2;

    // Calculate clock offset: leader_time - (local_time + one_way_delay)
    final offset = responseTime - (requestTime + oneWayDelay);

    // Update clock offset with exponential moving average
    _clockOffset = (_clockOffset * 7 + offset) ~/ 8;

    print('Clock offset updated: ${_clockOffset}ms');

    // Send acknowledgment back to leader for RTT calculation
    final ack = TimeSyncMessage.responseAck(
      senderId: _deviceIp,
      requestTime: requestTime,
      responseTime: responseTime,
      ackTime: receiveTime,
    );

    _meshNetwork.sendTimeSyncMessage(ack);
  }

  // Follower: process time broadcast from leader
  void _processBroadcast(TimeSyncMessage message) {
    if (message.leaderTime == null) return;

    final leaderTime = message.leaderTime!;
    final receiveTime = DateTime.now().millisecondsSinceEpoch;
    final estimatedOffset = leaderTime - receiveTime;

    // Update with a low weight to avoid overreacting to network jitter
    _clockOffset = (_clockOffset * 9 + estimatedOffset) ~/ 10;
  }

  // Start synchronization process (for followers)
  void _performSync() {
    if (_isLeader) return;

    final requestId = Random().nextInt(100000);
    final requestTime = DateTime.now().millisecondsSinceEpoch;

    // Store request time
    _pendingSyncRequests[requestId] = requestTime;

    // Send sync request
    final request = TimeSyncMessage.request(
      senderId: _deviceIp,
      requestId: requestId,
      requestTime: requestTime,
    );

    _meshNetwork.sendTimeSyncMessage(request);
  }

  // Leader: broadcast network time for additional synchronization
  void _broadcastTime() {
    if (!_isLeader) return;

    final broadcast = TimeSyncMessage.broadcast(
      senderId: _deviceIp,
      leaderTime: DateTime.now().millisecondsSinceEpoch,
    );

    _meshNetwork.sendTimeSyncMessage(broadcast);
  }

  // Start periodic sync
  void startPeriodicSync({int intervalMs = 5000}) {
    _syncTimer?.cancel();
    _broadcastTimer?.cancel();

    if (_isLeader) {
      // Leader broadcasts time regularly
      _broadcastTimer = Timer.periodic(
        Duration(milliseconds: intervalMs),
        (_) => _broadcastTime(),
      );
    } else {
      // Followers sync regularly
      _syncTimer = Timer.periodic(
        Duration(milliseconds: intervalMs),
        (_) => _performSync(),
      );

      // Initial sync immediately
      _performSync();
    }
  }

  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _broadcastTimer?.cancel();
  }

  void dispose() {
    stopPeriodicSync();
  }
}
