import 'package:flutter/material.dart';

/// Typography tokens and per-locale font resolution.
///
/// Arabic and English are both first-class, and they use different families:
/// **Cairo** for Arabic, **Manrope** for English. That choice is made once,
/// here, and applied by [AppTheme] — never per screen.
///
/// ## Font files are not bundled yet
///
/// The `.ttf` files are not in the repo: the vendor template's `assets/fonts/`
/// folder was empty when the reference was trimmed, and Cairo has to come from
/// Google Fonts. Until they are added, [familyFor] still returns the correct
/// family name and Flutter falls back to the platform font — the app renders
/// correctly, just not in the brand face.
///
/// To finish the job:
/// 1. Drop the files into `assets/fonts/` (Manrope 400/500/600/700/800,
///    Cairo 400/500/600/700).
/// 2. Uncomment the `fonts:` block in `pubspec.yaml`.
///
/// Nothing else needs to change.
abstract final class AppFonts {
  /// English (LTR) face.
  static const String manrope = 'Manrope';

  /// Arabic (RTL) face.
  static const String cairo = 'Cairo';

  /// The font family for [locale]. Arabic gets Cairo; everything else Manrope.
  static String familyFor(Locale locale) =>
      locale.languageCode == 'ar' ? cairo : manrope;
}

/// Builds the app's [TextTheme] for a given font family and colour set.
abstract final class AppTypography {
  /// Text styles for [family], coloured with [primary] and [muted].
  ///
  /// Sizes are shared across both languages; only the family changes, so a
  /// screen laid out in English keeps its proportions in Arabic.
  static TextTheme textTheme({
    required String family,
    required Color primary,
    required Color muted,
  }) {
    return TextTheme(
      // Display — hero numbers, price on ad details.
      displaySmall: TextStyle(
        fontFamily: family,
        fontSize: 28,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: primary,
      ),

      // Titles — screen headings, section headers, card titles.
      titleLarge: TextStyle(
        fontFamily: family,
        fontSize: 22,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontFamily: family,
        fontSize: 18,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleSmall: TextStyle(
        fontFamily: family,
        fontSize: 16,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: primary,
      ),

      // Body — the default reading styles.
      bodyLarge: TextStyle(
        fontFamily: family,
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: primary,
      ),
      bodyMedium: TextStyle(
        fontFamily: family,
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: primary,
      ),
      bodySmall: TextStyle(
        fontFamily: family,
        fontSize: 13,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: muted,
      ),

      // Labels — buttons, chips, tabs.
      labelLarge: TextStyle(
        fontFamily: family,
        fontSize: 16,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      labelMedium: TextStyle(
        fontFamily: family,
        fontSize: 14,
        height: 1.2,
        fontWeight: FontWeight.w500,
        color: primary,
      ),

      // Caption — timestamps, hints, metadata.
      labelSmall: TextStyle(
        fontFamily: family,
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w400,
        color: muted,
      ),
    );
  }
}
