/// Spacing, radius and sizing tokens.
///
/// Use these instead of magic numbers so screens stay consistent and a single
/// change re-flows the whole app. All values are logical pixels on a 4pt grid.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Default horizontal inset for screen content.
  static const double screenPadding = lg;
}

/// Corner radii. Primary buttons and cards use [md] per the wireframes.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;
}

/// Fixed component sizes that several screens depend on agreeing about.
abstract final class AppSizes {
  static const double buttonHeight = 52;
  static const double inputHeight = 52;
  static const double iconSm = 16;
  static const double iconMd = 24;
  static const double iconLg = 32;

  /// Minimum tap target — accessibility floor, do not go below.
  static const double minTapTarget = 48;
}
