import 'package:flutter/widgets.dart';
import 'package:soom_mobile/app/localization/generated/app_localizations.dart';

/// Shorthand for reaching localized strings from a widget.
///
/// Write `context.l10n.commonSave` instead of `AppL10n.of(context).commonSave`.
/// Every user-facing string goes through here — no hardcoded copy (golden
/// rule #4).
extension L10nExtension on BuildContext {
  /// The localized strings for the active locale.
  AppL10n get l10n => AppL10n.of(this);

  /// Text direction of the active locale — RTL for Arabic, LTR for English.
  TextDirection get textDirection => Directionality.of(this);

  /// Whether the active layout is right-to-left.
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
}
