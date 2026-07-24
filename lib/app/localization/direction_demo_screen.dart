import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soom_mobile/app/localization/l10n_extensions.dart';
import 'package:soom_mobile/app/localization/locale_cubit.dart';
import 'package:soom_mobile/app/theme/app_spacing.dart';

/// RTL/LTR smoke-test screen (M0.4).
///
/// Deliberately built from the widgets that most often break in Arabic:
/// directional padding, a leading icon, a chevron, a row that must reverse,
/// and a plural string. If this screen is right in both languages, the theme
/// and localization rails are sound.
///
/// Everything here uses **directional** primitives —
/// `EdgeInsetsDirectional`, `Alignment*Start`, `Icons.*_outlined` with
/// `matchTextDirection` — never `left`/`right`. That is the rule for every
/// screen in the app.
class DirectionDemoScreen extends StatelessWidget {
  const DirectionDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme text = theme.textTheme;
    final LocaleCubit localeCubit = context.read<LocaleCubit>();
    final Locale locale = context.watch<LocaleCubit>().state;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.directionDemoTitle),
        actions: <Widget>[
          TextButton(
            onPressed: localeCubit.toggle,
            child: Text(
              locale.languageCode == 'ar' ? 'EN' : 'ع',
              style: text.labelLarge?.copyWith(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(AppSpacing.screenPadding),
        children: <Widget>[
          Text(
            context.l10n.directionDemoCurrentLocale(locale.languageCode),
            style: text.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.directionDemoDirection(
              context.isRtl ? 'RTL' : 'LTR',
            ),
            style: text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Body copy — must start on the leading edge in both languages.
          Text(context.l10n.directionDemoBody, style: text.bodyMedium),
          const SizedBox(height: AppSpacing.lg),

          // A row that must reverse wholesale in Arabic.
          Card(
            child: ListTile(
              leading: Icon(
                Icons.storefront_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(context.l10n.appName, style: text.titleSmall),
              subtitle: Text(
                context.l10n.listingCountLabel(3),
                style: text.bodySmall,
              ),
              // Icons.chevron_right declares matchTextDirection: true in its
              // IconData, so it mirrors automatically under RTL.
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Plural forms — Arabic has six categories, English two.
          Text(context.l10n.listingCountLabel(0), style: text.bodyMedium),
          Text(context.l10n.listingCountLabel(1), style: text.bodyMedium),
          Text(context.l10n.listingCountLabel(2), style: text.bodyMedium),
          Text(context.l10n.listingCountLabel(11), style: text.bodyMedium),
          const SizedBox(height: AppSpacing.lg),

          // Numerals and currency placement differ between the two.
          Text(context.l10n.priceQar('4,500'), style: text.displaySmall),
          const SizedBox(height: AppSpacing.lg),

          // Hint text must also start on the leading edge.
          TextField(
            decoration: InputDecoration(hintText: context.l10n.commonSearch),
          ),
          const SizedBox(height: AppSpacing.lg),

          FilledButton(
            onPressed: localeCubit.toggle,
            child: Text(context.l10n.settingsLanguage),
          ),
        ],
      ),
    );
  }
}
