import 'package:it3060_wd04_navassist_app/screens/voice/data/alert_log_entry.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/data/voice_repository.dart';
import 'package:it3060_wd04_navassist_app/screens/voice/data/voice_settings.dart';

/// A VoiceRepository for widget tests: no Firebase. Instead of saving,
/// it remembers what the screens asked it to do, so a test can check it.
/// (Not a test file itself: the name does not end in _test.dart.)
class RecordingRepository extends VoiceRepository {
  final List<VoiceSettings> savedSettings = [];
  int resetCount = 0;
  final List<String> loggedAlerts = []; // messages
  final List<String> acknowledgedIds = [];

  @override
  Future<void> updateSettings(VoiceSettings settings) async {
    savedSettings.add(settings);
  }

  @override
  Future<VoiceSettings> resetToDefault() async {
    resetCount++;
    return const VoiceSettings();
  }

  @override
  Future<String> logAlert({
    required String type,
    required AlertSeverity severity,
    required String message,
  }) async {
    loggedAlerts.add(message);
    return 'alert-${loggedAlerts.length}';
  }

  @override
  Future<void> acknowledgeAlert(String id) async {
    acknowledgedIds.add(id);
  }
}
