// lib/bloc/time_sync/time_sync_bloc.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/protocol/sync.dart';
import '../../services/mesh_network.dart';
import '../../services/time_sync.dart';

part 'time_sync_event.dart';
part 'time_sync_state.dart';

class TimeSyncBloc extends Bloc<TimeSyncEvent, TimeSyncState> {
  TimeSyncService? _timeSyncService;
  StreamSubscription<int>? _clockOffsetSubscription;
  StreamSubscription<TimeSyncMessage>? _timeSyncMessageSubscription;

  TimeSyncService? get timeSyncService => _timeSyncService;

  TimeSyncBloc() : super(TimeSyncInitial()) {
    on<InitializeTimeSync>(_onInitialize);
    on<SetAsTimeSyncLeader>(_onSetAsLeader);
    on<SetAsTimeSyncFollower>(_onSetAsFollower);
    on<UpdateClockOffset>(_onUpdateOffset);
    on<TimeSyncMessageReceived>(_onMessageReceived);
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

      _clockOffsetSubscription = _timeSyncService!.clockOffsetStream.listen((
        offset,
      ) {
        add(UpdateClockOffset(offset));
      });

      _timeSyncMessageSubscription = event
          .meshNetwork
          .streams
          .timeSyncMessageStream
          .listen((message) {
            add(TimeSyncMessageReceived(message));
          });

      // TODO: Reenable this
      // _timeSyncService!.startPeriodicSync();

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
      debugPrint("HERE LEAD THIS SHIT MF");
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
    debugPrint("Updated clock: ${event.offset}, $state");
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

  void _onMessageReceived(
    TimeSyncMessageReceived event,
    Emitter<TimeSyncState> emit,
  ) {
    if (_timeSyncService != null) {
      _timeSyncService!.processTimeMessage(event.message);
    }
  }

  @override
  Future<void> close() {
    _clockOffsetSubscription?.cancel();
    _timeSyncMessageSubscription?.cancel();
    _timeSyncService?.dispose();
    return super.close();
  }
}
