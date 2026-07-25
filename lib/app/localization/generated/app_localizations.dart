import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// The product name. Not translated — brand.
  ///
  /// In en, this message translates to:
  /// **'SOOM'**
  String get appName;

  /// This language's own name, shown in the language picker.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageName;

  /// Advance to the next step.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// Return to the previous step.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// Dismiss without saving.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Persist changes.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Retry a failed action.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// Placeholder in the main search field.
  ///
  /// In en, this message translates to:
  /// **'Search SOOM'**
  String get commonSearch;

  /// Language setting row label.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Fallback message for an unexpected failure.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// Shown when the device is offline.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get errorNoConnection;

  /// Heading when the installed build is no longer supported.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get forceUpdateTitle;

  /// Body of the blocking force-update screen.
  ///
  /// In en, this message translates to:
  /// **'This version of SOOM is no longer supported. Please update to continue.'**
  String get forceUpdateBody;

  /// Shows installed versus required version.
  ///
  /// In en, this message translates to:
  /// **'You have {current}; {minimum} is required.'**
  String forceUpdateVersions(String current, String minimum);

  /// Heading on the phone login screen (S02). Wording taken from the approved screen reference, not paraphrased.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your phone'**
  String get loginTitle;

  /// Explanation under the login heading.
  ///
  /// In en, this message translates to:
  /// **'Enter your Qatar mobile number.'**
  String get loginSubtitle;

  /// Label for the phone field.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get loginPhoneLabel;

  /// Helper text under the field, explaining why there is no country picker.
  ///
  /// In en, this message translates to:
  /// **'Qatar code is fixed. Enter 8 digits only.'**
  String get loginPhoneHelper;

  /// Placeholder showing the expected 8-digit format. Not translated — it is a number.
  ///
  /// In en, this message translates to:
  /// **'5512 3456'**
  String get loginPhoneHint;

  /// Primary action: request the OTP.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get loginContinue;

  /// Reassures the user that browsing does not require login.
  ///
  /// In en, this message translates to:
  /// **'You can keep browsing without an account. Signing in is only needed to post, chat, or save favourites.'**
  String get loginGuestNote;

  /// Terms and privacy notice shown above the Continue button.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our Terms of Use and Privacy Policy.'**
  String get loginTermsNote;

  /// Validation: fewer than 8 digits entered.
  ///
  /// In en, this message translates to:
  /// **'Enter all 8 digits of your number.'**
  String get loginErrorTooShort;

  /// Validation: more than 8 digits entered.
  ///
  /// In en, this message translates to:
  /// **'A Qatar mobile number has 8 digits.'**
  String get loginErrorTooLong;

  /// Validation: valid length but not a mobile prefix. Landlines start with 4 and cannot receive SMS.
  ///
  /// In en, this message translates to:
  /// **'Enter a Qatar mobile number starting with 3, 5, 6 or 7.'**
  String get loginErrorNotMobile;

  /// Validation: nothing entered.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number.'**
  String get loginErrorEmpty;

  /// Backend rejected the request as rate limited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again shortly.'**
  String get loginErrorRateLimited;

  /// Rate limited, with a known wait.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in {seconds} seconds.'**
  String loginErrorRateLimitedIn(int seconds);

  /// Button that opens the app store listing.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get forceUpdateAction;

  /// Heading when the backend reports planned downtime.
  ///
  /// In en, this message translates to:
  /// **'Under maintenance'**
  String get maintenanceTitle;

  /// Body of the maintenance screen.
  ///
  /// In en, this message translates to:
  /// **'SOOM is briefly unavailable while we make improvements. Please try again shortly.'**
  String get maintenanceBody;

  /// Title of the RTL/LTR smoke-test screen.
  ///
  /// In en, this message translates to:
  /// **'Direction check'**
  String get directionDemoTitle;

  /// Body copy used to verify text direction visually.
  ///
  /// In en, this message translates to:
  /// **'This paragraph should start on the leading edge: left in English, right in Arabic. The icon and chevron below must mirror with it.'**
  String get directionDemoBody;

  /// Shows which locale is active.
  ///
  /// In en, this message translates to:
  /// **'Active locale: {locale}'**
  String directionDemoCurrentLocale(String locale);

  /// Shows the resolved text direction.
  ///
  /// In en, this message translates to:
  /// **'Text direction: {direction}'**
  String directionDemoDirection(String direction);

  /// Plural-aware listing count. Arabic needs the full plural set (zero/one/two/few/many/other), which is why this is a plural message rather than string concatenation.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No listings} =1{1 listing} other{{count} listings}}'**
  String listingCountLabel(int count);

  /// Price with the Qatari riyal prefix. Qatar is fixed, so the currency is not configurable.
  ///
  /// In en, this message translates to:
  /// **'QAR {amount}'**
  String priceQar(String amount);
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppL10nAr();
    case 'en':
      return AppL10nEn();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
