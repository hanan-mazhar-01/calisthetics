import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// The app's one place for haptic feedback.
///
/// iPhone: the system Taptic Engine (light / medium / heavy impact).
/// Android: Flutter's own haptics follow the phone's "touch feedback"
/// switch, which many phones ship turned off (nothing is felt), so the
/// vibration motor is driven directly with a short, medium-strength pulse.
class Haptics {
  const Haptics._();

  /// Tests switch this off so no plugin is called.
  static bool enabled = true;

  static bool? _amplitude;

  static bool get _android => !kIsWeb && Platform.isAndroid;

  static Future<void> _pulse(int ms, int amplitude) async {
    try {
      _amplitude ??= await Vibration.hasAmplitudeControl();
      if (_amplitude == true) {
        await Vibration.vibrate(duration: ms, amplitude: amplitude);
      } else {
        // No strength control (common on mid-range phones): the pulse
        // length sets how firm it feels, and a motor needs a little time
        // to spin up, so the pulses are longer.
        await Vibration.vibrate(duration: (ms * 1.8).round());
      }
    } catch (e) {
      debugPrint('Haptics: $e');
    }
  }

  /// A tick, as each letter of a headline is typed.
  static void tick() {
    if (!enabled) return;
    _android ? _pulse(12, 80) : HapticFeedback.selectionClick();
  }

  /// A light tap (switching a toggle, moving a slider).
  static void light() {
    if (!enabled) return;
    _android ? _pulse(18, 100) : HapticFeedback.lightImpact();
  }

  /// A medium tap: choosing an option, pressing a main button.
  static void medium() {
    if (!enabled) return;
    _android ? _pulse(26, 150) : HapticFeedback.mediumImpact();
  }

  /// A strong tap: a purchase or a finished workout.
  static void heavy() {
    if (!enabled) return;
    _android ? _pulse(45, 230) : HapticFeedback.heavyImpact();
  }
}
