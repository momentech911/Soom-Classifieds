import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soom_mobile/app/router/placeholder_screen.dart';
import 'package:soom_mobile/app/theme/app_colors.dart';
import 'package:soom_mobile/core/auth/auth_state.dart';
import 'package:soom_mobile/main.dart';

import 'helpers/pump_app.dart';

/// End-to-end boot test: the real [SoomApp], with router, theme and l10n.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('app boots to the bootstrap gate', (WidgetTester tester) async {
    await tester.pumpWidget(
      SoomApp(
        localeCubit: await localeCubitFor('en'),
        auth: AuthStateNotifier(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PlaceholderScreen), findsOneWidget);
    // Appears twice: the app bar title and the body label.
    expect(find.text('bootstrap'), findsNWidgets(2));
    expect(find.text('Planned in M0.7'), findsOneWidget);
  });

  testWidgets('theme tokens reach the widget tree', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      SoomApp(
        localeCubit: await localeCubitFor('en'),
        auth: AuthStateNotifier(),
      ),
    );
    await tester.pumpAndSettle();

    final ThemeData theme = Theme.of(tester.element(find.byType(Scaffold)));

    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
  });

  testWidgets('boots in Arabic with RTL direction', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      SoomApp(
        localeCubit: await localeCubitFor('ar'),
        auth: AuthStateNotifier(),
      ),
    );
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.byType(Scaffold));
    expect(Directionality.of(context), TextDirection.rtl);
  });
}
