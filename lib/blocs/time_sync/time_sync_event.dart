part of 'time_sync_bloc.dart';

abstract class TimeSyncEvent {}

class InitializeTimeSync extends TimeSyncEvent {
  final MeshNetwork meshNetwork;
  final String deviceIp;

  InitializeTimeSync(this.meshNetwork, this.deviceIp);
}

class SetAsTimeSyncLeader extends TimeSyncEvent {}

class SetAsTimeSyncFollower extends TimeSyncEvent {}

class UpdateClockOffset extends TimeSyncEvent {
  final int offset;

  UpdateClockOffset(this.offset);
}

class TimeSyncMessageReceived extends TimeSyncEvent {
  final TimeSyncMessage message;

  TimeSyncMessageReceived(this.message);
}
