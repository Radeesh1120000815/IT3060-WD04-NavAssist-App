import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../data/custom_command.dart';
import '../data/voice_settings_provider.dart';

/// Listens for spoken commands such as "hey navassist, repeat".
///
/// HONEST LIMITATION: this is IN-APP listening, not a true always-on
/// background wake word like "Hey Google". It only listens while the
/// Voice Command screen is open (or after a long press). Android's speech
/// recogniser stops after a few seconds of silence, so we start it again
/// each time it stops. Android may play a short beep on each restart.
///
/// How it works:
/// 1. speech_to_text turns speech into text.
/// 2. If the wake word is on, the text must contain the wake phrase.
/// 3. The text is matched to a command: the user's custom commands first,
///    then the built-in words repeat / next / settings / stop.
/// 4. [onCommand] is called so the screen can act on it.
///
/// Long-press fallback (Milestone 02 recommendation T8): a long press
/// listens once WITHOUT needing the wake phrase, for when the wake phrase
/// is not recognised (noise, accent) or the user prefers touch.
class CommandService extends ChangeNotifier {
  CommandService(this.settingsProvider, {SpeechToText? speech})
    : _speech = speech ?? SpeechToText();

  final VoiceSettingsProvider settingsProvider;
  final SpeechToText _speech;

  /// The built-in command words.
  static const Map<String, CommandAction> builtInCommands = {
    'repeat': CommandAction.repeat,
    'next': CommandAction.next,
    'settings': CommandAction.settings,
    'stop': CommandAction.stop,
  };

  /// Called when a command is recognised. Set by VoiceShell.
  void Function(CommandAction action)? onCommand;

  bool _isAvailable = false;
  bool _keepListening = false; // true while the Voice Command screen is open
  bool _skipWakeOnce = false; // set by a long press
  bool _sessionNeedsWake = true;
  bool _disposed = false;
  Timer? _restartTimer;
  String _lastHeard = '';
  CommandAction? _lastAction;
  String? _errorMessage;
  List<CustomCommand> _customCommands = [];

  /// True if speech recognition works on this phone.
  bool get isAvailable => _isAvailable;

  /// True while the microphone is listening.
  bool get isListening => _speech.isListening;

  /// The words heard most recently (shown as "Last heard command").
  String get lastHeard => _lastHeard;

  /// The last command that was recognised, or null.
  CommandAction? get lastAction => _lastAction;

  /// A simple message to show or speak, or null.
  String? get errorMessage => _errorMessage;

  /// True if the current listening session needs the wake phrase first.
  bool get needsWakePhrase => _sessionNeedsWake;

  // ---------------------------------------------------------------------
  // Matching (pure logic, easy to unit test)
  // ---------------------------------------------------------------------

