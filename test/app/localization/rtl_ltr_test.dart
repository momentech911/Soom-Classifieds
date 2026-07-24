import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soom_mobile/app/localization/direction_demo_screen.dart';
import 'package:soom_mobile/app/localization/locale_cubit.dart';
import 'package:soom_mobile/app/theme/app_typography.dart';

import '../../helpers/pump_app.dart';

/// The AR/EN direction contract, asserted rather than eyeballed.
///
/// Golden rule #4 says every screen must render correctly in both RTL and LTR.
/// These tests hold the rails to that: Arabic must resolve to
/// [TextDirection.rtl] and the Cairo font, English to LTR and Manrope.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('Arabic renders right-to-left', (WidgetTester tester) async {
    await pumpLocalized(
      tester,
      const DirectionDemoScreen(),
      languageCode: 'ar',
    );

    final BuildContext context = tester.element(find.byType(Scaffold));
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testWidgets('English renders left-to-right', (WidgetTester tester) async {
    await pumpLocalized(
      tester,
      const DirectionDemoScreen(),
      languageCode: 'en',
    );

    final BuildContext context = tester.element(find.byType(Scaffold));
    expect(Directionality.of(context), TextDirection.ltr);
  });

  testWidgets('switching locale flips direction and font live', (
    WidgetTester tester,
  ) async {
    final LocaleCubit cubit = await pumpLocalized(
      tester,
      const DirectionDemoScreen(),
      languageCode: 'en',
    );

    BuildContext context = tester.element(find.byType(Scaffold));
    expect(Directionality.of(context), TextDirection.ltr);
    expect(
      Theme.of(context).textTheme.bodyMedium?.fontFamily,
      AppFonts.manrope,
    );

    await cubit.toggle();
    await tester.pumpAndSettle();

    context = tester.element(find.byType(Scaffold));
    expect(Directionality.of(context), TextDirection.rtl);
    expect(Theme.of(context).textTheme.bodyMedium?.fontFamily, AppFonts.cairo);
  });

  testWidgets('Arabic copy is rendered, not English', (
    WidgetTester tester,
  ) async {
    await pumpLocalized(
      tester,
      const DirectionDemoScreen(),
      languageCode: 'ar',
    );

    expect(find.text('فحص الاتجاه'), findsOneWidget);
    expect(find.text('سوم'), findsWidgets);
    expect(find.text('Direction check'), findsNothing);
  });

  testWidgets('English copy is rendered for the English locale', (
    WidgetTester tester,
  ) async {
    await pumpLocalized(
      tester,
      const DirectionDemoScreen(),
      languageCode: 'en',
    );

    expect(find.text('Direction check'), findsOneWidget);
    expect(find.text('فحص الاتجاه'), findsNothing);
  });

  testWidgets('Arabic plurals use the correct category', (
    WidgetTester tester,
  ) async {
    await pumpLocalized(
      tester,
      const DirectionDemoScreen(),
      languageCode: 'ar',
    );

    // Arabic distinguishes zero / one / two, unlike English.
    expect(find.text('لا توجد إعلانات'), findsOneWidget);
    expect(find.text('إعلان واحد'), findsOneWidget);
    expect(find.text('إعلانان'), findsOneWidget);
  });

  testWidgets('English plurals read correctly', (WidgetTester tester) async {
    await pumpLocalized(
      tester,
      const DirectionDemoScreen(),
      languageCode: 'en',
    );

    expect(find.text('No listings'), findsOneWidget);
    expect(find.text('1 listing'), findsOneWidget);
    expect(find.text('2 listings'), findsOneWidget);
  });

  testWidgets('both directions render without overflow on a small screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    for (final String code in <String>['ar', 'en']) {
      await pumpLocalized(
        tester,
        const DirectionDemoScreen(),
        languageCode: code,
      );

      expect(tester.takeException(), isNull, reason: 'overflow in "$code"');
    }
  });
}
