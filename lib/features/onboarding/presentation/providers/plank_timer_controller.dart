import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_motion.dart';

@immutable
class PlankTimerState {
  const PlankTimerState({this.elapsedSeconds = 0, this.isRunning = false});

  final double elapsedSeconds;
  final bool isRunning;

  PlankTimerState copyWith({double? elapsedSeconds, bool? isRunning}) {
    return PlankTimerState(
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}

final plankTimerControllerProvider =
    NotifierProvider.autoDispose<PlankTimerController, PlankTimerState>(
      PlankTimerController.new,
    );

/// Plank-hold stopwatch. Uses a real [Stopwatch] (monotonic clock) rather
/// than incrementing a counter every tick, so elapsed time stays accurate
/// even if a tick is delayed. `autoDispose` resets the hold whenever the
/// user navigates away, matching the source design's per-visit reset.
class PlankTimerController extends Notifier<PlankTimerState> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;

  @override
  PlankTimerState build() {
    ref.onDispose(() => _ticker?.cancel());
    return const PlankTimerState();
  }

  void toggle() {
    if (state.isRunning) {
      _ticker?.cancel();
      _stopwatch.stop();
      state = state.copyWith(
        elapsedSeconds: _stopwatch.elapsedMilliseconds / 1000,
        isRunning: false,
      );
    } else {
      _stopwatch
        ..reset()
        ..start();
      _ticker = Timer.periodic(AppDurations.tick, (_) {
        state = state.copyWith(
          elapsedSeconds: _stopwatch.elapsedMilliseconds / 1000,
        );
      });
      state = state.copyWith(elapsedSeconds: 0, isRunning: true);
    }
  }
}
