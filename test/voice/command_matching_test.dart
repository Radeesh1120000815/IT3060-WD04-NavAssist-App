import 'package:flutter_test/flutter_test.dart';

import 'package:it3060_wd04_navassist_app/screens/voice/data/custom_command.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/services/command_service.dart';

// Unit tests for the voice command matching in CommandService.
// These are pure functions: no microphone, no Firebase.

void main() {
  const wake = 'hey navassist';

  group('normalise', () {
    test('makes lower case, removes punctuation and extra spaces', () {
      expect(CommandService.normalise('  Hey,   NavAssist!  '), 'hey navassist');
    });
  });

  group('removeWakePhrase', () {
    test('returns the words after the wake phrase', () {
      expect(
        CommandService.removeWakePhrase('Hey NavAssist, open settings', wake),
        'open settings',
      );
    });

    test('ignores capitals and spaces inside the wake phrase', () {
      expect(CommandService.removeWakePhrase('HEY NAV ASSIST repeat', wake),
          'repeat');
      expect(CommandService.removeWakePhrase('heynavassist repeat', wake),
          'repeat');
    });

    test('returns null when the wake phrase was not said', () {
      expect(CommandService.removeWakePhrase('hello there repeat', wake),
          isNull);
    });
  });

  group('matchCommand with the wake phrase on', () {
    test('finds each built-in command after the wake phrase', () {
      expect(CommandService.matchCommand('Hey NavAssist, repeat',
          wakePhrase: wake), CommandAction.repeat);
      expect(CommandService.matchCommand('hey nav assist next',
          wakePhrase: wake), CommandAction.next);
      expect(CommandService.matchCommand('heynavassist settings',
          wakePhrase: wake), CommandAction.settings);
      expect(CommandService.matchCommand('Hey NavAssist stop',
          wakePhrase: wake), CommandAction.stop);
    });

    test('ignores a command without the wake phrase', () {
      expect(CommandService.matchCommand('repeat', wakePhrase: wake), isNull);
    });

    test('returns null when only the wake phrase is said', () {
      expect(CommandService.matchCommand('hey navassist', wakePhrase: wake),
          isNull);
    });
  });

  group('matchCommand with the wake phrase off', () {
    test('finds a command anywhere in the sentence', () {
      expect(CommandService.matchCommand('please repeat that'),
          CommandAction.repeat);
    });

    test('matches whole words only ("nexus" is not "next")', () {
      expect(CommandService.matchCommand('nexus'), isNull);
    });

    test('returns null for empty or unknown speech', () {
      expect(CommandService.matchCommand(''), isNull);
      expect(CommandService.matchCommand('good morning'), isNull);
    });
  });

  group('matchCommand with custom commands', () {
    const sayAgain = CustomCommand(
      id: '1',
      phrase: 'say again',
      action: CommandAction.repeat,
    );
    const stopTalking = CustomCommand(
      id: '2',
      phrase: 'stop talking',
      action: CommandAction.repeat,
    );
    const disabled = CustomCommand(
      id: '3',
      phrase: 'go on',
      action: CommandAction.next,
      enabled: false,
    );

    test('finds a custom phrase', () {
      expect(
        CommandService.matchCommand('hey navassist say again',
            wakePhrase: wake, customCommands: [sayAgain]),
        CommandAction.repeat,
      );
    });

    test('a custom phrase is checked before the built-in words', () {
      // "stop talking" contains the built-in word "stop", but the custom
      // command (repeat) must win.
      expect(
        CommandService.matchCommand('stop talking',
            customCommands: [stopTalking]),
        CommandAction.repeat,
      );
    });

    test('a switched-off custom command is ignored', () {
      expect(
        CommandService.matchCommand('go on', customCommands: [disabled]),
        isNull,
      );
    });
  });
}
