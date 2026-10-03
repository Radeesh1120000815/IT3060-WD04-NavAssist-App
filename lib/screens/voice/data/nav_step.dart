import 'alert_log_entry.dart';
import 'haptic_cue.dart';

/// An alert that fires when a step is reached (used by the demo route).
class StepAlert {
  const StepAlert({
    required this.type,
    required this.severity,
    required this.message,
  });

  final String type; // 'obstacle', 'crossing' or 'hazard'
  final AlertSeverity severity;
  final String message;
}

/// One navigation instruction, e.g. "Head north" + "on Maple Street", 120 m.
/// Kept in memory only (not saved to Firestore).
class NavStep {
  const NavStep({
    required this.action,
    this.street = '',
    this.distanceMetres = 0,
    this.cue = HapticCue.straight,
    this.alert,
  });

  /// Builds a step from plain text sent by Member 1, e.g. "Turn left onto
  /// King Street". The vibration cue is guessed from the words.
  factory NavStep.fromText(String text) {
    final clean = text.trim().replaceAll(RegExp(r'[.!]+$'), '');
    return NavStep(action: clean, cue: guessCue(clean));
  }

  final String action; // "Head north"
  final String street; // "on Maple Street" (can be empty)
  final int distanceMetres; // 0 = unknown
  final HapticCue cue; // vibration played with this step
  final StepAlert? alert; // optional alert when this step is reached

  /// "Head north on Maple Street"
  String get displayText => street.isEmpty ? action : '$action $street';

  /// "Head north on Maple Street, 120 metres."
  String get spokenText => distanceMetres > 0
      ? '$displayText, $distanceMetres metres.'
      : '$displayText.';

  /// "Head north on Maple Street, 120 m" (for the preview card)
  String get previewText =>
      distanceMetres > 0 ? '$displayText, $distanceMetres m' : displayText;

  /// Picks a vibration cue from the words in an instruction.
  static HapticCue guessCue(String text) {
    final t = text.toLowerCase();
    if (t.contains('cross')) return HapticCue.crossing;
    if (t.contains('left')) return HapticCue.turnLeft;
    if (t.contains('right')) return HapticCue.turnRight;
    if (t.contains('arriv') || t.contains('destination')) {
      return HapticCue.arrival;
    }
    return HapticCue.straight;
  }
}

/// A whole route: where we are going and the steps to get there.
class NavRoute {
  const NavRoute({required this.destination, required this.steps});

  final String destination;
  final List<NavStep> steps;

  /// Reads the route that Member 1's Start Navigation screen passes in
  /// GoRouter's `extra`:
  ///   {'destination': 'Central Library', 'instructions': ['Head north', ...]}
  /// Returns null if nothing usable was passed (then the demo route is used).
  static NavRoute? fromExtra(Object? extra) {
    if (extra is! Map) return null;
    final destination = extra['destination'];
    final instructions = extra['instructions'];
    if (instructions is! List) return null;

    final steps = [
      for (final item in instructions)
        if (item is String && item.trim().isNotEmpty) NavStep.fromText(item),
    ];
    if (steps.isEmpty) return null;

    final name = destination is String && destination.trim().isNotEmpty
        ? destination.trim()
        : 'your destination';
    return NavRoute(destination: name, steps: steps);
  }
}
