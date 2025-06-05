// lib/services/time_sync.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:echosync/blocs/time_sync/time_sync_bloc.dart';
import 'package:echosync/data/protocol/base.dart';
import 'package:echosync/data/protocol/sync.dart';

import 'mesh_network.dart';

class TimeSyncService {
  final MeshNetwork _meshNetwork;
  final String _deviceIp;
  TimeSyncBloc? _timeSyncBloc;

  bool _isLeader = false;
  int _clockOffset = 0;
  final Map<String, List<int>> _rttMeasurements = {};
  final Map<int, int> _pendingSyncRequests = {};
  Timer? _syncTimer;
  Timer? _broadcastTimer;

  TimeSyncService({required MeshNetwork meshNetwork, required String deviceIp})
    : _meshNetwork = meshNetwork,
      _deviceIp = deviceIp;

  // Set BLoC reference for direct event emission
  void setBlocReference(TimeSyncBloc timeSyncBloc) {
    _timeSyncBloc = timeSyncBloc;
  }

  bool get isLeader => _isLeader;

  int get clockOffset => _clockOffset;

  void setAsLeader() {
    _isLeader = true;
    _clockOffset = 0;
    print('Device $_deviceIp is now the time sync leader');
    // Directly notify TimeSyncBloc
    _timeSyncBloc?.add(UpdateClockOffset(_clockOffset));
  }

  void setAsFollower() {
    _isLeader = false;
    print('Device $_deviceIp is now a time sync follower');
  }

  int localToNetworkTime(int localTime) {
    return localTime + _clockOffset;
  }

  int networkToLocalTime(int networkTime) {
    return networkTime - _clockOffset;
  }

  NetworkTime getNetworkTime() {
    return NetworkTime(
      localToNetworkTime(DateTime.now().millisecondsSinceEpoch),
    );
  }

  // This method will be called by MeshNetwork when it receives time sync messages
  void processTimeMessage(TimeSyncMessage message) {
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

  void _processResponseAck(TimeSyncMessage message) {
    if (message.requestTime == null) return;

    final receiveTime = DateTime.now().millisecondsSinceEpoch;
    final rtt = receiveTime - message.requestTime!;

    _rttMeasurements.putIfAbsent(message.senderId, () => []);
    _rttMeasurements[message.senderId]!.add(rtt);
    if (_rttMeasurements[message.senderId]!.length > 5) {
      _rttMeasurements[message.senderId]!.removeAt(0);
    }

    print('RTT to ${message.senderId}: ${rtt}ms');
  }

  void _processSyncResponse(TimeSyncMessage message) {
    print(
      "Processing sync response from ${message.senderId}: ${jsonEncode(message.toJson())}",
    );
    if (message.requestId == null ||
        message.requestTime == null ||
        message.responseTime == null) {
      return;
    }

    final requestId = message.requestId!;
    final requestTime = message.requestTime!;
    final responseTime = message.responseTime!;
    final receiveTime = DateTime.now().millisecondsSinceEpoch;

    _pendingSyncRequests.remove(requestId);

    final roundTripTime = receiveTime - requestTime;
    final oneWayDelay = roundTripTime ~/ 2;
    final offset = responseTime - (requestTime + oneWayDelay);

    _clockOffset = (_clockOffset * 7 + offset) ~/ 8;
    print('Clock offset updated: ${_clockOffset}ms');

    // Directly notify TimeSyncBloc
    _timeSyncBloc?.add(UpdateClockOffset(_clockOffset));

    final ack = TimeSyncMessage.responseAck(
      senderId: _deviceIp,
      requestTime: requestTime,
      responseTime: responseTime,
      ackTime: receiveTime,
    );
    _meshNetwork.sendTimeSyncMessage(ack);
  }

  void _processBroadcast(TimeSyncMessage message) {
    print(
      "Processing sync response from ${message.senderId}: ${jsonEncode(message.toJson())}",
    );
    if (message.leaderTime == null) return;

    final leaderTime = message.leaderTime!;
    final receiveTime = DateTime.now().millisecondsSinceEpoch;
    final estimatedOffset = leaderTime - receiveTime;

    _clockOffset = (_clockOffset * 9 + estimatedOffset) ~/ 10;

    // Directly notify TimeSyncBloc
    _timeSyncBloc?.add(UpdateClockOffset(_clockOffset));
  }

  void _performSync() {
    if (_isLeader) return;

    final requestId = Random().nextInt(100000);
    final requestTime = DateTime.now().millisecondsSinceEpoch;

    _pendingSyncRequests[requestId] = requestTime;

    final request = TimeSyncMessage.request(
      senderId: _deviceIp,
      requestId: requestId,
      requestTime: requestTime,
    );
    _meshNetwork.sendTimeSyncMessage(request);
  }

  void _broadcastTime() {
    if (!_isLeader) return;

    final broadcast = TimeSyncMessage.broadcast(
      senderId: _deviceIp,
      leaderTime: DateTime.now().millisecondsSinceEpoch,
    );
    _meshNetwork.sendTimeSyncMessage(broadcast);
  }

  void startPeriodicSync({int intervalMs = 5000}) {
    _syncTimer?.cancel();
    _broadcastTimer?.cancel();

    if (_isLeader) {
      _broadcastTimer = Timer.periodic(
        Duration(milliseconds: intervalMs),
        (_) => _broadcastTime(),
      );
    } else {
      _syncTimer = Timer.periodic(
        Duration(milliseconds: intervalMs),
        (_) => _performSync(),
      );
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
