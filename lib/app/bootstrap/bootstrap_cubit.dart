import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soom_mobile/app/bootstrap/bootstrap_state.dart';
import 'package:soom_mobile/app/bootstrap/version_check.dart';
import 'package:soom_mobile/core/api/api_client.dart';
import 'package:soom_mobile/core/auth/auth_state.dart';
import 'package:soom_mobile/core/storage/app_preferences.dart';

/// Runs the startup gate (M0.7).
///
/// In order: read the app version, ask the backend whether this build is
/// still supported, and detect first run. Session restore is stubbed until
/// M1.4 — for now the gate simply resolves auth to guest so the router stops
/// holding on the gate.
///
/// Nothing here blocks on the backend being up. If `/health` is unreachable
/// the gate reports [BootstrapStatus.backendUnreachable] and offers a retry,
/// rather than trapping the user on a spinner.
class BootstrapCubit extends Cubit<BootstrapState> {
  BootstrapCubit({
    required this.apiClient,
    required this.preferences,
    required this.auth,
    required this.appVersionReader,
  }) : super(const BootstrapState());

  // Public finals rather than private fields: Dart cannot bind a named
  // parameter to a private field with an initializing formal, and the
  // workaround costs more than the encapsulation is worth here.
  final ApiClient apiClient;
  final AppPreferences preferences;
  final AuthStateNotifier auth;

  /// Reads this build's version. Injected so tests need no platform channel.
  final Future<String> Function() appVersionReader;

  /// Runs every startup check. Safe to call again for a retry.
  Future<void> run() async {
    emit(const BootstrapState());

    final String version = await appVersionReader();
    final bool isFirstRun = !preferences.hasCompletedFirstRun;

    // Reachability. A dead backend is a retryable condition, not a crash.
    final bool backendReachable = await apiClient.healthCheck();
    if (!backendReachable) {
      emit(
        state.copyWith(
          status: BootstrapStatus.backendUnreachable,
          appVersion: version,
          isFirstRun: isFirstRun,
        ),
      );
      return;
    }

    // Force-update. The minimum supported version comes from the backend;
    // until B0.2 exposes it, this is null and the check is a no-op.
    final String? minimumSupported = await _fetchMinimumSupportedVersion();
    if (VersionCheck.isUpdateRequired(
      current: version,
      minimumSupported: minimumSupported,
    )) {
      emit(
        state.copyWith(
          status: BootstrapStatus.forceUpdateRequired,
          appVersion: version,
          minimumSupportedVersion: minimumSupported,
          isFirstRun: isFirstRun,
        ),
      );
      return;
    }

    await preferences.setLastSeenVersion(version);
    if (isFirstRun) {
      await preferences.markFirstRunComplete();
    }

    // Session restore lands in M1.4. Resolving to guest releases the router,
    // which holds every route on the gate while auth is unknown.
    if (auth.isResolving) {
      auth.signOut();
    }

    emit(
      state.copyWith(
        status: BootstrapStatus.ready,
        appVersion: version,
        minimumSupportedVersion: minimumSupported,
        isFirstRun: isFirstRun,
      ),
    );
  }

  /// Reads the minimum supported version from the backend.
  ///
  /// Returns null on any failure: a config endpoint that is missing or broken
  /// must not lock users out of the app.
  Future<String?> _fetchMinimumSupportedVersion() async {
    try {
      final Map<String, dynamic> config =
          await apiClient.get<Map<String, dynamic>>('/config');
      final Object? minimum = config['minimum_supported_version'];
      return minimum is String ? minimum : null;
    } on Object {
      return null;
    }
  }
}
