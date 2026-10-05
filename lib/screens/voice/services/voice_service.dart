import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../data/voice_settings.dart';
import '../data/voice_settings_provider.dart';

/// What kind of announcement is being spoken.
/// Each kind (except general) has its own "Announce" switch in settings.
enum AnnouncementType { turn, obstacle, crossing, arrival, distance, general }

/// Speaks text out loud with text-to-speech (UR-01).
///
/// - Uses the user's volume and speech rate from settings.
/// - Respects the voice on/off switch and the "Announce" switches.
/// - Remembers the last instruction so the user can ask for a replay.
/// - Shows the spoken text as a caption (also helps users who cannot hear).
/// - Saves each spoken instruction to settings/{uid}/instruction_history.
class VoiceService extends ChangeNotifier {
  VoiceService(this.settingsProvider, {FlutterTts? tts})
    : _tts = tts ?? FlutterTts();

  final VoiceSettingsProvider settingsProvider;
  final FlutterTts _tts;

  /// Normal voice pitch for navigation prompts.
  static const double normalPitch = 1.0;

  // Android's TTS treats 0.5 as normal speed, so 1.0x in our settings
  // becomes 0.5 here (0.75x -> 0.375, 1.5x -> 0.75).
  static const double _androidRateFactor = 0.5;

  bool _isReady = false;
  bool _isSpeaking = false;
  String _caption = '';
  String? _lastInstruction;

  /// The text currently shown on screen as a caption.
  String get caption => _caption;

  /// The last navigation instruction, used by Replay. Null if none yet.
  String? get lastInstruction => _lastInstruction;

  /// True while the phone is speaking.
  bool get isSpeaking => _isSpeaking;

  VoiceSettings get _settings => settingsProvider.settings;

  /// Checks the voice switch and the matching "Announce" switch.
  bool shouldAnnounce(AnnouncementType type) {
    final s = _settings;
    if (!s.voiceEnabled) return false;
    switch (type) {
      case AnnouncementType.turn:
        return s.announceTurns;
      case AnnouncementType.obstacle:
        return s.announceObstacles;
      case AnnouncementType.crossing:
        return s.announceCrossings;
      case AnnouncementType.arrival:
        return s.announceArrival;
      case AnnouncementType.distance:
        return s.announceDistance;
      case AnnouncementType.general:
        return true;
    }
  }

  /// Speaks a navigation instruction, e.g. "Turn left onto King Street".
  /// The caption and Replay text are always updated, even when the voice
  /// is switched off. Returns true if it was actually spoken.
  Future<bool> speakInstruction(
    String text, {
    AnnouncementType type = AnnouncementType.general,
  }) async {
    if (text.trim().isEmpty) return false;
    _lastInstruction = text;
    _setCaption(text);

    if (!shouldAnnounce(type)) return false;
    final spoken = await _speak(text, pitch: normalPitch);
    if (spoken) unawaited(_saveToHistory(text));
    return spoken;
  }

  /// Says the last instruction again (the user asked for it,
  /// so only the main voice switch is checked).
  Future<bool> replay() async {
    final text = _lastInstruction;
    if (text == null) return false;
    _setCaption(text);
    if (!_settings.voiceEnabled) return false;
    return _speak(text, pitch: normalPitch);
  }

  /// Speaks an alert. Used by AlertService.
  /// Interrupts anything being said and does NOT change the Replay text.
  Future<bool> speakAlert(
    String text, {
    required AnnouncementType type,
    double pitch = normalPitch,
  }) async {
    _setCaption(text);
    if (!shouldAnnounce(type)) return false;
    await stop();
    return _speak(text, pitch: pitch);
  }

  /// Speaks a short message such as "You are on track."
  /// Does not change the Replay text or the history.
  Future<bool> speakMessage(String text) async {
    if (!_settings.voiceEnabled) return false;
    return _speak(text, pitch: normalPitch);
  }

  /// Speaks a sample sentence for the "Test voice announcement" button.
  Future<bool> testAnnouncement() {
    const sample = 'In 50 metres, turn right onto King Street.';
    _setCaption(sample);
    return _speak(sample, pitch: normalPitch);
  }

  /// Stops speaking straight away.
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('VoiceService: stop failed: $e');
    }
    _setSpeaking(false);
  }

  // Sets up the TTS engine once.
  Future<void> _ensureReady() async {
    if (_isReady) return;
    // Makes speak() wait until the sentence has finished.
    await _tts.awaitSpeakCompletion(true);
    _isReady = true;
  }

  // Speaks with the user's volume and rate. Never throws:
  // if the phone has no TTS engine, it returns false and the caption remains.
  Future<bool> _speak(String text, {required double pitch}) async {
    try {
      await _ensureReady();
      await _tts.setVolume(_settings.volume);
      await _tts.setSpeechRate(_settings.speechRate * _androidRateFactor);
      await _tts.setPitch(pitch);
      _setSpeaking(true);
      await _tts.speak(text);
      return true;
    } catch (e) {
      debugPrint('VoiceService: could not speak: $e');
      return false;
    } finally {
      _setSpeaking(false);
    }
  }

  // CREATE in instruction_history. A save error must never stop guidance.
  Future<void> _saveToHistory(String text) async {
    try {
      await settingsProvider.repository.addInstructionHistory(text);
    } catch (e) {
      debugPrint('VoiceService: history not saved: $e');
    }
  }

  void _setCaption(String text) {
    _caption = text;
    notifyListeners();
  }

  void _setSpeaking(bool value) {
    if (_isSpeaking == value) return;
    _isSpeaking = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}
