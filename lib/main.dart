import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:soom_mobile/app/bootstrap/bootstrap_cubit.dart';
import 'package:soom_mobile/app/localization/generated/app_localizations.dart';
import 'package:soom_mobile/app/localization/locale_cubit.dart';
import 'package:soom_mobile/app/router/app_router.dart';
import 'package:soom_mobile/app/theme/app_theme.dart';
import 'package:soom_mobile/core/api/api_client.dart';
import 'package:soom_mobile/core/api/api_config.dart';
import 'package:soom_mobile/core/api/connectivity_service.dart';
import 'package:soom_mobile/core/auth/auth_state.dart';
import 'package:soom_mobile/core/storage/app_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppPreferences preferences = await AppPreferences.create();

  // Resolve the locale before the first frame so the app never flashes the
  // wrong language or direction.
  final LocaleCubit localeCubit = LocaleCubit();
  await localeCubit.load(
    deviceLocale: WidgetsBinding.instance.platformDispatcher.locale,
  );

  // Auth starts unknown so the router holds every route on the gate until
  // the bootstrap cubit resolves it.
  final AuthStateNotifier auth =
      AuthStateNotifier(initial: AuthStatus.unknown);

  final ApiClient apiClient = ApiClient(
    config: ApiConfig.fromEnvironment(),
    connectivity: ConnectivityService(),
    localeCode: () => localeCubit.state.languageCode,
    onUnauthorized: auth.signOut,
  );

  runApp(
    SoomApp(
      localeCubit: localeCubit,
      auth: auth,
      bootstrapCubit: BootstrapCubit(
        apiClient: apiClient,
        preferences: preferences,
        auth: auth,
        appVersionReader: () async =>
            (await PackageInfo.fromPlatform()).version,
      ),
    ),
  );
}

/// Root of the SOOM app.
class SoomApp extends StatefulWidget {
  const SoomApp({
    required this.localeCubit,
    required this.auth,
    required this.bootstrapCubit,
    super.key,
  });

  final LocaleCubit localeCubit;
  final AuthStateNotifier auth;
  final BootstrapCubit bootstrapCubit;

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

    // Start the gate after the first frame, so the spinner is already on
    // screen when the checks begin.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.bootstrapCubit.run();
    });
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
      child: BlocProvider<BootstrapCubit>.value(
        value: widget.bootstrapCubit,
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
      ),
    );
  }
}
