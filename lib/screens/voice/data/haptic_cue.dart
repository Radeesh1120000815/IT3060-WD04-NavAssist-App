/// The six vibration patterns shown on the Haptic Alerts screen (UR-03).
///
/// A pattern is a list of milliseconds: [wait, buzz, wait, buzz, ...].
/// Short buzzes (150 ms or less) feel like a tap; long ones (500 ms or more)
/// feel like a hum, so each cue can be told apart without looking.
enum HapticCue {
  turnLeft('Turn left', '1 short pulse', [0, 150]),
  turnRight('Turn right', '2 short pulses', [0, 150, 150, 150]),
  straight('Continue straight', '1 long pulse', [0, 600]),
  obstacle('Obstacle ahead', '3 rapid pulses', [0, 100, 80, 100, 80, 100]),
  crossing('Road crossing', 'Long-short-long', [0, 500, 150, 150, 150, 500]),
  arrival('Arrival', '3 strong pulses', [0, 300, 200, 300, 200, 300]);

  const HapticCue(this.label, this.description, this.pattern);

  final String label; // e.g. "Turn left"
  final String description; // e.g. "1 short pulse"
  final List<int> pattern;

  /// Arrival always plays at full strength ("3 strong pulses").
  bool get alwaysStrong => this == arrival;

  /// Only the buzz lengths (every second number), used to draw the pattern.
  List<int> get buzzes => [
    for (var i = 1; i < pattern.length; i += 2) pattern[i],
  ];
}
