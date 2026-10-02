import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

import '../data/voice_settings.dart';
import '../data/voice_settings_provider.dart';

/// Vibration alerts (UR-03).
///
/// Two patterns that feel clearly different:
/// - HIGH severity: three long, strong buzzes, repeated until the alert is
///   dismissed (with a safety stop after [maxHighAlertDuration]).
/// - LOW severity: one short pulse.
///
/// Respects the "Haptic feedback" switch (hapticEnabled) in settings.
/// Phones without a vibrator are detected, and nothing crashes.
class HapticService {
  HapticService(this.settingsProvider);

  final VoiceSettingsProvider settingsProvider;

  // A pattern is a list of milliseconds: [wait, buzz, wait, buzz, ...].

  /// High severity: buzz 800 ms, pause 200 ms, three times.
  static const List<int> highSeverityPattern = [0, 800, 200, 800, 200, 800];

  /// Low severity: a single 150 ms pulse.
  static const List<int> lowSeverityPattern = [0, 150];

  /// The high pattern stops by itself after this time, in case nobody
  /// dismisses the alert.
  static const Duration maxHighAlertDuration = Duration(seconds: 30);

  /// Pause before the high pattern repeats (milliseconds).
  static const int _highRepeatGap = 600;

  bool? _hasVibrator; // null = not checked yet
  bool _hasAmplitudeControl = false;
  Timer? _safetyStopTimer;

  /// Vibration strength 1-255 for each intensity setting.
  /// Only used on phones that support amplitude control.
  static int amplitudeFor(HapticIntensity intensity) {
    switch (intensity) {
      case HapticIntensity.gentle:
        return 80;
      case HapticIntensity.medium:
        return 160;
      case HapticIntensity.strong:
        return 255;
    }
  }

  /// True if this phone can vibrate. Checked once, then remembered.
  Future<bool> isAvailable() async {
    if (_hasVibrator != null) return _hasVibrator!;
    try {
      _hasVibrator = await Vibration.hasVibrator();
      _hasAmplitudeControl = await Vibration.hasAmplitudeControl();
    } catch (e) {
      debugPrint('HapticService: vibrator check failed: $e');
      _hasVibrator = false;
    }
    return _hasVibrator!;
  }

  /// High severity: always full strength, repeats until [stop].
  /// Returns false if it did not vibrate (switched off or no vibrator).
  Future<bool> vibrateHigh() async {
    // Repeat the whole pattern (plus a short gap) until stop() is called.
    final started = await _vibrate(
      _withGap(highSeverityPattern),
      amplitude: 255,
      repeat: 0,
    );
    if (started) {
      _safetyStopTimer?.cancel();
      _safetyStopTimer = Timer(maxHighAlertDuration, stop);
    }
    return started;
  }

  /// Low severity: one short pulse at the user's chosen intensity.
  Future<bool> vibrateLow() {
    final amplitude = amplitudeFor(settingsProvider.settings.hapticIntensity);
    return _vibrate(lowSeverityPattern, amplitude: amplitude);
  }

  /// Stops any vibration (called when an alert is dismissed).
  Future<void> stop() async {
    _safetyStopTimer?.cancel();
    _safetyStopTimer = null;
    try {
      await Vibration.cancel();
    } catch (e) {
      debugPrint('HapticService: cancel failed: $e');
    }
  }

  // Adds a pause at the end so repeats do not run together.
  List<int> _withGap(List<int> pattern) => [...pattern, _highRepeatGap];

  // Runs a pattern. Never throws.
  // repeat: -1 = play once, 0 = loop from the start until cancelled.
  Future<bool> _vibrate(
    List<int> pattern, {
    required int amplitude,
    int repeat = -1,
  }) async {
    if (!settingsProvider.settings.hapticEnabled) return false;
    if (!await isAvailable()) return false;

    try {
      await Vibration.vibrate(
        pattern: pattern,
        repeat: repeat,
        // One strength per pattern step: 0 for waits, amplitude for buzzes.
        intensities: _hasAmplitudeControl
            ? [for (var i = 0; i < pattern.length; i++) i.isOdd ? amplitude : 0]
            : const [],
      );
      return true;
    } catch (e) {
      debugPrint('HapticService: vibrate failed: $e');
      return false;
    }
  }
}
