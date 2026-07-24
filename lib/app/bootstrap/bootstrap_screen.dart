import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:soom_mobile/app/bootstrap/bootstrap_cubit.dart';
import 'package:soom_mobile/app/bootstrap/bootstrap_state.dart';
import 'package:soom_mobile/app/localization/l10n_extensions.dart';
import 'package:soom_mobile/app/router/app_routes.dart';
import 'package:soom_mobile/app/theme/app_spacing.dart';

/// Route 1 of 19 — the system gate.
///
/// Shows a spinner while checks run, then either sends the user on to Home or
/// stops them with a blocking message. Force-update is intentionally a dead
/// end: no dismiss, no back.
class BootstrapScreen extends StatelessWidget {
  const BootstrapScreen({super.key});

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
                BootstrapStatus.backendUnreachable =>
                  _BackendUnreachable(state: state),
                BootstrapStatus.forceUpdateRequired =>
                  _ForceUpdate(state: state),
              },
            ),
          ),
        );
      },
    );
  }
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

class _BackendUnreachable extends StatelessWidget {
  const _BackendUnreachable({required this.state});

  final BootstrapState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          Icons.cloud_off_outlined,
          size: AppSizes.iconLg,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.l10n.errorNoConnection,
          style: theme.textTheme.titleSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: () => context.read<BootstrapCubit>().run(),
          child: Text(context.l10n.commonRetry),
        ),
      ],
    );
  }
}

class _ForceUpdate extends StatelessWidget {
  const _ForceUpdate({required this.state});

  final BootstrapState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

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
            state.minimumSupportedVersion != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.forceUpdateVersions(
              state.appVersion!,
              state.minimumSupportedVersion!,
            ),
            style: theme.textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
