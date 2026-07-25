import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:soom_mobile/app/bootstrap/bootstrap_screen.dart';
import 'package:soom_mobile/app/localization/direction_demo_screen.dart';
import 'package:soom_mobile/features/auth/domain/qatar_phone.dart';
import 'package:soom_mobile/features/auth/presentation/phone_login_cubit.dart';
import 'package:soom_mobile/features/auth/presentation/phone_login_screen.dart';
import 'package:soom_mobile/app/router/app_routes.dart';
import 'package:soom_mobile/app/router/placeholder_screen.dart';
import 'package:soom_mobile/core/auth/auth_state.dart';

/// Builds the app's [GoRouter].
///
/// Declarative, typed and guarded — deliberately *not* the template's global
/// named-route switch (golden rule #3).
///
/// Every route is a [PlaceholderScreen] for now; each is swapped for its real
/// screen in the phase that owns it.
abstract final class AppRouter {
  /// Creates the router, guarded by [auth].
  ///
  /// [initialLocation] is overridable for tests.
  static GoRouter create({
    required AuthStateNotifier auth,
    String? initialLocation,
  }) {
    return GoRouter(
      initialLocation: initialLocation ?? AppRoute.bootstrap.path,
      // Re-run redirects whenever auth changes, so signing out of a protected
      // screen bounces immediately.
      refreshListenable: auth,
      redirect: (BuildContext context, GoRouterState state) =>
          _guard(auth: auth, state: state),
      errorBuilder: (BuildContext context, GoRouterState state) =>
          _RouteNotFoundScreen(location: state.uri.toString()),
      routes: <RouteBase>[
        // Route 1 is real as of M0.7 — the rest are still placeholders.
        GoRoute(
          path: AppRoute.bootstrap.path,
          name: AppRoute.bootstrap.routeName,
          builder: (BuildContext context, GoRouterState state) =>
              const BootstrapScreen(),
        ),
        // Route 2 is real as of M1.2. The cubit is provided here rather than
        // app-wide: it is scoped to this screen and should reset when the
        // user leaves. requestOtp is a stub until Firebase lands in M1.1.
        GoRoute(
          path: AppRoute.phoneLogin.path,
          name: AppRoute.phoneLogin.routeName,
          builder: (BuildContext context, GoRouterState state) {
            return BlocProvider<PhoneLoginCubit>(
              create: (_) => PhoneLoginCubit(
                requestOtp: (QatarPhone phone) async {
                  throw UnimplementedError(
                    'Firebase phone auth arrives in M1.1',
                  );
                },
              ),
              child: PhoneLoginScreen(
                onCodeSent: (QatarPhone phone) => context.goNamed(
                  AppRoute.otpVerification.routeName,
                  // The OTP screen needs the number it was sent to.
                  extra: phone,
                ),
              ),
            );
          },
        ),
        _route(AppRoute.otpVerification, plannedIn: 'M1.3'),
        _route(AppRoute.profileCompletion, plannedIn: 'M1.5'),

        _route(AppRoute.home, plannedIn: 'M3.1'),
        _route(AppRoute.explore, plannedIn: 'M3.2'),
        _route(AppRoute.advertisementDetails, plannedIn: 'M3.3'),
        _route(AppRoute.mediaViewer, plannedIn: 'M3.3'),

        _route(AppRoute.createEditAdvertisement, plannedIn: 'M4.1'),
        _route(AppRoute.myAds, plannedIn: 'M4.5'),

        _route(AppRoute.favorites, plannedIn: 'M5.1'),
        _route(AppRoute.conversations, plannedIn: 'M5.2'),
        _route(AppRoute.chat, plannedIn: 'M5.2'),
        _route(AppRoute.notifications, plannedIn: 'M5.4'),

        _route(AppRoute.myProfile, plannedIn: 'M6.2'),
        _route(AppRoute.editProfile, plannedIn: 'M6.2'),
        _route(AppRoute.sellerProfile, plannedIn: 'M3.4'),
        _route(AppRoute.settings, plannedIn: 'M6.1'),
        _route(AppRoute.contentViewer, plannedIn: 'M6.3'),

        // Dev-only: the M0.4 RTL/LTR smoke-test screen. Not one of the 19
        // product routes; remove once real screens exercise both directions.
        GoRoute(
          path: devDirectionDemoPath,
          name: devDirectionDemoName,
          builder: (BuildContext context, GoRouterState state) =>
              const DirectionDemoScreen(),
        ),
      ],
    );
  }

  /// Path of the dev-only direction demo.
  static const String devDirectionDemoPath = '/dev/direction';

  /// Route name of the dev-only direction demo.
  static const String devDirectionDemoName = 'devDirectionDemo';

  static GoRoute _route(AppRoute route, {String? plannedIn}) {
    return GoRoute(
      path: route.path,
      name: route.routeName,
      builder: (BuildContext context, GoRouterState state) =>
          PlaceholderScreen(
        route: route,
        pathParameters: state.pathParameters,
        plannedIn: plannedIn,
      ),
    );
  }

  /// Guard stub (M0.5).
  ///
  /// Guest browsing stays open; protected routes bounce to login. Real
  /// enforcement, including returning the user to where they were headed,
  /// lands with the auth cubit in M1.6.
  ///
  /// Returns the location to redirect to, or null to allow.
  static String? _guard({
    required AuthStateNotifier auth,
    required GoRouterState state,
  }) {
    // Session restore in flight — hold on the gate rather than guessing.
    if (auth.isResolving) {
      return state.matchedLocation == AppRoute.bootstrap.path
          ? null
          : AppRoute.bootstrap.path;
    }

    // Match on the route pattern (`/ad/:adId`), which go_router populates for
    // every matched route — more reliable than the optional name.
    final AppRoute? target = routeForPath(state.fullPath) ??
        routeForName(state.name);
    if (target == null) return null;

    final bool needsAuth = protectedRoutes.contains(target);

    if (needsAuth && !auth.isSignedIn) {
      return AppRoute.phoneLogin.path;
    }

    // Signed in but the profile is incomplete: everything protected funnels
    // to profile completion first. The completion screen itself is exempt,
    // otherwise the redirect would loop.
    if (needsAuth &&
        auth.status == AuthStatus.needsProfile &&
        target != AppRoute.profileCompletion) {
      return AppRoute.profileCompletion.path;
    }

    // Already signed in — no reason to sit on the auth screens.
    if (auth.isFullyOnboarded &&
        (target == AppRoute.phoneLogin ||
            target == AppRoute.otpVerification ||
            target == AppRoute.profileCompletion)) {
      return AppRoute.home.path;
    }

    return null;
  }

  /// The [AppRoute] with this [name], or null if it is not a product route.
  static AppRoute? routeForName(String? name) {
    if (name == null) return null;
    for (final AppRoute route in AppRoute.values) {
      if (route.routeName == name) return route;
    }
    return null;
  }

  /// The [AppRoute] whose pattern is [path], or null.
  ///
  /// Expects the pattern (`/ad/:adId`), not a resolved location (`/ad/12`).
  static AppRoute? routeForPath(String? path) {
    if (path == null) return null;
    for (final AppRoute route in AppRoute.values) {
      if (route.path == path) return route;
    }
    return null;
  }
}

/// Shown when a location matches no route.
class _RouteNotFoundScreen extends StatelessWidget {
  const _RouteNotFoundScreen({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(
        child: Text(
          'No route for $location',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
