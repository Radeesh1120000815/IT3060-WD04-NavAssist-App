import 'package:flutter/foundation.dart';

import 'voice_repository.dart';
import 'voice_settings.dart';

/// Keeps the current user's settings in memory and shares them with all
/// Member 2 screens through the `provider` package.
///
/// Screens read:   `context.watch<VoiceSettingsProvider>().settings`
/// Screens change: `context.read<VoiceSettingsProvider>().updateSettings(...)`
class VoiceSettingsProvider extends ChangeNotifier {
  VoiceSettingsProvider({VoiceRepository? repository})
    : repository = repository ?? VoiceRepository();

  /// Shared repository, so screens can also use the list methods
  /// (history, commands, alerts, feedback).
  final VoiceRepository repository;

  VoiceSettings _settings = const VoiceSettings();
  bool _isLoading = false;
  String? _errorMessage;
  Future<void>? _loadFuture;

  /// Finishes when the first [load] has finished. Navigation waits for this
  /// so the first instruction uses the user's own volume and speed.
  Future<void> get ready => _loadFuture ?? Future<void>.value();

  /// The current settings. Defaults until [load] finishes.
  VoiceSettings get settings => _settings;

  /// True while settings are being loaded.
  bool get isLoading => _isLoading;

  /// A simple message to show or speak, or null when all is fine.
  String? get errorMessage => _errorMessage;

  /// READ: loads settings from Firestore. Called once when the app starts.
  /// If it fails (e.g. no internet) the defaults are kept,
  /// so the app still works.
  Future<void> load() => _loadFuture = _load();

  Future<void> _load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _settings = await repository.getSettings();
    } catch (e) {
      _errorMessage = _messageFor(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// UPDATE: shows the new settings straight away, then saves them.
  /// Example: provider.updateSettings(provider.settings.copyWith(volume: 0.5))
  Future<void> updateSettings(VoiceSettings newSettings) async {
    _settings = newSettings;
    _errorMessage = null;
    notifyListeners();
    await _save(() => repository.updateSettings(newSettings));
  }

  /// DELETE + CREATE: puts every setting back to its default value.
  Future<void> resetToDefault() async {
    _settings = const VoiceSettings();
    _errorMessage = null;
    notifyListeners();
    await _save(repository.resetToDefault);
  }

  /// Hides the current error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Runs a save. On failure the new value stays on screen
  // and an error message is shown instead of crashing.
  Future<void> _save(Future<Object?> Function() action) async {
    try {
      await action();
    } catch (e) {
      _errorMessage = _messageFor(e);
      notifyListeners();
    }
  }

  // The message to show for an error.
  String _messageFor(Object error) {
    if (error is VoiceDataException) return error.message;
    return 'Could not reach your saved settings. Using defaults for now.';
  }
}
