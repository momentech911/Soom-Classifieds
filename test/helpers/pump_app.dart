import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soom_mobile/app/localization/generated/app_localizations.dart';
import 'package:soom_mobile/app/localization/locale_cubit.dart';
import 'package:soom_mobile/app/theme/app_theme.dart';

/// Test helpers for pumping widgets with SOOM's theme and localization.

/// A [LocaleCubit] backed by a mock store, already loaded to [languageCode].
Future<LocaleCubit> localeCubitFor(String languageCode) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'app_locale': languageCode,
  });
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final LocaleCubit cubit = LocaleCubit(preferences: prefs);
  await cubit.load();
  return cubit;
}

/// Pumps [child] inside a themed, localized [MaterialApp].
///
/// Use this to test a single screen in isolation — it gives the real theme,
/// the real localizations and correct [Directionality], without the router.
/// Set [settle] false for screens that run a periodic timer.
///
/// `pumpAndSettle` advances the fake clock in 100ms steps for as long as
/// frames keep being scheduled. A one-second countdown reschedules forever,
/// so settling silently fast-forwards until every timer has run out — a
/// screen with a two-minute expiry arrives already expired, and assertions
/// fail for reasons that have nothing to do with the code under test.
Future<LocaleCubit> pumpLocalized(
  WidgetTester tester,
  Widget child, {
  String languageCode = 'en',
  LocaleCubit? cubit,
  bool settle = true,
}) async {
  final LocaleCubit localeCubit = cubit ?? await localeCubitFor(languageCode);

  await tester.pumpWidget(
    BlocProvider<LocaleCubit>.value(
      value: localeCubit,
      child: BlocBuilder<LocaleCubit, Locale>(
        builder: (BuildContext context, Locale locale) {
          return MaterialApp(
            theme: AppTheme.light(locale),
            darkTheme: AppTheme.dark(locale),
            locale: locale,
            supportedLocales: AppLocales.supported,
            localizationsDelegates: const <LocalizationsDelegate<Object>>[
              AppL10n.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: child,
          );
        },
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }

  return localeCubit;
}
