import 'package:flutter/material.dart';

/// Member 3's theme, scoped to Safety routes only.
///
/// The palette reuses the existing Home blue and neutral background together
/// with the existing Voice tile, text, and danger colours. Keeping this theme
/// inside the Safety shell prevents it from changing Member 1 or Member 2 UI.
abstract final class SafetyTheme {
  static const primary = Color(0xFF1B4FD8);
  static const primaryContainer = Color(0xFFE3E9F6);
  static const background = Color(0xFFFAFAFA);
  static const text = Color(0xFF0F172A);
  static const mutedText = Color(0xFF5B6576);
  static const divider = Color(0xFFE2E8F0);
  static const danger = Color(0xFFB91C1C);
  static const dangerContainer = Color(0xFFFDE8E8);

  /// Theme used by the standalone Member 3 preview.
  static ThemeData get light => applyTo(ThemeData(useMaterial3: true));

  /// Applies Safety colours while preserving the surrounding app's component
  /// sizing, typography, and behavior.
  static ThemeData applyTo(ThemeData base) {
    final colors =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: primary,
          onPrimary: Colors.white,
          primaryContainer: primaryContainer,
          onPrimaryContainer: text,
          secondary: primary,
          onSecondary: Colors.white,
          secondaryContainer: primaryContainer,
          onSecondaryContainer: text,
          surface: Colors.white,
          onSurface: text,
          onSurfaceVariant: mutedText,
          outline: divider,
          error: danger,
          onError: Colors.white,
          errorContainer: dangerContainer,
          onErrorContainer: danger,
        );

    return base.copyWith(
      colorScheme: colors,
      scaffoldBackgroundColor: background,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.white,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: base.cardTheme.copyWith(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: base.dividerTheme.copyWith(color: divider),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        border: const OutlineInputBorder(),
      ),
    );
  }
}
