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
