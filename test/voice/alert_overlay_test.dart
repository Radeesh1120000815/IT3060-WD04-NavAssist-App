import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:it3060_wd04_navassist_app/screens/voice/data/alert_log_entry.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/data/voice_settings_provider.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/services/alert_service.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/services/haptic_service.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/services/voice_service.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/theme/voice_theme.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/widgets/alert_overlay.dart';

import 'fake_plugins.dart';
import 'recording_repository.dart';

// Widget tests for the high-severity alert pop-up (UR-02, UR-03).
// FakePlugins answers the vibration and text-to-speech messages (there is
// no phone in a test) and records them, so Dismiss can be checked to
// really stop the vibration and the voice.

class _Setup {
  _Setup() {
    settings = VoiceSettingsProvider(repository: repository);
    final voice = VoiceService(settings);
    alerts = AlertService(
      settingsProvider: settings,
      voice: voice,
      haptic: HapticService(settings),
    );
  }

  final repository = RecordingRepository();
  late final VoiceSettingsProvider settings;
  late final AlertService alerts;

  /// A screen with the alert overlay on top, like VoiceShell builds it.
  Widget buildApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: alerts),
      ],
      child: MaterialApp.router(
        theme: VoiceTheme.build(VoicePalette.normal),
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const Stack(
                children: [
                  Scaffold(body: Center(child: Text('Screen underneath'))),
                  AlertOverlay(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> fireHighAlert(WidgetTester tester) async {
    await alerts.trigger(
      type: 'obstacle',
      severity: AlertSeverity.high,
      message: 'Obstacle ahead',
    );
    await tester.pumpAndSettle();
  }
}

void main() {
  final plugins = FakePlugins();
  setUp(plugins.install);
  tearDown(plugins.uninstall);

  testWidgets('High alert shows full screen and Dismiss closes it', (
    tester,
  ) async {
    final setup = _Setup();
    await tester.pumpWidget(setup.buildApp());
    await setup.fireHighAlert(tester);

    expect(find.text('WARNING'), findsOneWidget);
    expect(find.text('OBSTACLE AHEAD'), findsOneWidget);
    expect(setup.repository.loggedAlerts, ['Obstacle ahead']); // CREATE
    expect(plugins.ttsCalls, contains('speak')); // the warning was spoken

    plugins.vibrationCalls.clear();
    plugins.ttsCalls.clear();
    await tester.tap(find.text('Dismiss alert'));
    await tester.pumpAndSettle();

    expect(find.text('OBSTACLE AHEAD'), findsNothing);
    expect(setup.alerts.currentAlert, isNull);
    expect(find.text('Screen underneath'), findsOneWidget);
    expect(setup.repository.acknowledgedIds, ['alert-1']); // UPDATE
    expect(plugins.vibrationCalls, contains('cancel')); // vibration stopped
    expect(plugins.ttsCalls, contains('stop')); // voice stopped
  });

  testWidgets('Phone Back button works like Dismiss on a high alert', (
    tester,
  ) async {
    final setup = _Setup();
    await tester.pumpWidget(setup.buildApp());
    await setup.fireHighAlert(tester);
    expect(find.text('OBSTACLE AHEAD'), findsOneWidget);

    // Same as pressing the Android Back button.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('OBSTACLE AHEAD'), findsNothing);
    expect(find.text('Screen underneath'), findsOneWidget);
    expect(setup.repository.acknowledgedIds, ['alert-1']);
  });
}
