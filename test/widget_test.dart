import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soom_mobile/app/localization/locale_cubit.dart';
import 'package:soom_mobile/app/theme/app_colors.dart';
import 'package:soom_mobile/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<LocaleCubit> buildCubit() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final LocaleCubit cubit = LocaleCubit(preferences: prefs);
    await cubit.load(deviceLocale: const Locale('en'));
    return cubit;
  }

  testWidgets('app boots and renders', (WidgetTester tester) async {
    await tester.pumpWidget(SoomApp(localeCubit: await buildCubit()));
    await tester.pumpAndSettle();

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('theme tokens reach the widget tree', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(SoomApp(localeCubit: await buildCubit()));
    await tester.pumpAndSettle();

    final ThemeData theme = Theme.of(tester.element(find.byType(Scaffold)));

    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
  });
}
