import 'package:flutter_test/flutter_test.dart';
import 'package:soom_mobile/features/auth/domain/qatar_phone.dart';

void main() {
  group('validate', () {
    test('accepts every Qatari mobile prefix', () {
      for (final String prefix in <String>['3', '5', '6', '7']) {
        expect(
          QatarPhone.validate('${prefix}5123456'),
          isNull,
          reason: 'prefix $prefix should be valid',
        );
      }
    });

    test('rejects landlines, which cannot receive SMS', () {
      // Qatari landlines start with 4. Accepting one would send the user to
      // an OTP screen waiting for a code that can never arrive.
      expect(QatarPhone.validate('44123456'), QatarPhoneError.notMobile);
    });

    test('rejects other non-mobile leading digits', () {
      for (final String prefix in <String>['0', '1', '2', '8', '9']) {
        expect(
          QatarPhone.validate('${prefix}5123456'),
          QatarPhoneError.notMobile,
          reason: 'prefix $prefix should be rejected',
        );
      }
    });

    test('distinguishes empty, short and long', () {
      expect(QatarPhone.validate(''), QatarPhoneError.empty);
      expect(QatarPhone.validate('   '), QatarPhoneError.empty);
      expect(QatarPhone.validate('5512345'), QatarPhoneError.tooShort);
      expect(QatarPhone.validate('551234567'), QatarPhoneError.tooLong);
    });
  });

  group('normalise', () {
    test('strips spaces, dashes and brackets', () {
      expect(QatarPhone.normalise('5512 3456'), '55123456');
      expect(QatarPhone.normalise('5512-3456'), '55123456');
      expect(QatarPhone.normalise(' (5512) 3456 '), '55123456');
    });

    test('strips the country code however it is written', () {
      expect(QatarPhone.normalise('+974 5512 3456'), '55123456');
      expect(QatarPhone.normalise('00974 5512 3456'), '55123456');
      expect(QatarPhone.normalise('974-5512-3456'), '55123456');
      expect(QatarPhone.normalise('+97455123456'), '55123456');
    });

    test('does not strip 974 when it is part of the local number', () {
      // 9741234 is not a valid number, but stripping its 974 would silently
      // turn it into "1234" — a different number entirely.
      expect(QatarPhone.normalise('9741234'), '9741234');
    });

    test('converts Arabic-Indic digits', () {
      // An Arabic keyboard produces these, and \d rejects them — so a valid
      // number typed in Arabic would otherwise look invalid.
      expect(QatarPhone.normalise('٥٥١٢٣٤٥٦'), '55123456');
      expect(QatarPhone.validate('٥٥١٢٣٤٥٦'), isNull);
    });

    test('converts Eastern Arabic-Indic digits', () {
      expect(QatarPhone.normalise('۵۵۱۲۳۴۵۶'), '55123456');
    });

    test('handles mixed Arabic and Western digits', () {
      expect(QatarPhone.normalise('٥٥12٣٤56'), '55123456');
    });
  });

  group('tryParse', () {
    test('returns a value object for valid input', () {
      final QatarPhone? phone = QatarPhone.tryParse('+974 5512 3456');

      expect(phone, isNotNull);
      expect(phone!.localNumber, '55123456');
    });

    test('returns null for invalid input', () {
      expect(QatarPhone.tryParse('44123456'), isNull);
      expect(QatarPhone.tryParse('123'), isNull);
      expect(QatarPhone.tryParse(''), isNull);
    });
  });

  group('formatting', () {
    final QatarPhone phone = QatarPhone.tryParse('55123456')!;

    test('stores E.164', () {
      expect(phone.e164, '+97455123456');
    });

    test('groups the local part for display', () {
      expect(phone.formattedLocal, '5512 3456');
      expect(phone.formatted, '+974 5512 3456');
    });

    test('masks all but the last four digits', () {
      expect(phone.masked, '+974 •••• 3456');
      expect(phone.masked, isNot(contains('5512')));
    });
  });

  group('value equality', () {
    test('same number parsed from different shapes is equal', () {
      expect(
        QatarPhone.tryParse('+974 5512 3456'),
        QatarPhone.tryParse('55123456'),
      );
      expect(
        QatarPhone.tryParse('00974-5512-3456'),
        QatarPhone.tryParse('٥٥١٢٣٤٥٦'),
      );
    });

    test('different numbers are not equal', () {
      expect(
        QatarPhone.tryParse('55123456'),
        isNot(QatarPhone.tryParse('66123456')),
      );
    });
  });
}
