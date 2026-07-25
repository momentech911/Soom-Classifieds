import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:soom_mobile/app/bootstrap/bootstrap_cubit.dart';
import 'package:soom_mobile/app/bootstrap/bootstrap_state.dart';
import 'package:soom_mobile/app/localization/l10n_extensions.dart';
import 'package:soom_mobile/app/router/app_routes.dart';
import 'package:soom_mobile/app/theme/app_spacing.dart';
import 'package:url_launcher/url_launcher.dart';

/// Route 1 of 19 — the system gate.
///
/// Shows a spinner while checks run, then either sends the user on to Home or
/// stops them. Force-update is intentionally a dead end: no dismiss, no back,
/// only a link to the store.
class BootstrapScreen extends StatelessWidget {
  const BootstrapScreen({super.key, this.onOpenStore});

  /// Overridable so tests do not hit the platform URL launcher.
  final Future<bool> Function(String url)? onOpenStore;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BootstrapCubit, BootstrapState>(
      listenWhen: (BootstrapState previous, BootstrapState current) =>
          previous.status != current.status,
      listener: (BuildContext context, BootstrapState state) {
        if (state.canProceed) {
          context.goNamed(AppRoute.home.routeName);
        }
      },
      builder: (BuildContext context, BootstrapState state) {
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: switch (state.status) {
                BootstrapStatus.inProgress ||
                BootstrapStatus.ready =>
                  const _Loading(),
                BootstrapStatus.backendUnreachable => _Blocked(
                    icon: Icons.cloud_off_outlined,
                    title: context.l10n.errorNoConnection,
                    isError: true,
                    onRetry: () => context.read<BootstrapCubit>().run(),
                  ),
                BootstrapStatus.maintenance => _Blocked(
                    icon: Icons.build_outlined,
                    title: context.l10n.maintenanceTitle,
                    body: context.l10n.maintenanceBody,
                    onRetry: () => context.read<BootstrapCubit>().run(),
                  ),
                BootstrapStatus.forceUpdateRequired => _ForceUpdate(
                    state: state,
                    onOpenStore: onOpenStore ?? _launchStore,
                  ),
              },
            ),
          ),
        );
      },
    );
  }

  static Future<bool> _launchStore(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          context.l10n.appName,
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: AppSpacing.xl),
        const CircularProgressIndicator(),
      ],
    );
  }
}

/// A blocking state the user can retry out of.
class _Blocked extends StatelessWidget {
  const _Blocked({
    required this.icon,
    required this.title,
    required this.onRetry,
    this.body,
    this.isError = false,
  });

  final IconData icon;
  final String title;
  final String? body;
  final bool isError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          icon,
          size: AppSizes.iconLg,
          color: isError ? theme.colorScheme.error : theme.colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          style: theme.textTheme.titleSmall,
          textAlign: TextAlign.center,
        ),
        if (body != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            body!,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: onRetry,
          child: Text(context.l10n.commonRetry),
        ),
      ],
    );
  }
}

class _ForceUpdate extends StatelessWidget {
  const _ForceUpdate({required this.state, required this.onOpenStore});

  final BootstrapState state;
  final Future<bool> Function(String url) onOpenStore;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? storeLink = state.storeLink;

    // No dismiss and no retry: the only way forward is to update.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          Icons.system_update_outlined,
          size: AppSizes.iconLg,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.l10n.forceUpdateTitle,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.l10n.forceUpdateBody,
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        if (state.appVersion != null &&
            state.requiredVersion != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.forceUpdateVersions(
              state.appVersion!,
              state.requiredVersion!,
            ),
            style: theme.textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
        // Only shown when the backend supplied a link — a button that goes
        // nowhere is worse than no button.
        if (storeLink != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: () => onOpenStore(storeLink),
            child: Text(context.l10n.forceUpdateAction),
          ),
        ],
      ],
    );
  }
}
