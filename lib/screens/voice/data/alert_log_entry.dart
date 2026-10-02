import 'parse_helpers.dart';

/// How serious an alert is (UR-02).
/// high = full-screen alert, low = small banner.
enum AlertSeverity {
  high('high'),
  low('low');

  const AlertSeverity(this.value);

  /// The text saved in Firestore.
  final String value;

  /// Reads the saved text back. Unknown text becomes [high] (the safe choice).
  static AlertSeverity fromValue(String value) =>
      values.firstWhere((s) => s.value == value, orElse: () => high);
}

/// One alert that was shown to the user, e.g. "Obstacle ahead".
/// Stored in settings/{uid}/alert_log.
class AlertLogEntry {
  final String id; // Firestore document id
  final String type; // e.g. 'obstacle', 'crossing', 'hazard'
  final AlertSeverity severity;
  final String message;
  final DateTime? firedAt; // set by the server
  final bool acknowledged; // true once the user dismissed it

  const AlertLogEntry({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    this.firedAt,
    this.acknowledged = false,
  });

  factory AlertLogEntry.fromMap(String id, Map<String, dynamic> map) {
    return AlertLogEntry(
      id: id,
      type: readString(map, 'type', 'obstacle'),
      severity: AlertSeverity.fromValue(readString(map, 'severity', '')),
      message: readString(map, 'message', ''),
      firedAt: readDate(map, 'firedAt'),
      acknowledged: readBool(map, 'acknowledged', false),
    );
  }

  /// firedAt is left out: the repository sets it with a server timestamp.
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'severity': severity.value,
      'message': message,
      'acknowledged': acknowledged,
    };
  }
}
