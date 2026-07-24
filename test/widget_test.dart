import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soom_mobile/app/theme/app_colors.dart';
import 'package:soom_mobile/main.dart';

void main() {
  testWidgets('app boots and renders the themed placeholder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SoomApp());

    expect(find.text('SOOM'), findsOneWidget);
    expect(find.text('Phase 0 — theme'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('theme tokens reach the widget tree', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SoomApp());

    final BuildContext context = tester.element(
      find.byType(ThemePlaceholderScreen),
    );
    final ThemeData theme = Theme.of(context);

    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
  });

  testWidgets('renders without overflow in a narrow viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const SoomApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
