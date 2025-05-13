// lib/services/time_sync_service.dart
import 'dart:async';
import 'dart:math';

class TimeSyncService {
  final Function(Map<String, dynamic>) sendMessage;
  final String deviceId;
  bool _isLeader = false;

  // Clock offset relative to leader (in milliseconds)
  int _clockOffset = 0;

  // For leader: store RTT measurements for each device
  final Map<String, List<int>> _rttMeasurements = {};

  // For followers: store sync requests for calculation
  final Map<int, int> _pendingSyncRequests = {};

  TimeSyncService({required this.deviceId, required this.sendMessage});

  void setAsLeader() {
    _isLeader = true;
    _clockOffset = 0; // Leader's clock is the reference
  }

  // Convert timestamp from local time to network time
  int localToNetworkTime(int localTime) {
    return localTime + _clockOffset;
  }

  // Convert timestamp from network time to local time
  int networkToLocalTime(int localTime) {
    return localTime - _clockOffset;
  }

  // Process incoming time sync messages
  void processTimeMessage(Map<String, dynamic> message) {
    final String type = message['sync_type'];

    if (_isLeader) {
      if (type == 'request') {
        _handleSyncRequest(message);
      } else if (type == 'response_ack') {
        _processResponseAck(message);
      }
    } else {
      if (type == 'response') {
        _processSyncResponse(message);
      } else if (type == 'broadcast') {
        // Leader is broadcasting current network time
        // Use this as an additional calibration point
        final int leaderTime = message['leader_time'];
        final int receiveTime = DateTime.now().millisecondsSinceEpoch;
        final int estimatedOffset = leaderTime - receiveTime;

        // Update with a low weight to avoid overreacting to network jitter
        _clockOffset = (_clockOffset * 9 + estimatedOffset) ~/ 10;
      }
    }
  }

  // Leader: handle sync request from follower
  void _handleSyncRequest(Map<String, dynamic> message) {
    final String senderId = message['sender_id'];
    final int requestId = message['request_id'];
    final int requestTime = message['request_time'];
    final int receiveTime = DateTime.now().millisecondsSinceEpoch;

    sendMessage({
      'sync_type': 'response',
      'request_id': requestId,
      'request_time': requestTime,
      'response_time': receiveTime,
      'target_id': senderId,
    });
  }

  // Leader: process acknowledgment to measure RTT
  void _processResponseAck(Map<String, dynamic> message) {
    final String senderId = message['sender_id'];
    final int requestTime = message['request_time'];
    final int receiveTime = DateTime.now().millisecondsSinceEpoch;

    // Calculate round-trip time
    final int rtt = (receiveTime - requestTime);

    // Store RTT for this device (keep last 5 measurements)
    if (!_rttMeasurements.containsKey(senderId)) {
      _rttMeasurements[senderId] = [];
    }

    _rttMeasurements[senderId]!.add(rtt);
    if (_rttMeasurements[senderId]!.length > 5) {
      _rttMeasurements[senderId]!.removeAt(0);
    }
  }

  // Follower: process sync response from leader
  void _processSyncResponse(Map<String, dynamic> message) {
    final int requestId = message['request_id'];
    final int requestTime = message['request_time'];
    final int responseTime = message['response_time'];
    final int receiveTime = DateTime.now().millisecondsSinceEpoch;

    // Remove from pending requests
    _pendingSyncRequests.remove(requestId);

    // Calculate one-way delay (assuming symmetric network)
    final int roundTripTime = receiveTime - requestTime;
    final int oneWayDelay = roundTripTime ~/ 2;

    // Calculate clock offset: leader_time - (local_time + one_way_delay)
    final int offset = responseTime - (requestTime + oneWayDelay);

    // Update clock offset with exponential moving average
    _clockOffset = (_clockOffset * 7 + offset) ~/ 8;

    // Send acknowledgment back to leader for RTT calculation
    sendMessage({
      'sync_type': 'response_ack',
      'request_time': requestTime,
      'response_time': responseTime,
      'ack_time': receiveTime,
    });
  }

  // Start synchronization process (for followers)
  void sync() {
    if (_isLeader) return;

    final int requestId = Random().nextInt(100000);
    final int requestTime = DateTime.now().millisecondsSinceEpoch;

    // Store request time
    _pendingSyncRequests[requestId] = requestTime;

    // Send sync request
    sendMessage({
      'sync_type': 'request',
      'request_id': requestId,
      'request_time': requestTime,
      'sender_id': deviceId,
    });
  }

  // Leader: broadcast network time for additional synchronization
  void broadcastTime() {
    if (!_isLeader) return;

    sendMessage({
      'sync_type': 'broadcast',
      'leader_time': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Start periodic sync
  Timer? _syncTimer;
  Timer? _broadcastTimer;

  void startPeriodicSync({int intervalMs = 5000}) {
    _syncTimer?.cancel();
    _broadcastTimer?.cancel();

    if (_isLeader) {
      // Leader broadcasts time regularly
      _broadcastTimer = Timer.periodic(
        Duration(milliseconds: intervalMs),
        (_) => broadcastTime(),
      );
    } else {
      // Followers sync regularly
      _syncTimer = Timer.periodic(
        Duration(milliseconds: intervalMs),
        (_) => sync(),
      );

      // Initial sync immediately
      sync();
    }
  }

  void dispose() {
    _syncTimer?.cancel();
    _broadcastTimer?.cancel();
  }
}
