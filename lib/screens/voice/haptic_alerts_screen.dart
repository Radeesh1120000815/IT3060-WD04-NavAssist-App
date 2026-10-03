import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/alert_log_entry.dart';
import 'data/haptic_cue.dart';
import 'data/voice_repository.dart';
import 'data/voice_settings.dart';
import 'data/voice_settings_provider.dart';
import 'services/alert_service.dart';
import 'services/haptic_service.dart';
import 'theme/voice_theme.dart';
import 'widgets/voice_widgets.dart';

/// Haptic Alerts (haptic_alerts.png), UR-03.
///
/// Vibration on/off, intensity, the six navigation patterns (tap one to
/// feel it) and a test button. Below that, the alert log (UR-02) with
/// buttons to try a high and a low alert, and a Clear button.
class HapticAlertsScreen extends StatefulWidget {
  const HapticAlertsScreen({super.key});

  @override
  State<HapticAlertsScreen> createState() => _HapticAlertsScreenState();
}

class _HapticAlertsScreenState extends State<HapticAlertsScreen> {
  late final Stream<List<AlertLogEntry>> _alertLog;
  late final Future<bool> _canVibrate;
  HapticCue _selected = HapticCue.turnLeft;

  @override
  void initState() {
    super.initState();
    _alertLog = context
        .read<VoiceSettingsProvider>()
        .repository
        .watchAlertLog();
    _canVibrate = context.read<HapticService>().isAvailable();
  }

  // Selects a pattern and plays it on the phone.
  Future<void> _play(HapticCue cue) async {
    setState(() => _selected = cue);
    final hapticOn = context
        .read<VoiceSettingsProvider>()
        .settings
        .hapticEnabled;
    final played = await context.read<HapticService>().playCue(cue);
    if (!played && mounted) {
      showMessage(
        context,
        hapticOn
            ? 'This phone cannot vibrate.'
            : 'Haptic feedback is off. Turn it on to feel the pattern.',
      );
    }
  }

  Future<void> _clearLog() async {
    final repository = context.read<VoiceSettingsProvider>().repository;
    final ok = await confirmAction(
      context,
      title: 'Clear alert log?',
      message: 'This deletes every saved alert.',
      confirmLabel: 'Clear',
    );
    if (!ok) return;
    try {
      await repository.clearAlertLog();
      if (mounted) showMessage(context, 'Alert log cleared.');
    } on VoiceDataException catch (e) {
      if (mounted) showMessage(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final provider = context.watch<VoiceSettingsProvider>();
    final s = provider.settings;
    final alerts = context.read<AlertService>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const VoiceHeader(title: 'Haptic Alerts'),
            FutureBuilder<bool>(
              future: _canVibrate,
              builder: (context, snapshot) => snapshot.data == false
                  ? const NoteText(
                      'This phone cannot vibrate, so haptic alerts will not be felt.',
                      icon: Icons.info_outline,
                    )
                  : const SizedBox.shrink(),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Haptic feedback',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Vibration-based navigation cues'),
              value: s.hapticEnabled,
              onChanged: (v) =>
                  provider.updateSettings(s.copyWith(hapticEnabled: v)),
            ),
            const SectionTitle('Intensity'),
            ChoiceRow<HapticIntensity>(
              options: HapticIntensity.values,
              selected: s.hapticIntensity,
              labelOf: _intensityLabel,
              semanticLabelOf: (i) => 'Intensity ${_intensityLabel(i)}',
              onSelected: (i) =>
                  provider.updateSettings(s.copyWith(hapticIntensity: i)),
            ),
            const SectionTitle('Haptic patterns'),
            for (final cue in HapticCue.values) ...[
              _PatternRow(
                cue: cue,
                selected: cue == _selected,
                onTap: () => _play(cue),
              ),
              const Divider(),
            ],
            const SizedBox(height: 16),
            TonalButton(
              icon: Icons.vibration,
              label: 'Test haptic pattern',
              onPressed: () => _play(_selected),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Plays the selected pattern: ${_selected.label}.',
                style: TextStyle(color: p.mutedText),
              ),
            ),
            SectionTitle(
              'Alert log',
              trailing: TextButton(
                onPressed: _clearLog,
                child: const Text('Clear', semanticsLabel: 'Clear alert log'),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => unawaited(
                    alerts.trigger(
                      type: 'obstacle',
                      severity: AlertSeverity.high,
                      message: 'Obstacle ahead',
                    ),
                  ),
                  icon: const Icon(Icons.warning_amber_rounded),
                  label: const Text('Test high alert'),
                ),
                OutlinedButton.icon(
                  onPressed: () => unawaited(
                    alerts.trigger(
                      type: 'hazard',
                      severity: AlertSeverity.low,
                      message:
                          'Hazard reported nearby, broken pavement in 80 m',
                    ),
                  ),
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Test low alert'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StreamList<AlertLogEntry>(
              stream: _alertLog,
              maxItems: 20,
              emptyText: 'No alerts yet.',
              itemBuilder: (context, entry) => _AlertLogTile(entry: entry),
            ),
          ],
        ),
      ),
    );
  }

  static String _intensityLabel(HapticIntensity i) =>
      i.value[0].toUpperCase() + i.value.substring(1);
}

/// One pattern row: name, description and the dot/dash drawing.
class _PatternRow extends StatelessWidget {
  const _PatternRow({
    required this.cue,
    required this.selected,
    required this.onTap,
  });

  final HapticCue cue;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      label: '${cue.label}, ${cue.description}',
      onTapHint: 'play this pattern',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cue.label,
                        style: TextStyle(
                          color: p.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        cue.description,
                        style: TextStyle(color: p.mutedText),
                      ),
                    ],
                  ),
                ),
                // Selected is shown by a tick, not only by colour.
                if (selected) ...[
                  Icon(Icons.check_circle, color: p.primary, size: 20),
                  const SizedBox(width: 10),
                ],
                PatternGlyph(cue),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One alert in the log: message, severity, time and dismissed state.
class _AlertLogTile extends StatelessWidget {
  const _AlertLogTile({required this.entry});

  final AlertLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final high = entry.severity == AlertSeverity.high;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        high ? Icons.warning_amber_rounded : Icons.notifications_active,
        color: high ? p.danger : p.primary,
      ),
      title: Text(entry.message),
      subtitle: Text(
        '${high ? 'High' : 'Low'} severity · ${formatTime(entry.firedAt)} · '
        '${entry.acknowledged ? 'Dismissed' : 'Not dismissed'}',
      ),
    );
  }
}
