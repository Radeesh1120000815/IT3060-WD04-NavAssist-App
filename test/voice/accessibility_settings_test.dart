import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:it3060_wd04_navassist_app/screens/voice/accessibility_settings_screen.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/data/voice_settings.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/data/voice_settings_provider.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/theme/voice_theme.dart';

import 'recording_repository.dart';

// Widget tests for the Accessibility Settings screen (UR-04).

Widget buildApp(VoiceSettingsProvider settings) {
  return ChangeNotifierProvider.value(
    value: settings,
    child: MaterialApp.router(
      theme: VoiceTheme.build(VoicePalette.normal),
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const AccessibilitySettingsScreen(),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('Large text switch turns the setting on and saves it', (
    tester,
  ) async {
    final repository = RecordingRepository();
    final settings = VoiceSettingsProvider(repository: repository);
    await tester.pumpWidget(buildApp(settings));

    expect(settings.settings.largeText, isFalse);
    await tester.tap(find.text('Large text'));
    await tester.pump();

    expect(settings.settings.largeText, isTrue); // shown straight away
    expect(repository.savedSettings.last.largeText, isTrue); // UPDATE sent
    final largeTextSwitch = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Large text'),
    );
    expect(largeTextSwitch.value, isTrue);
  });

  testWidgets('Reset to default asks first; Cancel keeps the settings', (
    tester,
  ) async {
    final repository = RecordingRepository();
    final settings = VoiceSettingsProvider(repository: repository);
    await settings.updateSettings(
      const VoiceSettings(highContrast: true, largeText: true),
    );
    await tester.pumpWidget(buildApp(settings));

    await tester.scrollUntilVisible(find.text('Reset to default'), 200);
    await tester.tap(find.text('Reset to default'));
    await tester.pumpAndSettle();

    // The confirm dialog is shown.
    expect(find.text('Reset to default?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Reset to default?'), findsNothing);
    expect(repository.resetCount, 0);
    expect(settings.settings.highContrast, isTrue);
  });

  testWidgets('Reset to default after confirming restores the defaults', (
    tester,
  ) async {
    final repository = RecordingRepository();
    final settings = VoiceSettingsProvider(repository: repository);
    await settings.updateSettings(
      const VoiceSettings(highContrast: true, largeText: true),
    );
    await tester.pumpWidget(buildApp(settings));

    await tester.scrollUntilVisible(find.text('Reset to default'), 200);
    await tester.tap(find.text('Reset to default'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pumpAndSettle();

    expect(repository.resetCount, 1); // DELETE + CREATE sent
    expect(settings.settings.highContrast, isFalse);
    expect(settings.settings.largeText, isFalse);
    expect(find.text('All settings are back to default.'), findsOneWidget);
  });
}
