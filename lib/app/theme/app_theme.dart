import 'package:flutter/material.dart';
import 'package:soom_mobile/app/theme/app_colors.dart';
import 'package:soom_mobile/app/theme/app_spacing.dart';
import 'package:soom_mobile/app/theme/app_typography.dart';

/// Builds SOOM's light and dark [ThemeData].
///
/// Both themes are locale-aware: the caller passes the active [Locale] so the
/// correct font family (Cairo for Arabic, Manrope for English) is baked into
/// the text theme. Rebuild the theme when the locale changes.
abstract final class AppTheme {
  /// Light theme for [locale].
  static ThemeData light(Locale locale) => _build(
        locale: locale,
        brightness: Brightness.light,
        background: AppColors.background,
        surface: AppColors.surface,
        textPrimary: AppColors.textPrimary,
        textMuted: AppColors.textMuted,
        border: AppColors.border,
        primary: AppColors.primary,
      );

  /// Dark theme for [locale].
  static ThemeData dark(Locale locale) => _build(
        locale: locale,
        brightness: Brightness.dark,
        background: AppColors.backgroundDark,
        surface: AppColors.surfaceDark,
        textPrimary: AppColors.textPrimaryDark,
        textMuted: AppColors.textMutedDark,
        border: AppColors.borderDark,
        // The token doc specifies primaryDark as the dark-mode brand colour.
        primary: AppColors.primaryDark,
      );

  static ThemeData _build({
    required Locale locale,
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color textPrimary,
    required Color textMuted,
    required Color border,
    required Color primary,
  }) {
    final String family = AppFonts.familyFor(locale);

    final TextTheme textTheme = AppTypography.textTheme(
      family: family,
      primary: textPrimary,
      muted: textMuted,
    );

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      onPrimary: AppColors.onPrimary,
      surface: surface,
      onSurface: textPrimary,
      error: AppColors.danger,
      outline: border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: family,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium,
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: border),
        ),
      ),

      // Primary buttons: filled maroon, white label, 12px radius.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: textTheme.labelMedium,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: textMuted),
        border: _inputBorder(border),
        enabledBorder: _inputBorder(border),
        focusedBorder: _inputBorder(primary, width: 1.5),
        errorBorder: _inputBorder(AppColors.danger),
        focusedErrorBorder: _inputBorder(AppColors.danger, width: 1.5),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: AppColors.primaryTint,
        side: BorderSide(color: border),
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
