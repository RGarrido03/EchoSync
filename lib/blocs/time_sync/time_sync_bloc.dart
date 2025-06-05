// lib/bloc/time_sync/time_sync_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/mesh_network.dart';
import '../../services/time_sync.dart';

part 'time_sync_event.dart';
part 'time_sync_state.dart';

class TimeSyncBloc extends Bloc<TimeSyncEvent, TimeSyncState> {
  TimeSyncService? _timeSyncService;

  TimeSyncService? get timeSyncService => _timeSyncService;

  TimeSyncBloc() : super(TimeSyncInitial()) {
    on<InitializeTimeSync>(_onInitialize);
    on<SetAsTimeSyncLeader>(_onSetAsLeader);
    on<SetAsTimeSyncFollower>(_onSetAsFollower);
    on<UpdateClockOffset>(_onUpdateOffset);
  }

  Future<void> _onInitialize(
    InitializeTimeSync event,
    Emitter<TimeSyncState> emit,
  ) async {
    try {
      emit(TimeSyncInitializing());

      _timeSyncService = TimeSyncService(
        meshNetwork: event.meshNetwork,
        deviceIp: event.deviceIp,
      );

      // Set BLoC reference in the service for direct event emission
      _timeSyncService!.setBlocReference(this);

      _timeSyncService!.startPeriodicSync();

      emit(
        TimeSyncReady(
          timeSyncService: _timeSyncService!,
          isLeader: _timeSyncService!.isLeader,
          clockOffset: _timeSyncService!.clockOffset,
        ),
      );
    } catch (e) {
      emit(TimeSyncError(e.toString()));
    }
  }

  void _onSetAsLeader(SetAsTimeSyncLeader event, Emitter<TimeSyncState> emit) {
    if (_timeSyncService != null) {
      _timeSyncService!.setAsLeader();
      emit(
        TimeSyncReady(
          timeSyncService: _timeSyncService!,
          isLeader: true,
          clockOffset: _timeSyncService!.clockOffset,
        ),
      );
    }
  }

  void _onSetAsFollower(
    SetAsTimeSyncFollower event,
    Emitter<TimeSyncState> emit,
  ) {
    if (_timeSyncService != null) {
      _timeSyncService!.setAsFollower();
      emit(
        TimeSyncReady(
          timeSyncService: _timeSyncService!,
          isLeader: false,
          clockOffset: _timeSyncService!.clockOffset,
        ),
      );
    }
  }

  void _onUpdateOffset(UpdateClockOffset event, Emitter<TimeSyncState> emit) {
    if (state is TimeSyncReady && _timeSyncService != null) {
      emit(
        TimeSyncReady(
          timeSyncService: _timeSyncService!,
          isLeader: _timeSyncService!.isLeader,
          clockOffset: event.offset,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _timeSyncService?.dispose();
    return super.close();
  }
}
