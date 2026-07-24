import 'package:flutter/material.dart';
import 'package:soom_mobile/app/router/app_routes.dart';
import 'package:soom_mobile/app/theme/app_spacing.dart';

/// Stand-in for a route that has not been built yet (M0.5).
///
/// One parameterised widget rather than 19 near-identical files — each route
/// is replaced by its real screen in the phase that owns it, and this
/// disappears when the last one lands.
///
/// It shows the route name, path and any path parameters, which makes the
/// route table verifiable by navigating the app.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.route,
    this.pathParameters = const <String, String>{},
    this.plannedIn,
    super.key,
  });

  /// The route this placeholder stands in for.
  final AppRoute route;

  /// Path parameters go_router matched, shown so `/ad/:adId` is verifiable.
  final Map<String, String> pathParameters;

  /// Plan task that will replace this, e.g. `'M3.3'`.
  final String? plannedIn;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme text = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(route.routeName)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.construction_outlined,
                size: AppSizes.iconLg,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                route.routeName,
                style: text.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                route.path,
                style: text.bodySmall,
                textAlign: TextAlign.center,
              ),
              if (plannedIn != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Chip(label: Text('Planned in $plannedIn')),
              ],
              if (pathParameters.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                for (final MapEntry<String, String> param
                    in pathParameters.entries)
                  Text('${param.key}: ${param.value}', style: text.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
