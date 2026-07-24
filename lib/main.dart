import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:soom_mobile/app/localization/generated/app_localizations.dart';
import 'package:soom_mobile/app/localization/locale_cubit.dart';
import 'package:soom_mobile/app/router/app_router.dart';
import 'package:soom_mobile/app/theme/app_theme.dart';
import 'package:soom_mobile/core/auth/auth_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Resolve the locale before the first frame so the app never flashes the
  // wrong language or direction.
  final LocaleCubit localeCubit = LocaleCubit();
  await localeCubit.load(
    deviceLocale: WidgetsBinding.instance.platformDispatcher.locale,
  );

  runApp(SoomApp(localeCubit: localeCubit, auth: AuthStateNotifier()));
}

/// Root of the SOOM app.
class SoomApp extends StatefulWidget {
  const SoomApp({required this.localeCubit, required this.auth, super.key});

  final LocaleCubit localeCubit;
  final AuthStateNotifier auth;

  @override
  State<SoomApp> createState() => _SoomAppState();
}

class _SoomAppState extends State<SoomApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Built once and kept: rebuilding a GoRouter would drop the nav stack.
    // It is locale-independent, so switching language does not disturb it.
    _router = AppRouter.create(auth: widget.auth);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LocaleCubit>.value(
      value: widget.localeCubit,
      child: BlocBuilder<LocaleCubit, Locale>(
        builder: (BuildContext context, Locale locale) {
          return MaterialApp.router(
            title: 'SOOM',
            debugShowCheckedModeBanner: false,

            // Rebuilt per locale: the font family is derived from it.
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

            routerConfig: _router,
          );
        },
      ),
    );
  }
}
