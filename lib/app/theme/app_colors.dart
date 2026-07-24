import 'package:flutter/material.dart';

/// SOOM brand colour tokens — the single source of truth for the palette.
///
/// Sampled from the approved bilingual wireframe set and recorded in
/// `soom-docs/SOOM_Build_Plan_v1/05_Design_Tokens.md`. `primary` is the
/// confirmed brand maroon; the rest are the agreed defaults.
///
/// Never hardcode a `Color` in a screen — reference a token here, or read it
/// from `Theme.of(context).colorScheme`.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF881438);
  static const Color primaryDark = Color(0xFF6E1030);
  static const Color primaryTint = Color(0xFFF5E6EC);

  // Surfaces (light)
  static const Color background = Color(0xFFF6F6F3);
  static const Color surface = Color(0xFFFFFFFF);

  // Text (light)
  static const Color textPrimary = Color(0xFF303036);
  static const Color textMuted = Color(0xFF6B6B70);

  // Lines
  static const Color border = Color(0xFFE4E3DF);

  // Semantic
  static const Color warningBg = Color(0xFFFBF4E6);
  static const Color success = Color(0xFF1E7A4C);
  static const Color danger = Color(0xFFC0342B);

  // On-colour foregrounds
  static const Color onPrimary = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------
  // Dark mode
  //
  // The token doc defines the light palette only and specifies `primaryDark`
  // as the dark-mode primary. These are the derived dark surfaces — warm-
  // neutral to stay in family with the light theme rather than pure black.
  // Revisit if a dark-mode design lands.
  // ---------------------------------------------------------------------
  static const Color backgroundDark = Color(0xFF141416);
  static const Color surfaceDark = Color(0xFF1E1E21);
  static const Color textPrimaryDark = Color(0xFFF2F2F0);
  static const Color textMutedDark = Color(0xFFA0A0A6);
  static const Color borderDark = Color(0xFF33333A);
  static const Color warningBgDark = Color(0xFF3A3222);
}
