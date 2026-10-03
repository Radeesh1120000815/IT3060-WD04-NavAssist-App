import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/alert_log_entry.dart';
import '../data/voice_settings_provider.dart';
import '../services/alert_service.dart';
import '../theme/voice_theme.dart';
import 'voice_widgets.dart';

/// Shows the alert from [AlertService] on top of any Member 2 screen (UR-02).
///
/// - HIGH severity: full-screen warning that blocks the screen until the
///   user presses Dismiss (alert_popup_wireframe.png).
/// - LOW severity: small banner at the top that does not block anything
///   and hides itself after about 4 seconds (alert_banner_wireframe.png).
///
/// Dismiss marks the alert as acknowledged in alert_log.
class AlertOverlay extends StatelessWidget {
  const AlertOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final alert = context.watch<AlertService>().currentAlert;

    Widget content;
    if (alert == null) {
      content = const SizedBox.shrink(key: ValueKey('no-alert'));
    } else if (alert.severity == AlertSeverity.high) {
      content = _HighAlert(key: ObjectKey(alert), alert: alert);
    } else {
      content = _LowAlertBanner(key: ObjectKey(alert), alert: alert);
    }

    // Fades in and out, unless "Reduce motion" is on.
    return AnimatedSwitcher(
      duration: motion(context, const Duration(milliseconds: 250)),
      child: content,
    );
  }
}

/// Full-screen warning with a big Dismiss button.
class _HighAlert extends StatelessWidget {
  const _HighAlert({super.key, required this.alert});

  final ActiveAlert alert;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final settings = context.watch<VoiceSettingsProvider>().settings;
    final text = Theme.of(context).textTheme;
    final vibrationNote = settings.hapticEnabled
        ? 'Strong vibration until you dismiss'
        : 'Vibration is turned off';

    // BlockSemantics hides the screen underneath from TalkBack, and
    // scopesRoute makes TalkBack treat this like a new page.
    return BlockSemantics(
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: 'Warning',
        child: SizedBox.expand(
          child: Material(
            color: p.background,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      liveRegion: settings.screenReaderSupport,
                      container: true,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 32,
                        ),
                        decoration: BoxDecoration(
                          color: p.dangerSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: p.danger, width: 3),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 72,
                              color: p.danger,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'WARNING',
                              style: text.titleMedium?.copyWith(
                                color: p.danger,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              alert.message.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: text.headlineMedium?.copyWith(
                                color: p.danger,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              vibrationNote,
                              textAlign: TextAlign.center,
                              style: text.bodyLarge?.copyWith(color: p.danger),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () =>
                          context.read<AlertService>().acknowledge(),
                      icon: const Icon(Icons.check),
                      label: const Text('Dismiss alert'),
                      style: FilledButton.styleFrom(
                        backgroundColor: p.danger,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(48, 64),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small banner at the top. Taps outside it still reach the screen below.
class _LowAlertBanner extends StatelessWidget {
  const _LowAlertBanner({super.key, required this.alert});

  final ActiveAlert alert;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final screenReader = context
        .watch<VoiceSettingsProvider>()
        .settings
        .screenReaderSupport;

    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Semantics(
            liveRegion: screenReader,
            container: true,
            child: Material(
              elevation: 4,
              color: p.dangerSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: p.danger, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active, color: p.danger),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Notice: ',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            TextSpan(text: alert.message),
                          ],
                        ),
                        style: TextStyle(color: p.danger, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          context.read<AlertService>().acknowledge(),
                      icon: Icon(Icons.close, color: p.danger),
                      tooltip: 'Dismiss notice',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
