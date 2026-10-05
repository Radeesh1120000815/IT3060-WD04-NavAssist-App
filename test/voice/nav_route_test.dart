import 'package:flutter_test/flutter_test.dart';

import 'package:it3060_wd04_navassist_app/screens/voice/data/haptic_cue.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/data/nav_step.dart';

// Unit tests for reading Member 1's route (NavRoute.fromExtra) and for
// turning one instruction sentence into a step (NavStep.fromText).

void main() {
  group('NavRoute.fromExtra with good data', () {
    test('reads the destination and every instruction in order', () {
      final route = NavRoute.fromExtra({
        'destination': 'Central Library',
        'instructions': [
          'Head north on Maple Street',
          'Turn right onto King Street',
          'Arrive at Central Library',
        ],
      });

      expect(route, isNotNull);
      expect(route!.destination, 'Central Library');
      expect(route.steps.map((s) => s.action).toList(), [
        'Head north on Maple Street',
        'Turn right onto King Street',
        'Arrive at Central Library',
      ]);
      expect(route.steps.map((s) => s.cue).toList(), [
        HapticCue.straight,
        HapticCue.turnRight,
        HapticCue.arrival,
      ]);
    });

    test('trims the destination name', () {
      final route = NavRoute.fromExtra({
        'destination': '  City Park  ',
        'instructions': ['Head north'],
      });
      expect(route!.destination, 'City Park');
    });

    test('a missing or blank destination becomes "your destination"', () {
      expect(
        NavRoute.fromExtra({'instructions': ['Head north']})!.destination,
        'your destination',
      );
      expect(
        NavRoute.fromExtra({
          'destination': '   ',
          'instructions': ['Head north'],
        })!.destination,
        'your destination',
      );
    });

    test('skips blank and non-text instructions but keeps the rest', () {
      final route = NavRoute.fromExtra({
        'destination': 'Central Library',
        'instructions': ['Head north', '', '   ', 42, null, 'Turn left'],
      });
      expect(route!.steps.map((s) => s.action).toList(), [
        'Head north',
        'Turn left',
      ]);
    });
  });

  group('NavRoute.fromExtra with bad data returns null (demo route used)', () {
    test('nothing passed', () {
      expect(NavRoute.fromExtra(null), isNull);
    });

    test('extra is not a map', () {
      expect(NavRoute.fromExtra('Central Library'), isNull);
      expect(NavRoute.fromExtra(['Head north']), isNull);
    });

    test('instructions missing or not a list', () {
      expect(NavRoute.fromExtra({'destination': 'Central Library'}), isNull);
      expect(
        NavRoute.fromExtra({
          'destination': 'Central Library',
          'instructions': 'Head north',
        }),
        isNull,
      );
    });

    test('instructions empty or with no usable text', () {
      expect(NavRoute.fromExtra({'instructions': <String>[]}), isNull);
      expect(NavRoute.fromExtra({'instructions': ['', '  ', 7]}), isNull);
    });
  });

  group('NavStep.fromText', () {
    test('removes spaces and the full stop at the end', () {
      final step = NavStep.fromText('  Turn left onto King Street.  ');
      expect(step.action, 'Turn left onto King Street');
      expect(step.cue, HapticCue.turnLeft);
    });

    test('guesses the vibration cue from the words', () {
      expect(NavStep.fromText('Turn right').cue, HapticCue.turnRight);
      expect(NavStep.fromText('Cross the road').cue, HapticCue.crossing);
      expect(NavStep.fromText('Arrive at Central Library').cue,
          HapticCue.arrival);
      expect(NavStep.fromText('You reached your destination').cue,
          HapticCue.arrival);
      expect(NavStep.fromText('Head north').cue, HapticCue.straight);
    });

    test('has no street or distance, so it is spoken as one sentence', () {
      final step = NavStep.fromText('Head north');
      expect(step.street, '');
      expect(step.distanceMetres, 0);
      expect(step.spokenText, 'Head north.');
    });
  });
}
