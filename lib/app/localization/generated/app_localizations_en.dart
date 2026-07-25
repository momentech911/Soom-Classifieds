// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'SOOM';

  @override
  String get languageName => 'English';

  @override
  String get commonNext => 'Next';

  @override
  String get commonBack => 'Back';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonSearch => 'Search SOOM';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNoConnection => 'No internet connection.';

  @override
  String get forceUpdateTitle => 'Update required';

  @override
  String get forceUpdateBody =>
      'This version of SOOM is no longer supported. Please update to continue.';

  @override
  String forceUpdateVersions(String current, String minimum) {
    return 'You have $current; $minimum is required.';
  }

  @override
  String get loginTitle => 'Enter your phone number';

  @override
  String get loginSubtitle => 'We\'ll send you a verification code by SMS.';

  @override
  String get loginPhoneLabel => 'Mobile number';

  @override
  String get loginPhoneHint => '5512 3456';

  @override
  String get loginContinue => 'Continue';

  @override
  String get loginGuestNote =>
      'You can keep browsing without an account. Signing in is only needed to post, chat, or save favourites.';

  @override
  String get loginTermsNote =>
      'By continuing you agree to our Terms of Use and Privacy Policy.';

  @override
  String get loginErrorTooShort => 'Enter all 8 digits of your number.';

  @override
  String get loginErrorTooLong => 'A Qatar mobile number has 8 digits.';

  @override
  String get loginErrorNotMobile =>
      'Enter a Qatar mobile number starting with 3, 5, 6 or 7.';

  @override
  String get loginErrorEmpty => 'Enter your mobile number.';

  @override
  String get loginErrorRateLimited =>
      'Too many attempts. Please try again shortly.';

  @override
  String loginErrorRateLimitedIn(int seconds) {
    return 'Too many attempts. Try again in $seconds seconds.';
  }

  @override
  String get forceUpdateAction => 'Update now';

  @override
  String get maintenanceTitle => 'Under maintenance';

  @override
  String get maintenanceBody =>
      'SOOM is briefly unavailable while we make improvements. Please try again shortly.';

  @override
  String get directionDemoTitle => 'Direction check';

  @override
  String get directionDemoBody =>
      'This paragraph should start on the leading edge: left in English, right in Arabic. The icon and chevron below must mirror with it.';

  @override
  String directionDemoCurrentLocale(String locale) {
    return 'Active locale: $locale';
  }

  @override
  String directionDemoDirection(String direction) {
    return 'Text direction: $direction';
  }

  @override
  String listingCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count listings',
      one: '1 listing',
      zero: 'No listings',
    );
    return '$_temp0';
  }

  @override
  String priceQar(String amount) {
    return 'QAR $amount';
  }
}
