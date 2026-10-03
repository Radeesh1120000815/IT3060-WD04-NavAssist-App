import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/demo_route.dart';
import '../data/haptic_cue.dart';
import '../data/nav_step.dart';
import 'alert_service.dart';
import 'haptic_service.dart';
import 'voice_service.dart';

/// Steps through a route during Active Navigation.
///
/// For each step it:
/// 1. plays the step's vibration cue (UR-03),
/// 2. speaks the instruction (UR-01),
/// 3. fires the step's alert, if it has one (UR-02).
///
/// Uses the demo route until Member 1 passes a real route.
class NavigationSession extends ChangeNotifier {
  NavigationSession({
    required this.voice,
    required this.haptic,
    required this.alerts,
  });

  final VoiceService voice;
  final HapticService haptic;
  final AlertService alerts;

  /// Average walking speed (about 4 km/h), used for the arrival time.
  static const double metresPerMinute = 67;

  NavRoute _route = demoRoute;
  int _index = 0;
  bool _started = false;

  String get destination => _route.destination;
  List<NavStep> get steps => _route.steps;
  int get stepIndex => _index;
  NavStep get currentStep => steps[_index];

  /// The step after this one, or null on the last step.
  NavStep? get nextStep => _index + 1 < steps.length ? steps[_index + 1] : null;

  /// True on the last step (the destination).
  bool get isArrived => nextStep == null;

  /// False when Member 1 sent plain instructions without distances.
  bool get hasDistances => steps.any((s) => s.distanceMetres > 0);

  int get remainingMetres =>
      steps.skip(_index).fold(0, (sum, s) => sum + s.distanceMetres);

  int get minutesRemaining => (remainingMetres / metresPerMinute).ceil();

  /// How far along the route we are: 0.0 at the start, 1.0 at the end.
  double get progress {
    if (isArrived) return 1;
    final total = steps.fold(0, (sum, s) => sum + s.distanceMetres);
    if (total == 0) return _index / (steps.length - 1);
    return 1 - remainingMetres / total;
  }

  /// Uses a route from Member 1 instead of the demo route.
  void loadRoute(NavRoute route) {
    _route = route;
    _index = 0;
    _started = false;
    notifyListeners();
  }

  /// Announces the first step. Does nothing if already started.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    // Wait (at most 3 seconds) for the saved settings.
    await voice.settingsProvider.ready.timeout(
      const Duration(seconds: 3),
      onTimeout: () {},
    );
    await _announceCurrentStep();
  }

  /// Moves to the next step and announces it.
  Future<void> next() async {
    if (isArrived) return;
    _index++;
    notifyListeners();
    await _announceCurrentStep();
  }

  /// Goes back to the first step (used to replay the demo).
  Future<void> restart() async {
    _index = 0;
    notifyListeners();
    await _announceCurrentStep();
  }

  /// Says the last instruction again.
  Future<bool> repeat() => voice.replay();

  Future<void> _announceCurrentStep() async {
    final step = currentStep;
    var text = step.spokenText;
    // "Distance updates" switch: add the distance left to the destination.
    final announceDistance = voice.settingsProvider.settings.announceDistance;
    if (announceDistance && hasDistances && !isArrived) {
      text += ' $remainingMetres metres remaining.';
    }

    unawaited(haptic.playCue(step.cue));
    await voice.speakInstruction(text, type: announcementTypeFor(step.cue));

    final alert = step.alert;
    if (alert != null) {
      await alerts.trigger(
        type: alert.type,
        severity: alert.severity,
        message: alert.message,
      );
    }
  }

  /// Which "Announce" switch controls a step with this cue.
  static AnnouncementType announcementTypeFor(HapticCue cue) {
    switch (cue) {
      case HapticCue.turnLeft:
      case HapticCue.turnRight:
      case HapticCue.straight:
        return AnnouncementType.turn;
      case HapticCue.crossing:
        return AnnouncementType.crossing;
      case HapticCue.obstacle:
        return AnnouncementType.obstacle;
      case HapticCue.arrival:
        return AnnouncementType.arrival;
    }
  }
}
