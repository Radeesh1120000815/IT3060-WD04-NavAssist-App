import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'data/custom_command.dart';
import 'data/voice_settings_provider.dart';
import 'services/alert_service.dart';
import 'services/command_service.dart';
import 'services/haptic_service.dart';
import 'services/navigation_session.dart';
import 'services/voice_service.dart';
import 'theme/voice_theme.dart';
import 'voice_routes.dart';
import 'widgets/alert_overlay.dart';
import 'widgets/voice_widgets.dart';

/// Wraps every Member 2 screen (see the ShellRoute in voice_routes.dart).
///
/// It:
/// 1. creates the settings and services once and shares them with
///    `provider`, so all my screens use the same ones;
/// 2. applies Large text, High contrast and Reduce motion (UR-04);
/// 3. shows alert pop-ups over any of my screens (UR-02);
/// 4. carries out recognised voice commands.
///
/// This keeps my part working without editing the shared main.dart.
class VoiceShell extends StatefulWidget {
  const VoiceShell({super.key, required this.child});

  /// The current screen, given by GoRouter.
  final Widget child;

  @override
  State<VoiceShell> createState() => _VoiceShellState();
}

class _VoiceShellState extends State<VoiceShell> {
  late final VoiceSettingsProvider _settings;
  late final VoiceService _voice;
  late final HapticService _haptic;
  late final AlertService _alerts;
  late final CommandService _commands;
  late final NavigationSession _session;

  @override
  void initState() {
    super.initState();
    _settings = VoiceSettingsProvider()..load();
    _voice = VoiceService(_settings);
    _haptic = HapticService(_settings);
    _alerts = AlertService(
      settingsProvider: _settings,
      voice: _voice,
      haptic: _haptic,
    );
    _commands = CommandService(_settings)..onCommand = _onVoiceCommand;
    _session = NavigationSession(
      voice: _voice,
      haptic: _haptic,
      alerts: _alerts,
    );
  }

  // Carries out a recognised voice command.
  void _onVoiceCommand(CommandAction action) {
    switch (action) {
      case CommandAction.repeat:
        _session.repeat();
      case CommandAction.next:
        _session.next();
      case CommandAction.settings:
        _openSettingsFromVoice();
      case CommandAction.stop:
        _voice.stop();
        _haptic.stop();
    }
  }

  // "settings" command: pause listening while Accessibility is open, then
  // listen again when the user comes back to the Voice Command screen.
  Future<void> _openSettingsFromVoice() async {
    final wasListening = _commands.isKeepingListening;
    await _commands.stopListening();
    if (!mounted) return;
    // push() finishes when the Accessibility screen is closed.
    await GoRouter.of(context).push(VoiceRoutes.accessibility);
    if (mounted && wasListening) await _commands.startListening();
  }

  @override
  void dispose() {
    _session.dispose();
    _commands.dispose();
    _alerts.dispose();
    _haptic.stop();
    _voice.dispose();
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _settings),
        ChangeNotifierProvider.value(value: _voice),
        Provider.value(value: _haptic),
        ChangeNotifierProvider.value(value: _alerts),
        ChangeNotifierProvider.value(value: _commands),
        ChangeNotifierProvider.value(value: _session),
      ],
      child: VoiceAccessibilityScope(
        // Own ScaffoldMessenger so messages use our theme.
        child: ScaffoldMessenger(
          child: Scaffold(
            body: Stack(children: [widget.child, const AlertOverlay()]),
            bottomNavigationBar: const TabBarPlaceholder(),
          ),
        ),
      ),
    );
  }
}

/// Applies the user's accessibility settings to everything below it (UR-04):
/// - Large text: text 1.3x bigger, on top of the phone's own text size.
/// - High contrast: switches to the high-contrast colours.
/// - Reduce motion: turns animations off (read with `motion(context, ...)`).
class VoiceAccessibilityScope extends StatelessWidget {
  const VoiceAccessibilityScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<VoiceSettingsProvider>().settings;
    final media = MediaQuery.of(context);

    final textScaler = settings.largeText
        ? TextScaler.linear(
            media.textScaler.scale(1) * VoiceTheme.largeTextFactor,
          )
        : media.textScaler;
    final palette = settings.highContrast
        ? VoicePalette.highContrast
        : VoicePalette.normal;

    return MediaQuery(
      data: media.copyWith(
        textScaler: textScaler,
        disableAnimations: media.disableAnimations || settings.reduceMotion,
      ),
      child: Theme(data: VoiceTheme.build(palette), child: child),
    );
  }
}
