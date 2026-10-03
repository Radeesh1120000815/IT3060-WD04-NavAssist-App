import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:it3060_wd04_navassist_app/screens/voice/data/alert_log_entry.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/data/custom_command.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/data/instruction_feedback.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/data/voice_repository.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/data/voice_settings.dart';

// Unit tests for every CRUD method in VoiceRepository.
//
// FakeFirebaseFirestore is an in-memory Firestore (package
// fake_cloud_firestore), so nothing touches the real database.
// Firebase Auth is replaced by a tiny fake that always has the user
// "test-uid" signed in.

const uid = 'test-uid';

class _FakeUser extends Fake implements User {
  @override
  String get uid => 'test-uid';
}

class _FakeUserCredential extends Fake implements UserCredential {
  @override
  User? get user => _FakeUser();
}

/// Signed in as test-uid, or (signedIn: false) nobody signed in yet.
class _FakeAuth extends Fake implements FirebaseAuth {
  _FakeAuth({this.signedIn = true});

  bool signedIn;
  int anonymousSignIns = 0;

  @override
  User? get currentUser => signedIn ? _FakeUser() : null;

  @override
  Future<UserCredential> signInAnonymously() async {
    anonymousSignIns++;
    signedIn = true;
    return _FakeUserCredential();
  }
}

