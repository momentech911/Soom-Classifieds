import 'package:equatable/equatable.dart';

/// Why a phone number was rejected.
enum QatarPhoneError {
  /// Nothing entered yet.
  empty,

  /// Fewer than 8 digits.
  tooShort,

  /// More than 8 digits.
  tooLong,

  /// Right length, but not a Qatari mobile prefix.
  ///
  /// Qatari mobiles start 3, 5, 6 or 7. Landlines start 4 and **cannot
  /// receive SMS** — accepting one sends the user to an OTP screen for a code
  /// that will never arrive.
  notMobile,
}

/// A validated Qatar mobile number.
///
/// Qatar is fixed, so there is no country picker and no dial code to choose:
/// `+974` is displayed, and the user types the 8-digit local part.
///
/// Rules come from `SOOM_Canonical_Addendum_v1.1.json`:
/// `^[3567][0-9]{7}$`, stored in E.164.
class QatarPhone extends Equatable {
  const QatarPhone._(this.localNumber);

  /// The 8 local digits, without the country code.
  final String localNumber;

  /// Fixed dial code. Never user-selectable.
  static const String dialCode = '+974';

  /// Length of the local part.
  static const int localLength = 8;

  /// Leading digits that identify a mobile line.
  static const Set<String> mobilePrefixes = <String>{'3', '5', '6', '7'};

  /// Parses [input], returning null if it is not a valid Qatar mobile.
  ///
  /// Accepts what users actually paste — spaces, dashes, a `+974` or `00974`
  /// prefix, Arabic-Indic digits — and normalises before validating. Use
  /// [validate] when you need to know *why* something failed.
  static QatarPhone? tryParse(String input) {
    return validate(input) == null ? QatarPhone._(normalise(input)) : null;
  }

  /// Returns the reason [input] is invalid, or null when it is valid.
  static QatarPhoneError? validate(String input) {
    final String digits = normalise(input);

    if (digits.isEmpty) return QatarPhoneError.empty;
    if (digits.length < localLength) return QatarPhoneError.tooShort;
    if (digits.length > localLength) return QatarPhoneError.tooLong;
    if (!mobilePrefixes.contains(digits[0])) return QatarPhoneError.notMobile;

    return null;
  }

  /// Reduces raw input to the 8 local digits.
  ///
  /// Handles the shapes people actually type or paste:
  /// `+974 5512 3456`, `00974-55123456`, `(974) 5512 3456`, `٥٥١٢٣٤٥٦`.
  static String normalise(String input) {
    final String digits = _toWesternDigits(input).replaceAll(RegExp(r'\D'), '');

    // Strip the country code however it was written — but only when what
    // remains is exactly a local number. A looser check silently mangles
    // input: "9741234" would lose its leading 974 and become "1234", a
    // different number, with no error shown.
    if (digits.startsWith('00974') &&
        digits.length == 5 + localLength) {
      return digits.substring(5);
    }
    if (digits.startsWith('974') && digits.length == 3 + localLength) {
      return digits.substring(3);
    }

    return digits;
  }

  /// Converts Arabic-Indic (٠-٩) and Eastern Arabic-Indic (۰-۹) digits to
  /// ASCII.
  ///
  /// An Arabic keyboard produces these, and `int.parse` and `\d` both reject
  /// them — so a perfectly valid number typed in Arabic would look invalid.
  static String _toWesternDigits(String input) {
    const String arabicIndic = '٠١٢٣٤٥٦٧٨٩';
    const String easternArabicIndic = '۰۱۲۳۴۵۶۷۸۹';

    final StringBuffer out = StringBuffer();

    for (final int rune in input.runes) {
      final String char = String.fromCharCode(rune);
      final int arabicIndex = arabicIndic.indexOf(char);
      final int easternIndex = easternArabicIndic.indexOf(char);

      if (arabicIndex >= 0) {
        out.write(arabicIndex);
      } else if (easternIndex >= 0) {
        out.write(easternIndex);
      } else {
        out.write(char);
      }
    }

    return out.toString();
  }

  /// E.164, the storage format: `+97455123456`.
  String get e164 => '$dialCode$localNumber';

  /// Grouped for display: `5512 3456`.
  String get formattedLocal =>
      '${localNumber.substring(0, 4)} ${localNumber.substring(4)}';

  /// Full number as shown to the user: `+974 5512 3456`.
  String get formatted => '$dialCode $formattedLocal';

  /// Partially hidden for the OTP screen: `+974 •••• 3456`.
  ///
  /// Enough to confirm the right number without printing it in full on a
  /// screen the user may show someone.
  String get masked => '$dialCode •••• ${localNumber.substring(4)}';

  @override
  List<Object?> get props => <Object?>[localNumber];

  @override
  String toString() => e164;
}
