import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soom_mobile/app/bootstrap/bootstrap_cubit.dart';
import 'package:soom_mobile/app/router/app_routes.dart';
import 'package:soom_mobile/app/theme/app_colors.dart';
import 'package:soom_mobile/core/auth/auth_state.dart';
import 'package:soom_mobile/core/storage/app_preferences.dart';
import 'package:soom_mobile/main.dart';

import 'helpers/pump_app.dart';
import 'helpers/stub_adapter.dart';

/// End-to-end boot: the real [SoomApp] with router, theme, l10n and the gate.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  /// A healthy backend with no version floor.
  StubAdapter healthyBackend() => StubAdapter(
        routes: <String, StubResponse>{
          '/health': const StubResponse(
            statusCode: 200,
            body: <String, Object>{'status': 'ok'},
          ),
          '/config': const StubResponse(
            statusCode: 200,
            body: <String, Object>{},
          ),
        },
      );

  Future<Widget> buildApp({
    String languageCode = 'en',
    StubAdapter? adapter,
  }) async {
    final AuthStateNotifier auth =
        AuthStateNotifier(initial: AuthStatus.unknown);

    return SoomApp(
      localeCubit: await localeCubitFor(languageCode),
      auth: auth,
      bootstrapCubit: BootstrapCubit(
        apiClient: buildTestApiClient(adapter: adapter ?? healthyBackend()),
        preferences: await AppPreferences.create(),
        auth: auth,
        appVersionReader: () async => '1.0.0',
      ),
    );
  }

  testWidgets('app boots through the gate to home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    // The gate resolved and handed off to Home.
    expect(find.text(AppRoute.home.routeName), findsWidgets);
  });

  testWidgets('theme tokens reach the widget tree', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    final ThemeData theme = Theme.of(tester.element(find.byType(Scaffold)));

    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
  });

  testWidgets('boots in Arabic with RTL direction', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(await buildApp(languageCode: 'ar'));
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.byType(Scaffold));
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testWidgets('an unreachable backend holds the user on the gate', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      await buildApp(adapter: StubAdapter.single(statusCode: 500)),
    );
    await tester.pumpAndSettle();

    // Stays on the gate, offering a retry rather than proceeding.
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text(AppRoute.home.routeName), findsNothing);
  });

  testWidgets('force update blocks with no way past it', (
    WidgetTester tester,
  ) async {
    final StubAdapter adapter = StubAdapter(
      routes: <String, StubResponse>{
        '/health': const StubResponse(
          statusCode: 200,
          body: <String, Object>{'status': 'ok'},
        ),
        '/config': const StubResponse(
          statusCode: 200,
          body: <String, Object>{'minimum_supported_version': '9.9.9'},
        ),
      },
    );

    await tester.pumpWidget(await buildApp(adapter: adapter));
    await tester.pumpAndSettle();

    expect(find.text('Update required'), findsOneWidget);
    // No retry and no route change — the screen is a dead end by design.
    expect(find.text('Try again'), findsNothing);
    expect(find.text(AppRoute.home.routeName), findsNothing);
  });
}
