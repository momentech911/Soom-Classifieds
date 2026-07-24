import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soom_mobile/app/localization/locale_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<LocaleCubit> buildCubit() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return LocaleCubit(preferences: prefs);
  }

  group('AppLocales', () {
    test('supports Arabic and English, Arabic listed first', () {
      expect(AppLocales.supported, <Locale>[
        AppLocales.arabic,
        AppLocales.english,
      ]);
    });

    test('recognises supported language codes', () {
      expect(AppLocales.isSupported('ar'), isTrue);
      expect(AppLocales.isSupported('en'), isTrue);
      expect(AppLocales.isSupported('fr'), isFalse);
    });
  });

  group('load', () {
    test('prefers a previously saved locale', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'app_locale': 'ar',
      });
      final LocaleCubit cubit = await buildCubit();

      await cubit.load(deviceLocale: const Locale('en'));

      expect(cubit.state, AppLocales.arabic);
    });

    test('falls back to the device locale when nothing is saved', () async {
      final LocaleCubit cubit = await buildCubit();

      await cubit.load(deviceLocale: const Locale('ar'));

      expect(cubit.state, AppLocales.arabic);
    });

    test('uses English when the device locale is unsupported', () async {
      final LocaleCubit cubit = await buildCubit();

      await cubit.load(deviceLocale: const Locale('fr'));

      expect(cubit.state, AppLocales.english);
    });

    test('ignores a saved value that is no longer supported', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'app_locale': 'de',
      });
      final LocaleCubit cubit = await buildCubit();

      await cubit.load(deviceLocale: const Locale('fr'));

      expect(cubit.state, AppLocales.english);
    });

    test('matches on language, ignoring country', () async {
      final LocaleCubit cubit = await buildCubit();

      await cubit.load(deviceLocale: const Locale('ar', 'QA'));

      expect(cubit.state, AppLocales.arabic);
    });
  });

  group('setLocale', () {
    test('switches and persists the choice', () async {
      final LocaleCubit cubit = await buildCubit();
      await cubit.load(deviceLocale: const Locale('en'));

      await cubit.setLocale(AppLocales.arabic);

      expect(cubit.state, AppLocales.arabic);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), 'ar');
    });

    test('ignores unsupported locales', () async {
      final LocaleCubit cubit = await buildCubit();
      await cubit.load(deviceLocale: const Locale('en'));

      await cubit.setLocale(const Locale('fr'));

      expect(cubit.state, AppLocales.english);
    });

    test('does not re-emit when the locale is unchanged', () async {
      final LocaleCubit cubit = await buildCubit();
      await cubit.load(deviceLocale: const Locale('en'));

      final List<Locale> emitted = <Locale>[];
      final subscription = cubit.stream.listen(emitted.add);

      await cubit.setLocale(AppLocales.english);
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(emitted, isEmpty);
    });
  });

  group('toggle', () {
    test('flips English to Arabic and back', () async {
      final LocaleCubit cubit = await buildCubit();
      await cubit.load(deviceLocale: const Locale('en'));

      await cubit.toggle();
      expect(cubit.state, AppLocales.arabic);
      expect(cubit.isRtl, isTrue);

      await cubit.toggle();
      expect(cubit.state, AppLocales.english);
      expect(cubit.isRtl, isFalse);
    });
  });
}
