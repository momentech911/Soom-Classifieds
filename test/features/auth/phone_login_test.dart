import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soom_mobile/features/auth/domain/qatar_phone.dart';
import 'package:soom_mobile/features/auth/presentation/phone_login_cubit.dart';
import 'package:soom_mobile/features/auth/presentation/phone_login_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  PhoneLoginCubit cubitThat({
    Future<void> Function(QatarPhone)? requestOtp,
  }) {
    return PhoneLoginCubit(
      requestOtp: requestOtp ?? (QatarPhone _) async {},
    );
  }

  Future<PhoneLoginCubit> pumpLogin(
    WidgetTester tester, {
    PhoneLoginCubit? cubit,
    String languageCode = 'en',
    void Function(QatarPhone)? onCodeSent,
  }) async {
    final PhoneLoginCubit c = cubit ?? cubitThat();
    addTearDown(c.close);

    await pumpLocalized(
      tester,
      BlocProvider<PhoneLoginCubit>.value(
        value: c,
        child: PhoneLoginScreen(onCodeSent: onCodeSent),
      ),
      languageCode: languageCode,
    );
    return c;
  }

  group('cubit validation', () {
    test('Continue is disabled only while the field is empty', () {
      // Deliberately enabled for invalid input: tapping it is how the user
      // finds out what is wrong. A dead button explains nothing.
      final PhoneLoginCubit cubit = cubitThat();
      addTearDown(cubit.close);

      expect(cubit.state.canSubmit, isFalse);

      cubit.onInputChanged('5512');
      expect(cubit.state.canSubmit, isTrue);

      cubit.onInputChanged('55123456');
      expect(cubit.state.canSubmit, isTrue);
    });

    test('errors stay hidden until the first submit', () async {
      final PhoneLoginCubit cubit = cubitThat();
      addTearDown(cubit.close);

      cubit.onInputChanged('551');
      // Invalid, but saying so mid-typing is hostile.
      expect(cubit.state.error, QatarPhoneError.tooShort);
      expect(cubit.state.showsError, isFalse);

      await cubit.submit();
      expect(cubit.state.showsError, isTrue);
    });

    test('a landline is rejected as not-mobile', () {
      final PhoneLoginCubit cubit = cubitThat();
      addTearDown(cubit.close);

      cubit.onInputChanged('44123456');

      expect(cubit.state.error, QatarPhoneError.notMobile);
      expect(cubit.state.isValid, isFalse);
      // canSubmit stays true so tapping Continue surfaces the reason; the
      // guard against actually sending an OTP lives in submit().
      expect(cubit.state.canSubmit, isTrue);
    });

    test('submitting an invalid number does not call requestOtp', () async {
      bool called = false;
      final PhoneLoginCubit cubit = cubitThat(
        requestOtp: (QatarPhone _) async => called = true,
      );
      addTearDown(cubit.close);

      cubit.onInputChanged('123');
      await cubit.submit();

      expect(called, isFalse);
    });
  });

  group('cubit submission', () {
    test('a valid number requests the OTP and reports codeSent', () async {
      QatarPhone? sentTo;
      final PhoneLoginCubit cubit = cubitThat(
        requestOtp: (QatarPhone p) async => sentTo = p,
      );
      addTearDown(cubit.close);

      cubit.onInputChanged('+974 5512 3456');
      await cubit.submit();

      expect(sentTo?.e164, '+97455123456');
      expect(cubit.state.status, PhoneLoginStatus.codeSent);
    });

    test('rate limiting surfaces with its retry window', () async {
      final PhoneLoginCubit cubit = cubitThat(
        requestOtp: (QatarPhone _) async => throw const
            OtpRateLimitedException(retryAfter: Duration(seconds: 60)),
      );
      addTearDown(cubit.close);

      cubit.onInputChanged('55123456');
      await cubit.submit();

      expect(cubit.state.status, PhoneLoginStatus.rateLimited);
      expect(cubit.state.retryAfter, const Duration(seconds: 60));
    });

    test('network failure is distinct from a generic failure', () async {
      final PhoneLoginCubit cubit = cubitThat(
        requestOtp: (QatarPhone _) async => throw const OtpNetworkException(),
      );
      addTearDown(cubit.close);

      cubit.onInputChanged('55123456');
      await cubit.submit();

      expect(cubit.state.status, PhoneLoginStatus.networkError);
    });

    test('editing after a failure clears it', () async {
      final PhoneLoginCubit cubit = cubitThat(
        requestOtp: (QatarPhone _) async => throw const OtpNetworkException(),
      );
      addTearDown(cubit.close);

      cubit.onInputChanged('55123456');
      await cubit.submit();
      expect(cubit.state.status, PhoneLoginStatus.networkError);

      cubit.onInputChanged('55123457');
      expect(cubit.state.status, PhoneLoginStatus.editing);
    });
  });

  group('screen', () {
    testWidgets('shows +974 and never a country picker', (
      WidgetTester tester,
    ) async {
      await pumpLogin(tester);

      expect(find.text('+974'), findsOneWidget);
      // Qatar is fixed — a picker would be a scope violation.
      expect(find.byType(DropdownButton<String>), findsNothing);
    });

    testWidgets('Continue is dead only while the field is empty', (
      WidgetTester tester,
    ) async {
      await pumpLogin(tester);

      FilledButton button() => tester.widget(find.byType(FilledButton));
      expect(button().onPressed, isNull);

      await tester.enterText(find.byType(TextField), '55123456');
      await tester.pump();

      expect(button().onPressed, isNotNull);
    });

    testWidgets('an invalid number still reaches the user as an error', (
      WidgetTester tester,
    ) async {
      // The regression this guards: with Continue disabled for invalid input,
      // tapping did nothing and no message ever appeared.
      await pumpLogin(tester);

      await tester.enterText(find.byType(TextField), '5512');
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('Enter all 8 digits of your number.'), findsOneWidget);
    });

    testWidgets('reports the parsed number when the code is sent', (
      WidgetTester tester,
    ) async {
      QatarPhone? reported;
      await pumpLogin(tester, onCodeSent: (QatarPhone p) => reported = p);

      await tester.enterText(find.byType(TextField), '55123456');
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(reported?.e164, '+97455123456');
    });

    testWidgets('a landline shows the mobile-prefix error', (
      WidgetTester tester,
    ) async {
      await pumpLogin(tester);

      await tester.enterText(find.byType(TextField), '44123456');
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(
        find.text('Enter a Qatar mobile number starting with 3, 5, 6 or 7.'),
        findsOneWidget,
      );
    });
  });

  group('RTL', () {
    testWidgets('digits stay in logical order regardless of language', (
      WidgetTester tester,
    ) async {
      // UX Spec: "preserve logical number, phone and price readability."
      // The digit run must never be reordered by the RTL paragraph.
      for (final String code in <String>['ar', 'en']) {
        await pumpLogin(tester, languageCode: code);

        final TextField field = tester.widget(find.byType(TextField));
        expect(
          field.textDirection,
          TextDirection.ltr,
          reason: 'digits must render LTR in "$code"',
        );
      }
    });

    testWidgets('+974 sits on the leading edge: left in EN, right in AR', (
      WidgetTester tester,
    ) async {
      // Asserted by geometry rather than by eye. The approved S02 reference
      // shows +974 on the right in Arabic; an earlier version pinned the
      // whole field LTR, which forced it to the left and fought the layout.
      double prefixCentre(WidgetTester t) =>
          t.getCenter(find.text(QatarPhone.dialCode)).dx;
      double fieldCentre(WidgetTester t) =>
          t.getCenter(find.byType(TextField)).dx;

      await pumpLogin(tester, languageCode: 'en');
      expect(
        prefixCentre(tester),
        lessThan(fieldCentre(tester)),
        reason: 'English: +974 belongs on the left',
      );

      await pumpLogin(tester, languageCode: 'ar');
      expect(
        prefixCentre(tester),
        greaterThan(fieldCentre(tester)),
        reason: 'Arabic: +974 belongs on the right, per the S02 reference',
      );
    });

    testWidgets('body text mirrors to the right in Arabic', (
      WidgetTester tester,
    ) async {
      await pumpLogin(tester, languageCode: 'ar');

      final BuildContext screen = tester.element(find.byType(Scaffold));
      expect(Directionality.of(screen), TextDirection.rtl);
    });

    testWidgets('Arabic copy renders and layout does not overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpLogin(tester, languageCode: 'ar');

      // Wording matches the approved S02 Arabic reference.
      expect(find.text('سجّل الدخول برقم هاتفك'), findsOneWidget);
      expect(find.text('أدخل رقم هاتفك القطري.'), findsOneWidget);
      expect(find.text('متابعة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a number typed in Arabic-Indic digits is accepted', (
      WidgetTester tester,
    ) async {
      await pumpLogin(tester, languageCode: 'ar');

      await tester.enterText(find.byType(TextField), '٥٥١٢٣٤٥٦');
      await tester.pump();

      final FilledButton button = tester.widget(find.byType(FilledButton));
      expect(
        button.onPressed,
        isNotNull,
        reason: 'Arabic-Indic digits are a valid way to type the number',
      );
    });
  });
}
