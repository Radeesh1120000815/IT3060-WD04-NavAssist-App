import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'data/voice_settings_provider.dart';
import 'theme/voice_theme.dart';
import 'voice_routes.dart';
import 'widgets/voice_widgets.dart';

/// Accessibility Settings (accessibility_settings.png), UR-04.
///
/// Large text, High contrast, Screen reader support and Reduce motion take
/// effect straight away through VoiceAccessibilityScope (voice_shell.dart).
/// Also: links to Haptic Alerts and Voice Command, the emergency contact
/// card (placeholder, see below) and Reset to default.
class AccessibilitySettingsScreen extends StatelessWidget {
  const AccessibilitySettingsScreen({super.key});

  Future<void> _reset(BuildContext context) async {
    final provider = context.read<VoiceSettingsProvider>();
    final ok = await confirmAction(
      context,
      title: 'Reset to default?',
      message:
          'Every voice, vibration, accessibility and voice command setting '
          'goes back to its default. Your history, custom commands and alert '
          'log are kept.',
      confirmLabel: 'Reset',
    );
    if (!ok) return;
    await provider.resetToDefault();
    if (context.mounted) {
      showMessage(
        context,
        provider.errorMessage ?? 'All settings are back to default.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final provider = context.watch<VoiceSettingsProvider>();
    final s = provider.settings;

    Widget toggle(
      String title,
      String subtitle,
      bool value,
      ValueChanged<bool> onChanged,
    ) {
      return Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(subtitle),
            value: value,
            onChanged: onChanged,
          ),
          const Divider(),
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const VoiceHeader(
              title: 'Accessibility',
              subtitle: 'Personalise your navigation experience',
            ),
            if (provider.errorMessage != null)
              NoteText(provider.errorMessage!, icon: Icons.cloud_off),
            toggle(
              'Large text',
              'Increase font size on the navigation and voice screens',
              s.largeText,
              (v) => provider.updateSettings(s.copyWith(largeText: v)),
            ),
            toggle(
              'High contrast',
              'Boost colour contrast for better visibility',
              s.highContrast,
              (v) => provider.updateSettings(s.copyWith(highContrast: v)),
            ),
            toggle(
              'Screen reader support',
              'Optimise for TalkBack: new instructions and alerts are read out',
              s.screenReaderSupport,
              (v) =>
                  provider.updateSettings(s.copyWith(screenReaderSupport: v)),
            ),
            toggle(
              'Reduce motion',
              'Minimise animation and transitions',
              s.reduceMotion,
              (v) => provider.updateSettings(s.copyWith(reduceMotion: v)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.vibration, color: p.primary),
              title: const Text('Haptic alerts'),
              subtitle: const Text('Vibration patterns and alert log'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(VoiceRoutes.hapticAlerts),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.keyboard_voice, color: p.primary),
              title: const Text('Voice commands'),
              subtitle: const Text('Wake phrase and custom commands'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(VoiceRoutes.voiceCommand),
            ),
            const Divider(),
            const SectionTitle('Emergency contact'),
            const _EmergencyContactPlaceholder(),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => _reset(context),
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset to default'),
              style: OutlinedButton.styleFrom(
                foregroundColor: p.danger,
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// PLACEHOLDER for the emergency contact card.
///
/// The contact lives in Member 3's `emergency_contacts` collection, and
/// Member 3's code does not provide a way to read it yet. When it does,
/// replace this with a read-only card. This screen never writes to
/// emergency_contacts.
class _EmergencyContactPlaceholder extends StatelessWidget {
  const _EmergencyContactPlaceholder();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: p.primary, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No emergency contact set',
                      style: TextStyle(
                        color: p.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Contacts are managed in the Safety section.',
                      style: TextStyle(color: p.mutedText),
                    ),
                  ],
                ),
              ),
              // Disabled until Member 3's screen exists.
              const TextButton(onPressed: null, child: Text('Edit')),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Editing will open the Safety section once it is added.',
            style: TextStyle(color: p.mutedText, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
