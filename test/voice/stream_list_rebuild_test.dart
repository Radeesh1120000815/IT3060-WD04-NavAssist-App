import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:it3060_wd04_navassist_app/screens/voice/data/alert_log_entry.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/data/custom_command.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/data/instruction_feedback.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/data/instruction_history_entry.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/data/voice_repository.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/data/voice_settings_provider.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/haptic_alerts_screen.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/instruction_feedback_screen.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/services/alert_service.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/services/command_service.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/services/haptic_service.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/services/navigation_session.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/services/voice_service.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/theme/voice_theme.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/voice_command_screen.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/voice_guidance_screen.dart';

// Regression test for the bug found on a real phone (Redmi 9):
// "Bad state: Stream has already been listened to" in the lists.
//
// A ListView throws away items that scroll far off screen and builds them
// again when they come back. Each time, the list widget must be able to
// listen to its data again.

/// A repository with no Firebase. Each list is one fixed item.
/// Like the real repository, the streams come from `async*` functions,
/// so each stream can only be listened to once.
class FakeRepository extends VoiceRepository {
  @override
  Stream<List<InstructionHistoryEntry>> watchInstructionHistory({
    int limit = 20,
  }) async* {
    yield [const InstructionHistoryEntry(id: 'h1', text: 'History item one')];
  }

  @override
  Stream<List<CustomCommand>> watchCustomCommands() async* {
    yield [
      const CustomCommand(
        id: 'c1',
        phrase: 'say again',
        action: CommandAction.repeat,
      ),
    ];
  }

  @override
  Future<List<CustomCommand>> getCustomCommands() async => [];

  @override
  Stream<List<AlertLogEntry>> watchAlertLog() async* {
    yield [
      const AlertLogEntry(
        id: 'a1',
        type: 'obstacle',
        severity: AlertSeverity.high,
        message: 'Logged alert one',
      ),
    ];
  }

  @override
  Stream<List<InstructionFeedback>> watchFeedback() async* {
    yield [
      const InstructionFeedback(
        id: 'f1',
        instruction: 'Feedback item one',
        status: FeedbackStatus.onTrack,
      ),
    ];
  }
}

/// Builds [screen] with the same providers VoiceShell gives it.
Widget buildApp(Widget screen) {
  final settings = VoiceSettingsProvider(repository: FakeRepository());
  final voice = VoiceService(settings);
  final haptic = HapticService(settings);
  final alerts = AlertService(
    settingsProvider: settings,
    voice: voice,
    haptic: haptic,
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider.value(value: voice),
      Provider.value(value: haptic),
      ChangeNotifierProvider.value(value: alerts),
      ChangeNotifierProvider.value(value: CommandService(settings)),
      ChangeNotifierProvider.value(
        value: NavigationSession(voice: voice, haptic: haptic, alerts: alerts),
      ),
    ],
    // A one-route GoRouter, because the Back button asks GoRouter.
    child: MaterialApp.router(
      theme: VoiceTheme.build(VoicePalette.normal),
      routerConfig: GoRouter(
        routes: [GoRoute(path: '/', builder: (context, state) => screen)],
      ),
    ),
  );
}

/// Scrolls down to [item], back to the top (so the list is thrown away),
/// and down again (so it is built again). No error may appear.
Future<void> scrollAwayAndBack(WidgetTester tester, Finder item) async {
  final list = find.byType(Scrollable).first;

  await tester.scrollUntilVisible(item, 200, scrollable: list);
  await tester.pump();
  expect(item, findsOneWidget);

  await tester.drag(list, const Offset(0, 5000)); // back to the top
  await tester.pump();
  expect(item, findsNothing); // the list item really was thrown away

  await tester.scrollUntilVisible(item, 200, scrollable: list);
  await tester.pump();
  expect(tester.takeException(), isNull);
  expect(item, findsOneWidget);
}

void main() {
  // A small screen, so the lists are far enough off screen to be thrown away.
  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1080, 1100);
    view.devicePixelRatio = 2.75;
  });
  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.reset();
  });

  testWidgets('Voice Command: custom commands list survives scrolling', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(const VoiceCommandScreen()));
    await tester.pump();
    await scrollAwayAndBack(tester, find.text('"say again"'));
  });

  testWidgets('Voice Guidance: instruction history survives scrolling', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(const VoiceGuidanceScreen()));
    await tester.pump();
    await scrollAwayAndBack(tester, find.text('History item one'));
  });

  testWidgets('Haptic Alerts: alert log survives scrolling', (tester) async {
    await tester.pumpWidget(buildApp(const HapticAlertsScreen()));
    await tester.pump();
    await scrollAwayAndBack(tester, find.text('Logged alert one'));
  });

  testWidgets('Instruction Feedback: recent feedback survives scrolling', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(const InstructionFeedbackScreen()));
    await tester.pump();
    await scrollAwayAndBack(tester, find.text('Feedback item one'));
  });
}
