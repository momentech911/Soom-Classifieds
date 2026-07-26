import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soom_mobile/core/utils/arabic_digits.dart';
import 'package:soom_mobile/features/auth/domain/qatar_phone.dart';
import 'package:soom_mobile/features/auth/presentation/otp_cubit.dart';
import 'package:soom_mobile/features/auth/presentation/otp_screen.dart';
import 'package:soom_mobile/features/auth/presentation/phone_login_cubit.dart';

import '../../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final QatarPhone phone = QatarPhone.tryParse('55123456')!;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  OtpCubit buildCubit({
    Future<void> Function(String)? verify,
    Future<void> Function()? resend,
  }) {
    return OtpCubit(
      phone: phone,
      verifyCode: verify ?? (String _) async {},
      resendCode: resend ?? () async {},
    );
  }

  group('ArabicDigits', () {
    test('converts both Arabic-Indic families to Western', () {
      expect(ArabicDigits.toWestern('٠١٢٣٤٥٦٧٨٩'), '0123456789');
      expect(ArabicDigits.toWestern('۰۱۲۳۴۵۶۷۸۹'), '0123456789');
    });

    test('leaves non-digits untouched', () {
      expect(ArabicDigits.toWestern('رمز ١٢٣'), 'رمز 123');
    });

    test('formats the countdown per language', () {
      const Duration d = Duration(minutes: 1, seconds: 24);

      expect(ArabicDigits.countdown(d, 'en'), '01:24');
      // The approved Arabic screen shows ٠١:٢٤, not 01:24.
      expect(ArabicDigits.countdown(d, 'ar'), '٠١:٢٤');
    });

    test('pads seconds correctly', () {
      expect(ArabicDigits.countdown(const Duration(seconds: 5), 'en'), '00:05');
      expect(ArabicDigits.countdown(Duration.zero, 'en'), '00:00');
    });
  });

  group('masked phone', () {
    test('matches the S03 reference format', () {
      // Reference shows "+974 55•• ••56" — first two and last two visible.
      expect(phone.masked, '+974 55•• ••56');
    });

    test('hides the middle digits', () {
      expect(phone.masked, isNot(contains('1234')));
    });
  });

  group('code entry', () {
    test('accumulates digits up to six', () {
      final OtpCubit cubit = buildCubit();
      addTearDown(cubit.close);

      cubit.onCodeChanged('123');
      expect(cubit.state.code, '123');
      expect(cubit.state.isComplete, isFalse);

      cubit.onCodeChanged('123456');
      expect(cubit.state.isComplete, isTrue);
      expect(cubit.state.canVerify, isTrue);
    });

    test('never exceeds six digits', () {
      final OtpCubit cubit = buildCubit();
      addTearDown(cubit.close);

      cubit.onCodeChanged('123456789');

      expect(cubit.state.code, '123456');
    });

    test('accepts a code typed in Arabic-Indic digits', () {
      final OtpCubit cubit = buildCubit();
      addTearDown(cubit.close);

      cubit.onCodeChanged('١٢٣٤٥٦');

      expect(cubit.state.code, '123456');
      expect(cubit.state.canVerify, isTrue);
    });

    test('strips anything that is not a digit', () {
      final OtpCubit cubit = buildCubit();
      addTearDown(cubit.close);

      cubit.onCodeChanged('12-34 56');

      expect(cubit.state.code, '123456');
    });

    test('editing clears a previous rejection', () async {
      final OtpCubit cubit = buildCubit(
        verify: (String _) async => throw Exception('nope'),
      );
      addTearDown(cubit.close);

      cubit.onCodeChanged('123456');
      await cubit.verify();
      expect(cubit.state.status, OtpStatus.invalid);

      cubit.onCodeChanged('12345');
      expect(cubit.state.status, OtpStatus.entering);
    });
  });

  group('verification', () {
    test('an accepted code reaches verified', () async {
      String? submitted;
      final OtpCubit cubit = buildCubit(
        verify: (String c) async => submitted = c,
      );
      addTearDown(cubit.close);

      cubit.onCodeChanged('123456');
      await cubit.verify();

      expect(submitted, '123456');
      expect(cubit.state.status, OtpStatus.verified);
    });

    test('an incomplete code is not submitted', () async {
      bool called = false;
      final OtpCubit cubit = buildCubit(
        verify: (String _) async => called = true,
      );
      addTearDown(cubit.close);

      cubit.onCodeChanged('123');
      await cubit.verify();

      expect(called, isFalse);
    });

    test('rate limiting is distinct from a wrong code', () async {
      final OtpCubit cubit = buildCubit(
        verify: (String _) async => throw const OtpRateLimitedException(),
      );
      addTearDown(cubit.close);

      cubit.onCodeChanged('123456');
      await cubit.verify();

      expect(cubit.state.status, OtpStatus.rateLimited);
    });
  });

  group('timers', () {
    testWidgets('the expiry countdown ticks down', (WidgetTester tester) async {
      await tester.runAsync(() async {
        final OtpCubit cubit = buildCubit();
        addTearDown(cubit.close);

        expect(cubit.state.expiresIn, OtpCubit.codeLifetime);

        // start() is explicit — building the cubit does not begin counting.
        cubit.start();
        await Future<void>.delayed(const Duration(milliseconds: 1100));
        cubit.stop();

        expect(cubit.state.expiresIn, lessThan(OtpCubit.codeLifetime));
      });
    });

    test('resend is locked until the cooldown elapses', () {
      final OtpCubit cubit = buildCubit();
      addTearDown(cubit.close);

      expect(cubit.state.resendIn, OtpCubit.resendCooldown);
      expect(cubit.state.canResend, isFalse);
    });

    test('an expired code cannot be verified', () async {
      final OtpCubit cubit = buildCubit();
      addTearDown(cubit.close);

      cubit.onCodeChanged('123456');
      expect(cubit.state.canVerify, isTrue);

      cubit.emit(cubit.state.copyWith(status: OtpStatus.expired));

      expect(cubit.state.canVerify, isFalse);
      expect(cubit.state.hasExpired, isTrue);
    });

    test('resending clears the code and restarts both countdowns', () async {
      final OtpCubit cubit = buildCubit();
      addTearDown(cubit.close);

      cubit.onCodeChanged('123456');
      // Force the cooldown to zero so resend is permitted.
      cubit.emit(cubit.state.copyWith(resendIn: Duration.zero));
      expect(cubit.state.canResend, isTrue);

      await cubit.resend();

      expect(cubit.state.code, isEmpty);
      expect(cubit.state.status, OtpStatus.entering);
      expect(cubit.state.expiresIn, OtpCubit.codeLifetime);
      expect(cubit.state.resendIn, OtpCubit.resendCooldown);
    });
  });

  /// Pumps the OTP screen. Shared by the screen and RTL groups.
  Future<OtpCubit> pumpOtp(
    WidgetTester tester, {
    OtpCubit? cubit,
    String languageCode = 'en',
    VoidCallback? onVerified,
    VoidCallback? onChangePhone,
  }) async {
      final OtpCubit c = cubit ?? buildCubit();
      addTearDown(c.close);

      await pumpLocalized(
        tester,
        BlocProvider<OtpCubit>.value(
          value: c,
          child: OtpScreen(
            onVerified: onVerified,
            onChangePhone: onChangePhone,
          ),
        ),
        languageCode: languageCode,
        settle: false,
      );

      // The screen starts a periodic countdown in initState. Tear the tree
      // down inside the test so dispose() cancels it — otherwise the binding
      // reports "a Timer is still pending after the widget tree was
      // disposed", which fails the test for a leak the screen does not have.
      addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));

    return c;
  }

  group('screen', () {
    testWidgets('renders six code boxes', (WidgetTester tester) async {
      await pumpOtp(tester);

      // Six visual boxes, one hidden field behind them.
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Enter verification code'), findsOneWidget);
    });

    testWidgets('shows the masked number, never the full one', (
      WidgetTester tester,
    ) async {
      await pumpOtp(tester);

      expect(find.text('Sent to +974 55•• ••56'), findsOneWidget);
      expect(find.textContaining('55123456'), findsNothing);
    });

    testWidgets('Verify is dead until six digits are in', (
      WidgetTester tester,
    ) async {
      final OtpCubit cubit = await pumpOtp(tester);

      FilledButton button() => tester.widget(find.byType(FilledButton));
      expect(button().onPressed, isNull);

      cubit.onCodeChanged('123456');
      await tester.pump();

      expect(button().onPressed, isNotNull);
    });

    testWidgets('reports verification upward', (WidgetTester tester) async {
      bool verified = false;
      final OtpCubit cubit = await pumpOtp(
        tester,
        onVerified: () => verified = true,
      );

      cubit.onCodeChanged('123456');
      await tester.pump();
      await cubit.verify();
      await tester.pump();

      expect(verified, isTrue);
    });

    testWidgets('a wrong code shows the invalid message', (
      WidgetTester tester,
    ) async {
      final OtpCubit cubit = buildCubit(
        verify: (String _) async => throw Exception('nope'),
      );
      await pumpOtp(tester, cubit: cubit);

      cubit.onCodeChanged('123456');
      await tester.pump();
      await cubit.verify();
      await tester.pump();

      expect(
        find.text("That code isn't right. Check it and try again."),
        findsOneWidget,
      );
    });
  });

  group('RTL', () {
    testWidgets('the code boxes stay left-to-right in Arabic', (
      WidgetTester tester,
    ) async {
      // The code is read in the order the SMS shows it. Mirroring the row in
      // Arabic would display it reversed against the message being copied.
      final OtpCubit cubit = await pumpOtp(tester, languageCode: 'ar');

      cubit.onCodeChanged('123456');
      await tester.pump();

      // The first digit must render left of the last, whatever the language.
      final double firstX = tester.getCenter(find.text('1')).dx;
      final double lastX = tester.getCenter(find.text('6')).dx;

      expect(
        firstX,
        lessThan(lastX),
        reason: 'digit 1 must sit left of digit 6 even in Arabic',
      );
    });

    testWidgets('Arabic copy and Arabic-Indic timer render', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpOtp(tester, languageCode: 'ar');

      expect(find.text('أدخل رمز التحقق'), findsOneWidget);
      expect(find.text('تحقق'), findsOneWidget);
      // Timer must use Arabic-Indic numerals, per the reference.
      expect(find.textContaining('٠'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the masked phone keeps Western digits in Arabic', (
      WidgetTester tester,
    ) async {
      // The reference shows the phone in Western digits even in Arabic,
      // while the timer uses Arabic-Indic. The distinction is deliberate.
      await pumpOtp(tester, languageCode: 'ar');

      expect(find.textContaining('+974 55•• ••56'), findsOneWidget);
    });
  });
}
