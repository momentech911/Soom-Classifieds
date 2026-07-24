import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:soom_mobile/app/localization/direction_demo_screen.dart';
import 'package:soom_mobile/app/localization/generated/app_localizations.dart';
import 'package:soom_mobile/app/localization/locale_cubit.dart';
import 'package:soom_mobile/app/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Resolve the locale before the first frame so the app never flashes the
  // wrong language or direction.
  final LocaleCubit localeCubit = LocaleCubit();
  await localeCubit.load(
    deviceLocale: WidgetsBinding.instance.platformDispatcher.locale,
  );

  runApp(SoomApp(localeCubit: localeCubit));
}

/// Root of the SOOM app.
///
/// Routing lands in M0.5, at which point `home:` becomes the router config.
class SoomApp extends StatelessWidget {
  const SoomApp({required this.localeCubit, super.key});

  final LocaleCubit localeCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LocaleCubit>.value(
      value: localeCubit,
      child: BlocBuilder<LocaleCubit, Locale>(
        builder: (BuildContext context, Locale locale) {
          return MaterialApp(
            title: 'SOOM',
            debugShowCheckedModeBanner: false,

            // The theme is rebuilt per locale: the font family is resolved
            // from it (Cairo for Arabic, Manrope for English).
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

            home: const DirectionDemoScreen(),
          );
        },
      ),
    );
  }
}
