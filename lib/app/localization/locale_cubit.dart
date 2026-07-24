import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The locales SOOM ships. Arabic and English are both first-class.
abstract final class AppLocales {
  static const Locale arabic = Locale('ar');
  static const Locale english = Locale('en');

  /// Order matters: Arabic first, since SOOM is a Qatar product.
  static const List<Locale> supported = <Locale>[arabic, english];

  /// Used when the device locale is neither Arabic nor English.
  static const Locale fallback = english;

  /// Whether [code] is a language we support.
  static bool isSupported(String code) =>
      supported.any((Locale l) => l.languageCode == code);
}

/// Holds the active [Locale] and persists the user's choice.
///
/// Startup order:
/// 1. A locale the user previously picked, if any.
/// 2. Otherwise the device locale, when we support it.
/// 3. Otherwise [AppLocales.fallback].
///
/// Changing the locale re-themes the app, because the font family is resolved
/// from the locale — see `AppFonts.familyFor`.
class LocaleCubit extends Cubit<Locale> {
  /// [preferences] is injectable so tests can supply a mock store; in the app
  /// it is left null and resolved lazily on first use.
  LocaleCubit({SharedPreferences? preferences})
      : super(AppLocales.fallback) {
    _preferences = preferences;
  }

  static const String _storageKey = 'app_locale';

  SharedPreferences? _preferences;

  /// Resolves the startup locale. Call once, before the first frame.
  ///
  /// [deviceLocale] is normally `PlatformDispatcher.instance.locale`; it is a
  /// parameter so tests can drive it.
  Future<void> load({Locale? deviceLocale}) async {
    _preferences ??= await SharedPreferences.getInstance();

    final String? saved = _preferences?.getString(_storageKey);
    if (saved != null && AppLocales.isSupported(saved)) {
      emit(Locale(saved));
      return;
    }

    final String? deviceCode = deviceLocale?.languageCode;
    if (deviceCode != null && AppLocales.isSupported(deviceCode)) {
      emit(Locale(deviceCode));
      return;
    }

    emit(AppLocales.fallback);
  }

  /// Switches to [locale] and remembers it. Unsupported locales are ignored.
  Future<void> setLocale(Locale locale) async {
    if (!AppLocales.isSupported(locale.languageCode)) return;
    if (locale.languageCode == state.languageCode) return;

    emit(Locale(locale.languageCode));

    _preferences ??= await SharedPreferences.getInstance();
    await _preferences?.setString(_storageKey, locale.languageCode);
  }

  /// Flips between Arabic and English — the language toggle in Settings.
  Future<void> toggle() => setLocale(
        state.languageCode == AppLocales.arabic.languageCode
            ? AppLocales.english
            : AppLocales.arabic,
      );

  /// Whether the active locale reads right-to-left.
  bool get isRtl => state.languageCode == AppLocales.arabic.languageCode;
}