  /// Lower-case, no punctuation, single spaces: "Hey, NavAssist!" -> "hey navassist".
  static String normalise(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r' +'), ' ')
        .trim();
  }

  /// Finds the command in [heard], or returns null.
  ///
  /// [wakePhrase]: if given, the text must contain it.
  /// [customCommands]: checked before the built-in words; longer phrases
  /// are checked first so "stop talking" wins over "stop".
  static CommandAction? matchCommand(
    String heard, {
    String? wakePhrase,
    List<CustomCommand> customCommands = const [],
  }) {
    var text = normalise(heard);
    if (text.isEmpty) return null;

    if (wakePhrase != null) {
      // Remove the wake phrase so its words are not read as a command.
      final rest = removeWakePhrase(text, wakePhrase);
      if (rest == null) return null; // wake phrase not heard
      text = rest;
    }

    final enabled =
        customCommands
            .where((c) => c.enabled && normalise(c.phrase).isNotEmpty)
            .toList()
          ..sort((a, b) => b.phrase.length.compareTo(a.phrase.length));
    for (final command in enabled) {
      if (_containsPhrase(text, normalise(command.phrase))) {
        return command.action;
      }
    }

    for (final entry in builtInCommands.entries) {
      if (_containsPhrase(text, entry.key)) return entry.value;
    }
    return null;
  }

  /// Removes the wake phrase from [text] and returns what is left,
  /// or null if the wake phrase was not heard.
  /// Capitals and spaces do not matter, so "Hey NavAssist", "hey nav assist"
  /// and "heynavassist" all count as "hey navassist".
  static String? removeWakePhrase(String text, String wakePhrase) {
    final clean = normalise(text);
    final letters = normalise(wakePhrase).replaceAll(' ', '');
    if (letters.isEmpty) return clean;

    // "hey" becomes the pattern "h ?e ?y": a space may come between letters.
    final pattern = RegExp(letters.split('').map(RegExp.escape).join(' ?'));
    final match = pattern.firstMatch(clean);
    if (match == null) return null;
    return normalise(clean.replaceRange(match.start, match.end, ' '));
  }

  // Whole words only, so "next" does not match "nexus".
  static bool _containsPhrase(String text, String phrase) {
    return ' $text '.contains(' $phrase ');
  }

  // ---------------------------------------------------------------------
  // Listening
  // ---------------------------------------------------------------------

  /// Sets up speech recognition (asks for microphone permission)
  /// and loads the user's custom commands. Returns false if unavailable.
  Future<bool> init() async {
    try {
      _isAvailable = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
      );
    } catch (e) {
      debugPrint('CommandService: init failed: $e');
      _isAvailable = false;
    }
    _errorMessage = _isAvailable
        ? null
        : 'Voice commands are not available. Check the microphone permission.';
    await reloadCustomCommands();
    _notify();
    return _isAvailable;
  }

  /// Calls [init] the first time, or again if it failed before
  /// (for example, the user has since allowed the microphone).
  Future<bool> ensureReady() async => _isAvailable ? true : init();

  /// READ: loads custom commands from Firestore.
  /// If that fails, only the built-in commands are used.
  Future<void> reloadCustomCommands() async {
    try {
      _customCommands = await settingsProvider.repository.getCustomCommands();
    } catch (e) {
      debugPrint('CommandService: custom commands not loaded: $e');
    }
  }

  /// Starts listening. Call when the Voice Command screen opens.
  /// Keeps restarting until [stopListening] is called.
  Future<void> startListening() async {
    if (!_isAvailable) return;
    _keepListening = true;
    await _listen();
  }

  /// Long-press fallback (T8): listens once without the wake phrase.
  /// Works on any screen, if "long-press fallback" is on in settings.
  Future<void> listenFromLongPress() async {
    if (!_isAvailable || !settingsProvider.settings.longPressFallback) return;
    _skipWakeOnce = true;
    await _speech.stop(); // end the current session first
    await _listen();
  }

  /// Stops listening. Call when the Voice Command screen closes.
  Future<void> stopListening() async {
    _keepListening = false;
    _restartTimer?.cancel();
    await _speech.stop();
    _notify();
  }

  // Starts one listening session.
  Future<void> _listen() async {
    if (_speech.isListening) return;
    final settings = settingsProvider.settings;
    _sessionNeedsWake = settings.wakeWordEnabled && !_skipWakeOnce;
    _skipWakeOnce = false;

    try {
      await _speech.listen(
        onResult: _onResult,
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 5),
          partialResults: true, // show words while the user speaks
          cancelOnError: false,
          listenMode: ListenMode.confirmation, // short commands
        ),
      );
    } catch (e) {
      debugPrint('CommandService: listen failed: $e');
      _errorMessage = 'Could not start listening. Please try again.';
    }
    _notify();
  }

  // Called with the words heard so far, and once more with the final words.
  void _onResult(SpeechRecognitionResult result) {
    _lastHeard = result.recognizedWords;
    _notify();
    if (!result.finalResult) return;

    final settings = settingsProvider.settings;
    final action = matchCommand(
      result.recognizedWords,
      wakePhrase: _sessionNeedsWake ? settings.wakePhrase : null,
      customCommands: _customCommands,
    );
    if (action == null) {
      // The user said only the wake phrase and then paused. The recogniser
      // stops on the pause, so the next session will not need it again.
      final wakeHeard =
          removeWakePhrase(result.recognizedWords, settings.wakePhrase) != null;
      if (_sessionNeedsWake && wakeHeard) _skipWakeOnce = true;
      return;
    }

    _lastAction = action;
    _notify();
    onCommand?.call(action);
  }

  // The recogniser reports 'listening', 'notListening' or 'done'.
  // When a session is done and the screen is still open, start again.
  void _onStatus(String status) {
    _notify();
    if (status == SpeechToText.doneStatus && _keepListening) {
      _restartTimer?.cancel();
      _restartTimer = Timer(const Duration(milliseconds: 500), () {
        if (_keepListening && !_disposed) _listen();
      });
    }
  }

  // "No match" and "timeout" errors are normal when nobody speaks, so they
  // are ignored. A permanent error (e.g. no permission) stops listening.
  void _onError(SpeechRecognitionError error) {
    debugPrint('CommandService: ${error.errorMsg}');
    if (error.permanent) {
      _keepListening = false;
      _errorMessage = 'The microphone stopped working. Please try again.';
      _notify();
    }
  }

  // notifyListeners, but never after dispose (speech callbacks can arrive late).
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _keepListening = false;
    _restartTimer?.cancel();
    _speech.cancel();
    super.dispose();
  }
}
