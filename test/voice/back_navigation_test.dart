import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:it3060_wd04_navassist_app/screens/voice/accessibility_settings_screen.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/data/voice_settings_provider.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/theme/voice_theme.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/voice_routes.dart';

import 'recording_repository.dart';

// Widget tests for the "< Back" button in VoiceHeader (DEVIATIONS N1):
// - a screen opened on top of another goes back to it;
// - a screen opened directly (nothing underneath) goes to Active Navigation.
// A simple stand-in is used for Active Navigation, so only Back is tested.

Widget buildApp(String startAt) {
  return ChangeNotifierProvider.value(
    value: VoiceSettingsProvider(repository: RecordingRepository()),
    child: MaterialApp.router(
      theme: VoiceTheme.build(VoicePalette.normal),
      routerConfig: GoRouter(
        initialLocation: startAt,
        routes: [
          GoRoute(
            path: VoiceRoutes.activeNavigation,
            builder: (context, state) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => context.push(VoiceRoutes.accessibility),
                  child: const Text('Active Navigation stand-in'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: VoiceRoutes.accessibility,
            builder: (context, state) => const AccessibilitySettingsScreen(),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('Back on a screen opened directly goes to Active Navigation', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(VoiceRoutes.accessibility));
    await tester.pumpAndSettle();
    expect(find.text('Accessibility'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Active Navigation stand-in'), findsOneWidget);
    expect(find.text('Accessibility'), findsNothing);
  });

  testWidgets('Back on a pushed screen returns to the screen underneath', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(VoiceRoutes.activeNavigation));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Active Navigation stand-in'));
    await tester.pumpAndSettle();
    expect(find.text('Accessibility'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Active Navigation stand-in'), findsOneWidget);
    expect(find.text('Accessibility'), findsNothing);
  });
}
