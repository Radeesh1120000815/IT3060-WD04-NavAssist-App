import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/alert_log_entry.dart';
import '../data/voice_settings_provider.dart';
import 'haptic_service.dart';
import 'voice_service.dart';

/// The alert that is on screen right now.
class ActiveAlert {
  const ActiveAlert({
    required this.type,
    required this.severity,
    required this.message,
  });

  final String type; // e.g. 'obstacle', 'crossing', 'hazard'
  final AlertSeverity severity;
  final String message;
}

/// Fires obstacle / hazard alerts (UR-02) with voice and vibration (UR-03).
///
/// HIGH severity (full-screen alert):
///   - starts with the spoken prefix "Warning! Warning!" and uses a higher
///     voice pitch, so it sounds clearly different from normal navigation
///     prompts (Milestone 02 recommendation T7)
///   - strong, repeating vibration until the user dismisses it
/// LOW severity (small banner):
///   - normal voice, starts with "Notice."
///   - one short vibration pulse
///   - hides itself after [lowAlertDisplayTime]
///
/// Every alert is saved to settings/{uid}/alert_log.
///
/// Note on the "tone": we have no audio-player package, so the different
/// tone is made with the text-to-speech pitch, not a sound file.
class AlertService extends ChangeNotifier {
  AlertService({
    required this.settingsProvider,
    required this.voice,
    required this.haptic,
  });

  final VoiceSettingsProvider settingsProvider;
  final VoiceService voice;
  final HapticService haptic;

  /// Spoken before every high-severity alert (T7).
  static const String highSeverityPrefix = 'Warning! Warning!';

  /// Spoken before every low-severity alert.
  static const String lowSeverityPrefix = 'Notice.';

  /// Higher pitch for high-severity alerts (normal prompts use 1.0).
  static const double highSeverityPitch = 1.4;

  /// How long a low-severity banner stays on screen.
  static const Duration lowAlertDisplayTime = Duration(seconds: 4);

  ActiveAlert? _current;
  Future<String?>? _currentLogId; // Firestore id of the current alert
  Timer? _autoHideTimer;

  /// The alert to show, or null when there is none.
  ActiveAlert? get currentAlert => _current;

  /// The exact sentence that is spoken for an alert.
  static String spokenText(AlertSeverity severity, String message) {
    final prefix = severity == AlertSeverity.high
        ? highSeverityPrefix
        : lowSeverityPrefix;
    return '$prefix $message';
  }

  /// Which "Announce" switch controls this alert type.
  static AnnouncementType announcementTypeFor(String type) {
    switch (type) {
      case 'obstacle':
        return AnnouncementType.obstacle;
      case 'crossing':
        return AnnouncementType.crossing;
      default:
        return AnnouncementType.general;
    }
  }

  /// Shows, speaks, vibrates and logs an alert.
  /// Example: trigger(type: 'obstacle', severity: AlertSeverity.high,
  ///                  message: 'Obstacle ahead')
  Future<void> trigger({
    required String type,
    required AlertSeverity severity,
    required String message,
  }) async {
    // Save to the alert log in the background (CREATE).
    final logId = _logAlert(type, severity, message);

    // A low alert must never hide a high alert that is still showing.
    final highIsShowing = _current?.severity == AlertSeverity.high;
    if (severity == AlertSeverity.low && highIsShowing) return;

    _autoHideTimer?.cancel();
    _current = ActiveAlert(type: type, severity: severity, message: message);
    _currentLogId = logId;
    notifyListeners();

    final text = spokenText(severity, message);
    final announceType = announcementTypeFor(type);

    if (severity == AlertSeverity.high) {
      await haptic.vibrateHigh();
      await voice.speakAlert(
        text,
        type: announceType,
        pitch: highSeverityPitch,
      );
    } else {
      await haptic.vibrateLow();
      _autoHideTimer = Timer(lowAlertDisplayTime, _hide);
      await voice.speakAlert(text, type: announceType);
    }
  }

  /// The user pressed Dismiss: stop vibration and voice, hide the alert,
  /// and mark it as acknowledged in Firestore (UPDATE).
  Future<void> acknowledge() async {
    final logId = _currentLogId;
    _hide();
    await haptic.stop();
    await voice.stop();

    final id = await logId;
    if (id == null) return;
    try {
      await settingsProvider.repository.acknowledgeAlert(id);
    } catch (e) {
      debugPrint('AlertService: acknowledge not saved: $e');
    }
  }

  // Hides the alert without acknowledging it (low alerts time out).
  void _hide() {
    _autoHideTimer?.cancel();
    _current = null;
    _currentLogId = null;
    notifyListeners();
  }

  // CREATE in alert_log. Returns the new id, or null if saving failed.
  Future<String?> _logAlert(
    String type,
    AlertSeverity severity,
    String message,
  ) async {
    try {
      return await settingsProvider.repository.logAlert(
        type: type,
        severity: severity,
        message: message,
      );
    } catch (e) {
      debugPrint('AlertService: alert not logged: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    super.dispose();
  }
}
