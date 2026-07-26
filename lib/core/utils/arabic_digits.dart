/// Conversion between Arabic-Indic and Western digits.
///
/// Arabic keyboards produce ٠-٩ (and Persian/Urdu layouts ۰-۹). Dart's
/// `int.parse` and the `\d` regex class both reject them, so a number typed
/// perfectly correctly in Arabic looks like garbage to validation unless it
/// is converted first.
///
/// The reverse direction matters for display: the approved Arabic screens
/// show countdown timers in Arabic-Indic numerals (٠١:٢٤) while phone numbers
/// stay Western — so conversion has to be applied deliberately, per field,
/// not globally.
abstract final class ArabicDigits {
  static const String _arabicIndic = '٠١٢٣٤٥٦٧٨٩';
  static const String _easternArabicIndic = '۰۱۲۳۴۵۶۷۸۹';
  static const String _western = '0123456789';

  /// Converts any Arabic-Indic digits in [input] to Western ones.
  ///
  /// Everything else passes through untouched, so this is safe to run over
  /// mixed text.
  static String toWestern(String input) {
    final StringBuffer out = StringBuffer();

    for (final int rune in input.runes) {
      final String char = String.fromCharCode(rune);
      final int arabic = _arabicIndic.indexOf(char);
      final int eastern = _easternArabicIndic.indexOf(char);

      if (arabic >= 0) {
        out.write(arabic);
      } else if (eastern >= 0) {
        out.write(eastern);
      } else {
        out.write(char);
      }
    }

    return out.toString();
  }

  /// Converts Western digits in [input] to Arabic-Indic.
  ///
  /// For display only — never store or transmit these.
  static String toArabicIndic(String input) {
    final StringBuffer out = StringBuffer();

    for (final int rune in input.runes) {
      final String char = String.fromCharCode(rune);
      final int index = _western.indexOf(char);

      out.write(index >= 0 ? _arabicIndic[index] : char);
    }

    return out.toString();
  }

  /// Keeps only digits, converting Arabic-Indic ones first.
  static String digitsOnly(String input) =>
      toWestern(input).replaceAll(RegExp(r'\D'), '');

  /// Formats [duration] as `m:ss`, in the numerals [languageCode] expects.
  ///
  /// The approved Arabic screens show ٠١:٢٤ rather than 01:24.
  static String countdown(Duration duration, String languageCode) {
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds % 60;
    final String text =
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';

    return languageCode == 'ar' ? toArabicIndic(text) : text;
  }
}
