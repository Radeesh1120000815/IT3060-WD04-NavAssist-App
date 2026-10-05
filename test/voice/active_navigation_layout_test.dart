import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:it3060_wd04_navassist_app/screens/voice/active_navigation_screen.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/data/voice_settings_provider.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/services/alert_service.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/services/command_service.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/services/haptic_service.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/services/navigation_session.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/services/voice_service.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/theme/voice_theme.dart';

// Regression test for the bug found on a real phone (Redmi 9):
// "LayoutBuilder does not support returning intrinsic dimensions".
// Active Navigation showed only a dark blue screen.
//
// No Firebase is started here. Settings are never loaded, so the defaults
// are used. Text-to-speech and vibration have no plugin in tests; the
// services catch that and carry on.

/// Builds Active Navigation with the same providers VoiceShell gives it.
Widget buildScreen({double textScale = 1.0}) {
  final settings = VoiceSettingsProvider();
  final voice = VoiceService(settings);
  final haptic = HapticService(settings);
  final alerts = AlertService(
    settingsProvider: settings,
    voice: voice,
    haptic: haptic,
  );
  final commands = CommandService(settings);
  final session = NavigationSession(
    voice: voice,
    haptic: haptic,
    alerts: alerts,
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider.value(value: voice),
      Provider.value(value: haptic),
      ChangeNotifierProvider.value(value: alerts),
      ChangeNotifierProvider.value(value: commands),
      ChangeNotifierProvider.value(value: session),
    ],
    // A one-route GoRouter, because the screen's Back button asks GoRouter.
    child: MaterialApp.router(
      theme: VoiceTheme.build(VoicePalette.normal),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const ActiveNavigationScreen(),
          ),
        ],
      ),
    ),
  );
}

/// Sets a phone-sized screen (Redmi 9: about 393 x 851 logical pixels).
void usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('Active Navigation lays out without errors', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(buildScreen());
    await tester.pump(); // lets the first instruction start

    expect(tester.takeException(), isNull);
    expect(find.text('Central Library'), findsOneWidget);
    expect(find.text('Head north'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Active Navigation lays out with very large text', (
    tester,
  ) async {
    usePhoneSize(tester);
    // Above 1.3x the quick buttons switch to two per row.
    await tester.pumpWidget(buildScreen(textScale: 2.0));
    await tester.pump();
    expect(tester.takeException(), isNull);

    // With big text the white panel is below the screen edge: scroll to it.
    await tester.scrollUntilVisible(find.text('Settings'), 200);
    expect(tester.takeException(), isNull);
    expect(find.text('Central Library'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
