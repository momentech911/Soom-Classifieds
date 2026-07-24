import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soom_mobile/app/theme/app_colors.dart';
import 'package:soom_mobile/app/theme/app_theme.dart';
import 'package:soom_mobile/app/theme/app_typography.dart';

void main() {
  const Locale en = Locale('en');
  const Locale ar = Locale('ar');

  group('AppFonts.familyFor', () {
    test('resolves Cairo for Arabic and Manrope for English', () {
      expect(AppFonts.familyFor(ar), AppFonts.cairo);
      expect(AppFonts.familyFor(en), AppFonts.manrope);
    });

    test('falls back to Manrope for an unexpected locale', () {
      expect(AppFonts.familyFor(const Locale('fr')), AppFonts.manrope);
    });

    test('ignores country code, matching on language only', () {
      expect(AppFonts.familyFor(const Locale('ar', 'QA')), AppFonts.cairo);
      expect(AppFonts.familyFor(const Locale('en', 'US')), AppFonts.manrope);
    });
  });

  group('AppTheme.light', () {
    test('uses the brand maroon and warm off-white background', () {
      final ThemeData theme = AppTheme.light(en);

      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.onPrimary, AppColors.onPrimary);
      expect(theme.scaffoldBackgroundColor, AppColors.background);
      expect(theme.brightness, Brightness.light);
    });

    test('carries the locale font into the theme', () {
      expect(AppTheme.light(en).textTheme.bodyMedium?.fontFamily,
          AppFonts.manrope);
      expect(
          AppTheme.light(ar).textTheme.bodyMedium?.fontFamily, AppFonts.cairo);
    });

    test('maps error to the danger token', () {
      expect(AppTheme.light(en).colorScheme.error, AppColors.danger);
    });
  });

  group('AppTheme.dark', () {
    test('uses primaryDark and the dark surfaces', () {
      final ThemeData theme = AppTheme.dark(en);

      expect(theme.colorScheme.primary, AppColors.primaryDark);
      expect(theme.scaffoldBackgroundColor, AppColors.backgroundDark);
      expect(theme.brightness, Brightness.dark);
    });

    test('respects the locale font just as light does', () {
      expect(AppTheme.dark(ar).textTheme.bodyMedium?.fontFamily,
          AppFonts.cairo);
    });
  });

  group('component themes', () {
    test('text sizes are shared across languages so layouts hold', () {
      final TextTheme enText = AppTheme.light(en).textTheme;
      final TextTheme arText = AppTheme.light(ar).textTheme;

      expect(enText.bodyMedium?.fontSize, arText.bodyMedium?.fontSize);
      expect(enText.titleLarge?.fontSize, arText.titleLarge?.fontSize);
    });

    test('filled buttons are maroon with a white label', () {
      final ThemeData theme = AppTheme.light(en);
      final ButtonStyle? style = theme.filledButtonTheme.style;

      expect(
        style?.backgroundColor?.resolve(<WidgetState>{}),
        AppColors.primary,
      );
      expect(
        style?.foregroundColor?.resolve(<WidgetState>{}),
        AppColors.onPrimary,
      );
    });
  });
}
