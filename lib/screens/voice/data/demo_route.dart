import 'alert_log_entry.dart';
import 'haptic_cue.dart';
import 'nav_step.dart';

/// Demo route used until Member 1's route data is passed in.
/// It matches the hi-fi design: Maple Street -> King Street -> Central
/// Library, 600 m in total (about 9 minutes on foot).
///
/// Two steps also fire alerts, so every alert type can be shown:
/// step 2 = low-severity hazard banner, step 4 = high-severity obstacle.
const NavRoute demoRoute = NavRoute(
  destination: 'Central Library',
  steps: [
    NavStep(
      action: 'Head north',
      street: 'on Maple Street',
      distanceMetres: 120,
      cue: HapticCue.straight,
    ),
    NavStep(
      action: 'Turn right',
      street: 'onto King Street',
      distanceMetres: 150,
      cue: HapticCue.turnRight,
      alert: StepAlert(
        type: 'hazard',
        severity: AlertSeverity.low,
        message: 'Hazard reported nearby, broken pavement in 80 m',
      ),
    ),
    NavStep(
      action: 'Cross the road',
      street: 'at the King Street crossing',
      distanceMetres: 30,
      cue: HapticCue.crossing,
    ),
    NavStep(
      action: 'Continue straight',
      street: 'on King Street',
      distanceMetres: 150,
      cue: HapticCue.straight,
      alert: StepAlert(
        type: 'obstacle',
        severity: AlertSeverity.high,
        message: 'Obstacle ahead',
      ),
    ),
    NavStep(
      action: 'Turn left',
      street: 'onto Library Lane',
      distanceMetres: 150,
      cue: HapticCue.turnLeft,
    ),
    NavStep(
      action: 'Arrive at',
      street: 'Central Library',
      cue: HapticCue.arrival,
    ),
  ],
);
