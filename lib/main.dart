import 'package:flutter/material.dart';
import 'package:soom_mobile/app/theme/app_colors.dart';
import 'package:soom_mobile/app/theme/app_spacing.dart';
import 'package:soom_mobile/app/theme/app_theme.dart';

void main() {
  runApp(const SoomApp());
}

/// Root of the SOOM app.
///
/// Still a placeholder shell: localization arrives in M0.4 and routing in M0.5,
/// at which point `home:` is replaced by the router.
class SoomApp extends StatelessWidget {
  const SoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Fixed to English until the locale cubit lands in M0.4.
    const Locale locale = Locale('en');

    return MaterialApp(
      title: 'SOOM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(locale),
      darkTheme: AppTheme.dark(locale),
      locale: locale,
      home: const ThemePlaceholderScreen(),
    );
  }
}

/// Temporary home that exercises the theme so M0.3 is visually verifiable.
///
/// Replaced by the real Home screen in M0.5.
class ThemePlaceholderScreen extends StatelessWidget {
  const ThemePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('SOOM')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Phase 0 — theme', style: text.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Design tokens are wired up. Localization (M0.4) and routing '
              '(M0.5) come next.',
              style: text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('QAR 4,500', style: text.displaySmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Sample listing card', style: text.titleSmall),
                    const SizedBox(height: AppSpacing.xxs),
                    Text('Al Sadd, Doha · 2 hours ago', style: text.bodySmall),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            FilledButton(onPressed: () {}, child: const Text('Primary action')),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Secondary action'),
            ),
            const SizedBox(height: AppSpacing.xl),

            const TextField(
              decoration: InputDecoration(hintText: 'Search SOOM'),
            ),
            const SizedBox(height: AppSpacing.xl),

            Wrap(
              spacing: AppSpacing.sm,
              children: <Widget>[
                for (final (String label, Color color) in <(String, Color)>[
                  ('primary', AppColors.primary),
                  ('success', AppColors.success),
                  ('danger', AppColors.danger),
                  ('muted', AppColors.textMuted),
                ])
                  Chip(
                    avatar: CircleAvatar(backgroundColor: color, radius: 8),
                    label: Text(label),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
