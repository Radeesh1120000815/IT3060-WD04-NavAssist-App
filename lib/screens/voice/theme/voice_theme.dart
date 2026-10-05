import 'package:flutter/material.dart';

/// Colours for Member 2's screens, taken from the hi-fi designs.
/// The app has no shared theme yet, so this lives in the voice folder.
///
/// There are two versions: [normal] and [highContrast] (UR-04).
/// Screens read the colours with `context.palette`.
class VoicePalette extends ThemeExtension<VoicePalette> {
  const VoicePalette({
    required this.primary,
    required this.onPrimary,
    required this.background,
    required this.text,
    required this.mutedText,
    required this.tile,
    required this.divider,
    required this.switchOff,
    required this.navBackground,
    required this.navCard,
    required this.onNav,
    required this.onNavMuted,
    required this.mapStreet,
    required this.mapRoute,
    required this.danger,
    required this.dangerSurface,
    required this.success,
    required this.borderWidth,
  });

  final Color primary; // blue buttons, selected chips, switches
  final Color onPrimary; // text on primary
  final Color background; // screen background
  final Color text; // main text
  final Color mutedText; // subtitles
  final Color tile; // light blue-grey cards and buttons
  final Color divider;
  final Color switchOff; // switch track when off
  final Color navBackground; // dark Active Navigation screen
  final Color navCard; // cards on the dark screen
  final Color onNav; // text on the dark screen
  final Color onNavMuted;
  final Color mapStreet;
  final Color mapRoute;
  final Color danger; // SOS and alerts
  final Color dangerSurface; // light red alert background
  final Color success; // "On track"
  final double borderWidth; // 0 = no outlines; high contrast adds outlines

  /// Colours from the hi-fi designs.
  static const normal = VoicePalette(
    primary: Color(0xFF1D4ED8),
    onPrimary: Colors.white,
    background: Colors.white,
    text: Color(0xFF0F172A),
    mutedText: Color(0xFF5B6576),
    tile: Color(0xFFE3E9F6),
    divider: Color(0xFFE2E8F0),
    switchOff: Color(0xFFCBD5E1),
    navBackground: Color(0xFF0F1D3A),
    navCard: Color(0xFF22314F),
    onNav: Colors.white,
    onNavMuted: Color(0xFFB8C2D6),
    mapStreet: Color(0xFF243862),
    mapRoute: Color(0xFF2F5BEA),
    danger: Color(0xFFB91C1C),
    dangerSurface: Color(0xFFFDE8E8),
    success: Color(0xFF15803D),
    borderWidth: 0,
  );

  /// High contrast: pure black and white, darker colours and outlines.
  static const highContrast = VoicePalette(
    primary: Color(0xFF002080),
    onPrimary: Colors.white,
    background: Colors.white,
    text: Colors.black,
    mutedText: Colors.black,
    tile: Colors.white,
    divider: Colors.black,
    switchOff: Color(0xFF5A5A5A),
    navBackground: Colors.black,
    navCard: Colors.black,
    onNav: Colors.white,
    onNavMuted: Colors.white,
    mapStreet: Color(0xFF6B6B6B),
    mapRoute: Color(0xFFFFD600),
    danger: Color(0xFF8B0000),
    dangerSurface: Colors.white,
    success: Color(0xFF005A00),
    borderWidth: 2,
  );

  /// An outline for cards in high contrast mode, otherwise none.
  BoxBorder? get border =>
      borderWidth == 0 ? null : Border.all(color: text, width: borderWidth);

  /// Same as [border] but for the dark navigation screen.
  BoxBorder? get navBorder =>
      borderWidth == 0 ? null : Border.all(color: onNav, width: borderWidth);

  // ThemeExtension needs these two methods. Our colours never change one
  // by one, and we do not animate between palettes, so they stay simple.
  @override
  VoicePalette copyWith() => this;

  @override
  VoicePalette lerp(ThemeExtension<VoicePalette>? other, double t) =>
      other is VoicePalette && t >= 0.5 ? other : this;
}

/// Lets any widget write `context.palette`.
extension VoicePaletteContext on BuildContext {
  VoicePalette get palette =>
      Theme.of(this).extension<VoicePalette>() ?? VoicePalette.normal;
}

/// Builds the Material theme for Member 2's screens.
class VoiceTheme {
  VoiceTheme._();

  /// How much bigger text gets when "Large text" is on. It multiplies the
  /// phone's own text size, so the user's system setting is still respected.
  static const double largeTextFactor = 1.3;

  static ThemeData build(VoicePalette p) {
    final scheme = ColorScheme.fromSeed(seedColor: p.primary).copyWith(
      primary: p.primary,
      onPrimary: p.onPrimary,
      surface: p.background,
      onSurface: p.text,
      onSurfaceVariant: p.mutedText,
      outline: p.borderWidth == 0 ? p.divider : p.text,
      error: p.danger,
    );
    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    const buttonText = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      extensions: [p],
      // Keeps every tappable thing at least 48 x 48.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      dividerTheme: DividerThemeData(
        color: p.divider,
        thickness: p.borderWidth == 0 ? 1 : 2,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.primary : p.switchOff,
        ),
        trackOutlineColor: WidgetStatePropertyAll(
          p.borderWidth == 0 ? Colors.transparent : p.text,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: p.primary,
        inactiveTrackColor: p.switchOff,
        thumbColor: p.primary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          textStyle: buttonText,
          shape: rounded,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: p.primary,
          textStyle: buttonText,
          shape: rounded,
          side: BorderSide(
            color: p.borderWidth == 0 ? p.divider : p.text,
            width: p.borderWidth == 0 ? 1 : p.borderWidth,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: p.primary,
          textStyle: buttonText,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
