import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soom_mobile/app/bootstrap/bootstrap_cubit.dart';
import 'package:soom_mobile/app/localization/generated/app_localizations.dart';
import 'package:soom_mobile/app/router/app_router.dart';
import 'package:soom_mobile/app/router/app_routes.dart';
import 'package:soom_mobile/app/router/placeholder_screen.dart';
import 'package:soom_mobile/core/auth/auth_state.dart';
import 'package:soom_mobile/core/storage/app_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../helpers/stub_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  /// Pumps the router with [auth], starting at [initialLocation].
  ///
  /// A [BootstrapCubit] is provided because route 1 is a real screen as of
  /// M0.7. It is never `run()` here, so it sits in its loading state and does
  /// not redirect — these tests are about the route table, not the gate.
  /// Set [settle] false when the destination shows an indefinite progress
  /// indicator — `pumpAndSettle` would spin forever waiting on it.
  Future<GoRouter> pumpRouter(
    WidgetTester tester, {
    required AuthStateNotifier auth,
    String? initialLocation,
    bool settle = true,
  }) async {
    final GoRouter router = AppRouter.create(
      auth: auth,
      initialLocation: initialLocation,
    );
    addTearDown(router.dispose);

    final BootstrapCubit bootstrapCubit = BootstrapCubit(
      apiClient: buildTestApiClient(
        adapter: StubAdapter.single(statusCode: 200),
      ),
      preferences: await AppPreferences.create(),
      auth: auth,
      appVersionReader: () async => '1.0.0',
    );
    addTearDown(bootstrapCubit.close);

    await tester.pumpWidget(
      BlocProvider<BootstrapCubit>.value(
        value: bootstrapCubit,
        child: MaterialApp.router(
          routerConfig: router,
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppL10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
    return router;
  }

  String currentPath(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.path;

  group('route table', () {
    test('has exactly the 19 routes the PRD freezes', () {
      expect(AppRoute.values.length, 19);
    });

    test('route names are unique', () {
      final Set<String> names =
          AppRoute.values.map((AppRoute r) => r.routeName).toSet();
      expect(names.length, AppRoute.values.length);
    });

    test('route paths are unique', () {
      final Set<String> paths =
          AppRoute.values.map((AppRoute r) => r.path).toSet();
      expect(paths.length, AppRoute.values.length);
    });

    test('every path starts with a slash', () {
      for (final AppRoute route in AppRoute.values) {
        expect(route.path, startsWith('/'), reason: route.routeName);
      }
    });

    test('guest-browsable routes are not protected', () {
      // Guests must be able to browse: golden rule, guest browsing stays open.
      const List<AppRoute> public = <AppRoute>[
        AppRoute.home,
        AppRoute.explore,
        AppRoute.advertisementDetails,
        AppRoute.mediaViewer,
        AppRoute.sellerProfile,
        AppRoute.contentViewer,
      ];
      for (final AppRoute route in public) {
        expect(
          protectedRoutes.contains(route),
          isFalse,
          reason: '${route.routeName} must stay public',
        );
      }
    });

    test('write and account routes are protected', () {
      const List<AppRoute> mustGuard = <AppRoute>[
        AppRoute.createEditAdvertisement,
        AppRoute.myAds,
        AppRoute.favorites,
        AppRoute.conversations,
        AppRoute.chat,
        AppRoute.notifications,
        AppRoute.settings,
      ];
      for (final AppRoute route in mustGuard) {
        expect(
          protectedRoutes.contains(route),
          isTrue,
          reason: '${route.routeName} must require auth',
        );
      }
    });
  });

  group('lookup helpers', () {
    test('routeForPath matches on the pattern', () {
      expect(AppRouter.routeForPath('/ad/:adId'),
          AppRoute.advertisementDetails);
      expect(AppRouter.routeForPath('/home'), AppRoute.home);
      expect(AppRouter.routeForPath('/nope'), isNull);
      expect(AppRouter.routeForPath(null), isNull);
    });

    test('routeForName matches on the name', () {
      expect(AppRouter.routeForName('chat'), AppRoute.chat);
      expect(AppRouter.routeForName('nope'), isNull);
      expect(AppRouter.routeForName(null), isNull);
    });
  });

  group('navigation', () {
    testWidgets('every public route renders its placeholder', (
      WidgetTester tester,
    ) async {
      final AuthStateNotifier auth = AuthStateNotifier();

      // Routes that have been built for real and no longer render a
      // placeholder. Remove an entry here as each screen lands.
      const Set<AppRoute> implemented = <AppRoute>{
        AppRoute.bootstrap, // M0.7
        AppRoute.phoneLogin, // M1.2
      };

      for (final AppRoute route in AppRoute.values) {
        if (protectedRoutes.contains(route)) continue;
        if (implemented.contains(route)) continue;

        // Substitute a value for any path parameter.
        final String location = route.path
            .replaceAll(':adId', '42')
            .replaceAll(':sellerId', '7')
            .replaceAll(':conversationId', '9')
            .replaceAll(':slug', 'terms');

        await pumpRouter(tester, auth: auth, initialLocation: location);

        expect(
          find.byType(PlaceholderScreen),
          findsOneWidget,
          reason: 'no placeholder for ${route.routeName} at $location',
        );
      }
    });

    testWidgets('path parameters are captured and displayed', (
      WidgetTester tester,
    ) async {
      await pumpRouter(
        tester,
        auth: AuthStateNotifier(),
        initialLocation: '/ad/12345',
      );

      expect(find.text('adId: 12345'), findsOneWidget);
    });

    testWidgets('an unknown location shows the not-found screen', (
      WidgetTester tester,
    ) async {
      await pumpRouter(
        tester,
        auth: AuthStateNotifier(),
        initialLocation: '/does-not-exist',
      );

      expect(find.text('No route for /does-not-exist'), findsOneWidget);
    });
  });

  group('guards', () {
    testWidgets('a guest is bounced from a protected route to login', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpRouter(
        tester,
        auth: AuthStateNotifier(),
        initialLocation: AppRoute.favorites.path,
      );

      expect(currentPath(router), AppRoute.phoneLogin.path);
    });

    testWidgets('a guest may browse public routes freely', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpRouter(
        tester,
        auth: AuthStateNotifier(),
        initialLocation: AppRoute.explore.path,
      );

      expect(currentPath(router), AppRoute.explore.path);
    });

    testWidgets('an incomplete profile funnels to profile completion', (
      WidgetTester tester,
    ) async {
      final AuthStateNotifier auth =
          AuthStateNotifier(initial: AuthStatus.needsProfile);

      final GoRouter router = await pumpRouter(
        tester,
        auth: auth,
        initialLocation: AppRoute.myAds.path,
      );

      expect(currentPath(router), AppRoute.profileCompletion.path);
    });

    testWidgets('profile completion itself does not redirect-loop', (
      WidgetTester tester,
    ) async {
      final AuthStateNotifier auth =
          AuthStateNotifier(initial: AuthStatus.needsProfile);

      final GoRouter router = await pumpRouter(
        tester,
        auth: auth,
        initialLocation: AppRoute.profileCompletion.path,
      );

      expect(currentPath(router), AppRoute.profileCompletion.path);
    });

    testWidgets('an authenticated user reaches protected routes', (
      WidgetTester tester,
    ) async {
      final AuthStateNotifier auth =
          AuthStateNotifier(initial: AuthStatus.authenticated);

      final GoRouter router = await pumpRouter(
        tester,
        auth: auth,
        initialLocation: AppRoute.favorites.path,
      );

      expect(currentPath(router), AppRoute.favorites.path);
    });

    testWidgets('an authenticated user is kept off the login screen', (
      WidgetTester tester,
    ) async {
      final AuthStateNotifier auth =
          AuthStateNotifier(initial: AuthStatus.authenticated);

      final GoRouter router = await pumpRouter(
        tester,
        auth: auth,
        initialLocation: AppRoute.phoneLogin.path,
      );

      expect(currentPath(router), AppRoute.home.path);
    });

    testWidgets('signing out of a protected route bounces immediately', (
      WidgetTester tester,
    ) async {
      final AuthStateNotifier auth =
          AuthStateNotifier(initial: AuthStatus.authenticated);

      final GoRouter router = await pumpRouter(
        tester,
        auth: auth,
        initialLocation: AppRoute.favorites.path,
      );
      expect(currentPath(router), AppRoute.favorites.path);

      auth.signOut();
      await tester.pumpAndSettle();

      expect(currentPath(router), AppRoute.phoneLogin.path);
    });

    testWidgets('an unresolved session is held on the gate', (
      WidgetTester tester,
    ) async {
      final AuthStateNotifier auth =
          AuthStateNotifier(initial: AuthStatus.unknown);

      final GoRouter router = await pumpRouter(
        tester,
        auth: auth,
        initialLocation: AppRoute.home.path,
        // The gate shows an indefinite spinner; do not wait for it to settle.
        settle: false,
      );

      expect(currentPath(router), AppRoute.bootstrap.path);
    });
  });

  group('AuthStateNotifier', () {
    test('reports sign-in state correctly per status', () {
      expect(AuthStateNotifier(initial: AuthStatus.guest).isSignedIn, isFalse);
      expect(
        AuthStateNotifier(initial: AuthStatus.needsProfile).isSignedIn,
        isTrue,
      );
      expect(
        AuthStateNotifier(initial: AuthStatus.authenticated).isFullyOnboarded,
        isTrue,
      );
      expect(
        AuthStateNotifier(initial: AuthStatus.needsProfile).isFullyOnboarded,
        isFalse,
      );
      expect(
        AuthStateNotifier(initial: AuthStatus.unknown).isResolving,
        isTrue,
      );
    });

    test('notifies listeners only on a real change', () {
      final AuthStateNotifier auth =
          AuthStateNotifier(initial: AuthStatus.guest);
      int calls = 0;
      auth.addListener(() => calls++);

      auth.status = AuthStatus.guest;
      expect(calls, 0);

      auth.status = AuthStatus.authenticated;
      expect(calls, 1);
    });
  });
}
