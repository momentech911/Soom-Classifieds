// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppL10nAr extends AppL10n {
  AppL10nAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'سوم';

  @override
  String get languageName => 'العربية';

  @override
  String get commonNext => 'التالي';

  @override
  String get commonBack => 'رجوع';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get commonSearch => 'ابحث في سوم';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get errorGeneric => 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  @override
  String get errorNoConnection => 'لا يوجد اتصال بالإنترنت.';

  @override
  String get forceUpdateTitle => 'التحديث مطلوب';

  @override
  String get forceUpdateBody =>
      'هذا الإصدار من سوم لم يعد مدعومًا. يرجى التحديث للمتابعة.';

  @override
  String forceUpdateVersions(String current, String minimum) {
    return 'لديك $current، والمطلوب $minimum.';
  }

  @override
  String get loginTitle => 'سجّل الدخول برقم هاتفك';

  @override
  String get loginSubtitle => 'أدخل رقم هاتفك القطري.';

  @override
  String get loginPhoneLabel => 'رقم الهاتف';

  @override
  String get loginPhoneHelper => 'رمز قطر ثابت. أدخل ٨ أرقام فقط.';

  @override
  String get loginPhoneHint => '5512 3456';

  @override
  String get loginContinue => 'متابعة';

  @override
  String get loginGuestNote =>
      'يمكنك التصفح بدون حساب. تسجيل الدخول مطلوب فقط للنشر والمحادثة وحفظ المفضلة.';

  @override
  String get loginTermsNote =>
      'بالمتابعة فإنك توافق على شروط الاستخدام وسياسة الخصوصية.';

  @override
  String get loginErrorTooShort => 'أدخل جميع أرقام الهاتف الثمانية.';

  @override
  String get loginErrorTooLong => 'رقم الجوال القطري مكوّن من ٨ أرقام.';

  @override
  String get loginErrorNotMobile =>
      'أدخل رقم جوال قطري يبدأ بـ ٣ أو ٥ أو ٦ أو ٧.';

  @override
  String get loginErrorEmpty => 'أدخل رقم جوالك.';

  @override
  String get loginErrorRateLimited => 'محاولات كثيرة. يرجى المحاولة بعد قليل.';

  @override
  String loginErrorRateLimitedIn(int seconds) {
    return 'محاولات كثيرة. حاول مرة أخرى خلال $seconds ثانية.';
  }

  @override
  String get otpAppBarTitle => 'التحقق';

  @override
  String get otpTitle => 'أدخل رمز التحقق';

  @override
  String otpSentTo(String phone) {
    return 'أُرسل إلى $phone';
  }

  @override
  String otpExpiresIn(String time) {
    return 'ينتهي الرمز خلال $time';
  }

  @override
  String get otpVerify => 'تحقق';

  @override
  String otpResendIn(String time) {
    return 'إعادة الإرسال خلال $time';
  }

  @override
  String get otpResend => 'إعادة إرسال الرمز';

  @override
  String get otpChangePhone => 'تغيير رقم الهاتف';

  @override
  String get otpErrorInvalid => 'الرمز غير صحيح. تحقق منه وحاول مرة أخرى.';

  @override
  String get otpErrorExpired => 'انتهت صلاحية هذا الرمز. اطلب رمزًا جديدًا.';

  @override
  String get otpErrorRateLimited =>
      'محاولات كثيرة. يرجى الانتظار قبل المحاولة مرة أخرى.';

  @override
  String get forceUpdateAction => 'التحديث الآن';

  @override
  String get maintenanceTitle => 'قيد الصيانة';

  @override
  String get maintenanceBody =>
      'سوم غير متاح مؤقتًا بينما نجري بعض التحسينات. يرجى المحاولة بعد قليل.';

  @override
  String get directionDemoTitle => 'فحص الاتجاه';

  @override
  String get directionDemoBody =>
      'يجب أن تبدأ هذه الفقرة من الحافة الأمامية: اليسار في الإنجليزية واليمين في العربية. ويجب أن تنعكس الأيقونة والسهم أدناه معها.';

  @override
  String directionDemoCurrentLocale(String locale) {
    return 'اللغة الحالية: $locale';
  }

  @override
  String directionDemoDirection(String direction) {
    return 'اتجاه النص: $direction';
  }

  @override
  String listingCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إعلان',
      many: '$count إعلانًا',
      few: '$count إعلانات',
      two: 'إعلانان',
      one: 'إعلان واحد',
      zero: 'لا توجد إعلانات',
    );
    return '$_temp0';
  }

  @override
  String priceQar(String amount) {
    return '$amount ر.ق';
  }
}
