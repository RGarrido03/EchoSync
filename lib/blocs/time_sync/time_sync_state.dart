part of 'time_sync_bloc.dart';

abstract class TimeSyncState {}

class TimeSyncInitial extends TimeSyncState {}

class TimeSyncInitializing extends TimeSyncState {}

class TimeSyncReady extends TimeSyncState {
  final TimeSyncService timeSyncService;
  final bool isLeader;
  final int clockOffset;

  TimeSyncReady({
    required this.timeSyncService,
    required this.isLeader,
    required this.clockOffset,
  });
}

class TimeSyncError extends TimeSyncState {
  final String error;

  TimeSyncError(this.error);
}
