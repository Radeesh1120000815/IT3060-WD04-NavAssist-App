import 'parse_helpers.dart';

/// How strong vibrations are (UR-03).
enum HapticIntensity {
  gentle('gentle'),
  medium('medium'),
  strong('strong');

  const HapticIntensity(this.value);

  /// The text saved in Firestore.
  final String value;

  /// Reads the saved text back. Unknown text becomes [medium].
  static HapticIntensity fromValue(String value) =>
      values.firstWhere((i) => i.value == value, orElse: () => medium);
}

/// All of one user's voice, haptic and accessibility settings.
/// Stored in Firestore as the document settings/{uid}.
///
/// The default values in the constructor are the app defaults,
/// so `const VoiceSettings()` means "default settings".
class VoiceSettings {
  /// The only speech speeds the Voice Guidance screen offers.
  static const List<double> allowedSpeechRates = [0.75, 1.0, 1.25, 1.5];

  // Voice guidance (UR-01)
  final bool voiceEnabled;
  final double volume; // 0.0 (silent) to 1.0 (full)
  final double speechRate; // one of allowedSpeechRates
  final bool announceTurns;
  final bool announceObstacles; // UR-02
  final bool announceCrossings;
  final bool announceArrival;
  final bool announceDistance;

  // Vibration (UR-03)
  final bool hapticEnabled;
  final HapticIntensity hapticIntensity;

  // Accessibility (UR-04)
  final bool largeText;
  final bool highContrast;
  final bool screenReaderSupport;
  final bool reduceMotion;

  // Voice commands
  final bool wakeWordEnabled;
  final String wakePhrase;
  final bool longPressFallback; // long-press the screen to start listening

  // Filled in by the Firestore server. Null until the document is saved.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VoiceSettings({
    this.voiceEnabled = true,
    this.volume = 0.8,
    this.speechRate = 1.0,
    this.announceTurns = true,
    this.announceObstacles = true,
    this.announceCrossings = true,
    this.announceArrival = true,
    this.announceDistance = false,
    this.hapticEnabled = true,
    this.hapticIntensity = HapticIntensity.medium,
    this.largeText = false,
    this.highContrast = false,
    this.screenReaderSupport = true,
    this.reduceMotion = false,
    this.wakeWordEnabled = true,
    this.wakePhrase = 'hey navassist',
    this.longPressFallback = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Builds settings from a Firestore document.
  /// Any missing or invalid field falls back to its default value.
  factory VoiceSettings.fromMap(Map<String, dynamic> map) {
    const d = VoiceSettings(); // defaults
    final rate = readDouble(map, 'speechRate', d.speechRate);
    final phrase = readString(map, 'wakePhrase', d.wakePhrase).trim();

    return VoiceSettings(
      voiceEnabled: readBool(map, 'voiceEnabled', d.voiceEnabled),
      volume: readDouble(map, 'volume', d.volume).clamp(0.0, 1.0),
      speechRate: allowedSpeechRates.contains(rate) ? rate : d.speechRate,
      announceTurns: readBool(map, 'announceTurns', d.announceTurns),
      announceObstacles: readBool(
        map,
        'announceObstacles',
        d.announceObstacles,
      ),
      announceCrossings: readBool(
        map,
        'announceCrossings',
        d.announceCrossings,
      ),
      announceArrival: readBool(map, 'announceArrival', d.announceArrival),
      announceDistance: readBool(map, 'announceDistance', d.announceDistance),
      hapticEnabled: readBool(map, 'hapticEnabled', d.hapticEnabled),
      hapticIntensity: HapticIntensity.fromValue(
        readString(map, 'hapticIntensity', d.hapticIntensity.value),
      ),
      largeText: readBool(map, 'largeText', d.largeText),
      highContrast: readBool(map, 'highContrast', d.highContrast),
      screenReaderSupport: readBool(
        map,
        'screenReaderSupport',
        d.screenReaderSupport,
      ),
      reduceMotion: readBool(map, 'reduceMotion', d.reduceMotion),
      wakeWordEnabled: readBool(map, 'wakeWordEnabled', d.wakeWordEnabled),
      wakePhrase: phrase.isEmpty ? d.wakePhrase : phrase,
      longPressFallback: readBool(
        map,
        'longPressFallback',
        d.longPressFallback,
      ),
      createdAt: readDate(map, 'createdAt'),
      updatedAt: readDate(map, 'updatedAt'),
    );
  }

  /// Converts settings to a map for Firestore.
  /// createdAt / updatedAt are left out: the repository sets them
  /// with server timestamps.
  Map<String, dynamic> toMap() {
    return {
      'voiceEnabled': voiceEnabled,
      'volume': volume,
      'speechRate': speechRate,
      'announceTurns': announceTurns,
      'announceObstacles': announceObstacles,
      'announceCrossings': announceCrossings,
      'announceArrival': announceArrival,
      'announceDistance': announceDistance,
      'hapticEnabled': hapticEnabled,
      'hapticIntensity': hapticIntensity.value,
      'largeText': largeText,
      'highContrast': highContrast,
      'screenReaderSupport': screenReaderSupport,
      'reduceMotion': reduceMotion,
      'wakeWordEnabled': wakeWordEnabled,
      'wakePhrase': wakePhrase,
      'longPressFallback': longPressFallback,
    };
  }

  /// Returns a copy with only the given fields changed.
  /// Example: settings.copyWith(volume: 0.5)
  VoiceSettings copyWith({
    bool? voiceEnabled,
    double? volume,
    double? speechRate,
    bool? announceTurns,
    bool? announceObstacles,
    bool? announceCrossings,
    bool? announceArrival,
    bool? announceDistance,
    bool? hapticEnabled,
    HapticIntensity? hapticIntensity,
    bool? largeText,
    bool? highContrast,
    bool? screenReaderSupport,
    bool? reduceMotion,
    bool? wakeWordEnabled,
    String? wakePhrase,
    bool? longPressFallback,
  }) {
    return VoiceSettings(
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      volume: volume ?? this.volume,
      speechRate: speechRate ?? this.speechRate,
      announceTurns: announceTurns ?? this.announceTurns,
      announceObstacles: announceObstacles ?? this.announceObstacles,
      announceCrossings: announceCrossings ?? this.announceCrossings,
      announceArrival: announceArrival ?? this.announceArrival,
      announceDistance: announceDistance ?? this.announceDistance,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      hapticIntensity: hapticIntensity ?? this.hapticIntensity,
      largeText: largeText ?? this.largeText,
      highContrast: highContrast ?? this.highContrast,
      screenReaderSupport: screenReaderSupport ?? this.screenReaderSupport,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      wakeWordEnabled: wakeWordEnabled ?? this.wakeWordEnabled,
      wakePhrase: wakePhrase ?? this.wakePhrase,
      longPressFallback: longPressFallback ?? this.longPressFallback,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