void main() {
  late FakeFirebaseFirestore db;
  late VoiceRepository repository;

  setUp(() {
    db = FakeFirebaseFirestore();
    repository = VoiceRepository(firestore: db, auth: _FakeAuth());
  });

  // Reads a raw document straight from the fake database.
  Future<Map<String, dynamic>?> rawSettings() async =>
      (await db.collection('settings').doc(uid).get()).data();

  Future<int> countIn(String subCollection) async => (await db
          .collection('settings')
          .doc(uid)
          .collection(subCollection)
          .get())
      .docs
      .length;

  // ---------------------------------------------------------------------
  group('user id', () {
    test('uses the signed-in user', () async {
      expect(await repository.currentUserId(), uid);
    });

    test('signs in anonymously when nobody is signed in', () async {
      final auth = _FakeAuth(signedIn: false);
      final repo = VoiceRepository(firestore: db, auth: auth);
      expect(await repo.currentUserId(), uid);
      expect(auth.anonymousSignIns, 1);
    });
  });

  // ---------------------------------------------------------------------
  group('settings/{uid}', () {
    test('CREATE: createDefaultSettings saves the defaults', () async {
      await repository.createDefaultSettings();

      final data = await rawSettings();
      expect(data, isNotNull);
      expect(data!['voiceEnabled'], true);
      expect(data['volume'], 0.8);
      expect(data['hapticIntensity'], 'medium');
      expect(data['wakePhrase'], 'hey navassist');
      expect(data['createdAt'], isNotNull);
      expect(data['updatedAt'], isNotNull);
    });

    test('READ: getSettings creates the defaults the first time', () async {
      expect(await rawSettings(), isNull);

      final settings = await repository.getSettings();

      expect(settings.volume, 0.8);
      expect(settings.speechRate, 1.0);
      expect(await rawSettings(), isNotNull); // document now exists
    });

    test('READ: getSettings returns saved values', () async {
      await db.collection('settings').doc(uid).set({
        'volume': 0.3,
        'speechRate': 1.5,
        'largeText': true,
        'hapticIntensity': 'strong',
      });

      final settings = await repository.getSettings();

      expect(settings.volume, 0.3);
      expect(settings.speechRate, 1.5);
      expect(settings.largeText, true);
      expect(settings.hapticIntensity, HapticIntensity.strong);
      expect(settings.voiceEnabled, true); // missing field -> default
    });

    test('READ: bad stored values fall back to safe defaults', () async {
      await db.collection('settings').doc(uid).set({
        'volume': 5, // too loud -> clamped to 1.0
        'speechRate': 3.0, // not an allowed speed -> 1.0
        'hapticIntensity': 'extreme', // unknown -> medium
        'voiceEnabled': 'yes', // wrong type -> default true
        'wakePhrase': '   ', // blank -> default
      });

      final settings = await repository.getSettings();

      expect(settings.volume, 1.0);
      expect(settings.speechRate, 1.0);
      expect(settings.hapticIntensity, HapticIntensity.medium);
      expect(settings.voiceEnabled, true);
      expect(settings.wakePhrase, 'hey navassist');
    });

    test('UPDATE: updateSettings saves the changed values', () async {
      await repository.createDefaultSettings();

      await repository.updateSettings(
        const VoiceSettings(volume: 0.5, highContrast: true, speechRate: 1.25),
      );

      final settings = await repository.getSettings();
      expect(settings.volume, 0.5);
      expect(settings.highContrast, true);
      expect(settings.speechRate, 1.25);
      expect((await rawSettings())!['updatedAt'], isNotNull);
    });

    test('UPDATE: updateSettings also works before the document exists',
        () async {
      await repository.updateSettings(const VoiceSettings(reduceMotion: true));
      expect((await rawSettings())!['reduceMotion'], true);
    });

    test('READ (live): watchSettings sends the new value after an update',
        () async {
      await repository.createDefaultSettings();
      final stream = repository.watchSettings();

      expect((await stream.first).largeText, false);
      await repository.updateSettings(const VoiceSettings(largeText: true));
      expect((await repository.watchSettings().first).largeText, true);
    });

    test('DELETE + CREATE: resetToDefault restores every default', () async {
      await repository.updateSettings(
        const VoiceSettings(volume: 0.1, largeText: true, wakePhrase: 'hello'),
      );

      final result = await repository.resetToDefault();

      expect(result.volume, 0.8);
      final settings = await repository.getSettings();
      expect(settings.volume, 0.8);
      expect(settings.largeText, false);
      expect(settings.wakePhrase, 'hey navassist');
    });

    // SKIPPED on purpose: fake_cloud_firestore 3.1.0 deletes a document's
    // sub-collections together with it (its delete() removes the whole
    // node). Real Firestore keeps them. So this cannot be checked with the
    // fake; it is checked by hand on the phone instead (see TEST_CASES.md).
    test(
      'resetToDefault keeps the sub-collections (history etc.)',
      () async {
        await repository.addInstructionHistory('Head north');
        await repository.resetToDefault();
        expect(await countIn('instruction_history'), 1);
      },
      skip: 'fake_cloud_firestore deletes sub-collections with their parent; '
          'real Firestore does not. Checked manually on the phone.',
    );
  });

  // ---------------------------------------------------------------------
  group('settings/{uid}/instruction_history', () {
    test('CREATE: addInstructionHistory saves the text and the time',
        () async {
      final id = await repository.addInstructionHistory('Turn left');

      final doc = await db
          .collection('settings')
          .doc(uid)
          .collection('instruction_history')
          .doc(id)
          .get();
      expect(doc.data()!['text'], 'Turn left');
      expect(doc.data()!['spokenAt'], isNotNull);
    });

    test('READ (live): watchInstructionHistory lists the entries', () async {
      await repository.addInstructionHistory('Head north');
      await repository.addInstructionHistory('Turn right');

      final entries = await repository.watchInstructionHistory().first;

      expect(entries.map((e) => e.text),
          containsAll(['Head north', 'Turn right']));
      expect(entries.every((e) => e.spokenAt != null), isTrue);
    });

    test('READ (live): the limit is respected', () async {
      for (var i = 0; i < 5; i++) {
        await repository.addInstructionHistory('Step $i');
      }
      final entries =
          await repository.watchInstructionHistory(limit: 3).first;
      expect(entries.length, 3);
    });

    test('DELETE: clearInstructionHistory removes every entry', () async {
      await repository.addInstructionHistory('Head north');
      await repository.addInstructionHistory('Turn right');

      await repository.clearInstructionHistory();

      expect(await countIn('instruction_history'), 0);
      expect(await repository.watchInstructionHistory().first, isEmpty);
    });
  });

  // ---------------------------------------------------------------------
  group('settings/{uid}/custom_commands', () {
    test('CREATE: addCustomCommand saves a cleaned phrase', () async {
      await repository.addCustomCommand('  Say AGAIN ', CommandAction.repeat);

      final commands = await repository.getCustomCommands();
      expect(commands.length, 1);
      expect(commands.first.phrase, 'say again');
      expect(commands.first.action, CommandAction.repeat);
      expect(commands.first.enabled, true);
    });

    test('CREATE: an empty phrase is refused and nothing is saved',
        () async {
      await expectLater(
        repository.addCustomCommand('   ', CommandAction.next),
        throwsA(isA<VoiceDataException>()),
      );
      expect(await countIn('custom_commands'), 0);
    });

    test('READ: getCustomCommands and watchCustomCommands list them',
        () async {
      await repository.addCustomCommand('say again', CommandAction.repeat);
      await repository.addCustomCommand('go on', CommandAction.next);

      final once = await repository.getCustomCommands();
      final live = await repository.watchCustomCommands().first;

      expect(once.map((c) => c.phrase), containsAll(['say again', 'go on']));
      expect(live.length, 2);
    });

    test('UPDATE: updateCustomCommand changes phrase, action and on/off',
        () async {
      await repository.addCustomCommand('say again', CommandAction.repeat);
      final original = (await repository.getCustomCommands()).first;

      await repository.updateCustomCommand(
        original.copyWith(
          phrase: ' Go ON ',
          action: CommandAction.next,
          enabled: false,
        ),
      );

      final updated = (await repository.getCustomCommands()).first;
      expect(updated.id, original.id);
      expect(updated.phrase, 'go on');
      expect(updated.action, CommandAction.next);
      expect(updated.enabled, false);
    });

    test('UPDATE: an empty phrase is refused', () async {
      await repository.addCustomCommand('say again', CommandAction.repeat);
      final original = (await repository.getCustomCommands()).first;

      await expectLater(
        repository.updateCustomCommand(original.copyWith(phrase: ' ')),
        throwsA(isA<VoiceDataException>()),
      );
      expect((await repository.getCustomCommands()).first.phrase,
          'say again');
    });

    test('DELETE: deleteCustomCommand removes only that command', () async {
      await repository.addCustomCommand('say again', CommandAction.repeat);
      await repository.addCustomCommand('go on', CommandAction.next);
      final sayAgain = (await repository.getCustomCommands())
          .firstWhere((c) => c.phrase == 'say again');

      await repository.deleteCustomCommand(sayAgain.id);

      final left = await repository.getCustomCommands();
      expect(left.map((c) => c.phrase), ['go on']);
    });
  });

  // ---------------------------------------------------------------------
  group('settings/{uid}/alert_log', () {
    test('CREATE: logAlert saves type, severity, message, not dismissed',
        () async {
      await repository.logAlert(
        type: 'obstacle',
        severity: AlertSeverity.high,
        message: 'Obstacle ahead',
      );

      final log = await repository.watchAlertLog().first;
      expect(log.length, 1);
      expect(log.first.type, 'obstacle');
      expect(log.first.severity, AlertSeverity.high);
      expect(log.first.message, 'Obstacle ahead');
      expect(log.first.acknowledged, false);
      expect(log.first.firedAt, isNotNull);
    });

    test('UPDATE: acknowledgeAlert marks the alert as dismissed', () async {
      final id = await repository.logAlert(
        type: 'hazard',
        severity: AlertSeverity.low,
        message: 'Broken pavement',
      );

      await repository.acknowledgeAlert(id);

      final log = await repository.watchAlertLog().first;
      expect(log.single.acknowledged, true);
    });

    test('DELETE: clearAlertLog removes every alert', () async {
      await repository.logAlert(
        type: 'obstacle',
        severity: AlertSeverity.high,
        message: 'Obstacle ahead',
      );
      await repository.logAlert(
        type: 'hazard',
        severity: AlertSeverity.low,
        message: 'Broken pavement',
      );

      await repository.clearAlertLog();

      expect(await countIn('alert_log'), 0);
    });
  });

  // ---------------------------------------------------------------------
  group('settings/{uid}/feedback', () {
    test('CREATE: addFeedback saves the instruction and the status',
        () async {
      await repository.addFeedback('Head north', FeedbackStatus.onTrack);

      final raw = await db
          .collection('settings')
          .doc(uid)
          .collection('feedback')
          .get();
      expect(raw.docs.single.data()['status'], 'on_track');

      final list = await repository.watchFeedback().first;
      expect(list.single.instruction, 'Head north');
      expect(list.single.status, FeedbackStatus.onTrack);
      expect(list.single.createdAt, isNotNull);
    });

    test('UPDATE: updateFeedback changes the status', () async {
      final id =
          await repository.addFeedback('Turn left', FeedbackStatus.onTrack);

      await repository.updateFeedback(id, FeedbackStatus.unclear);

      final list = await repository.watchFeedback().first;
      expect(list.single.status, FeedbackStatus.unclear);
    });

    test('DELETE: deleteFeedback removes only that entry', () async {
      final keep =
          await repository.addFeedback('Head north', FeedbackStatus.onTrack);
      final remove =
          await repository.addFeedback('Turn left', FeedbackStatus.unclear);

      await repository.deleteFeedback(remove);

      final list = await repository.watchFeedback().first;
      expect(list.map((f) => f.id), [keep]);
    });

    test('UPDATE of a deleted entry gives a friendly error', () async {
      final id =
          await repository.addFeedback('Head north', FeedbackStatus.onTrack);
      await repository.deleteFeedback(id);

      await expectLater(
        repository.updateFeedback(id, FeedbackStatus.unclear),
        throwsA(isA<VoiceDataException>()),
      );
    });
  });

  // ---------------------------------------------------------------------
  test('all data is stored under settings/{uid} for the signed-in user',
      () async {
    await repository.createDefaultSettings();
    await repository.addInstructionHistory('Head north');
    await repository.addCustomCommand('say again', CommandAction.repeat);
    await repository.logAlert(
      type: 'obstacle',
      severity: AlertSeverity.high,
      message: 'Obstacle ahead',
    );
    await repository.addFeedback('Head north', FeedbackStatus.onTrack);

    final topLevel = await db.collection('settings').get();
    expect(topLevel.docs.map((d) => d.id), [uid]);
    expect(await countIn('instruction_history'), 1);
    expect(await countIn('custom_commands'), 1);
    expect(await countIn('alert_log'), 1);
    expect(await countIn('feedback'), 1);
  });
}
