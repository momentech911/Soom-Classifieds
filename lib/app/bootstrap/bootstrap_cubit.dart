import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soom_mobile/app/bootstrap/bootstrap_state.dart';
import 'package:soom_mobile/app/bootstrap/system_settings.dart';
import 'package:soom_mobile/app/bootstrap/version_check.dart';
import 'package:soom_mobile/core/api/api_client.dart';
import 'package:soom_mobile/core/auth/auth_state.dart';
import 'package:soom_mobile/core/storage/app_preferences.dart';

/// Runs the startup gate (M0.7).
///
/// In order: read the app version, fetch backend settings, then apply
/// maintenance and force-update rules. Session restore is stubbed until
/// M1.4 — for now the gate resolves auth to guest so the router stops
/// holding every route on the gate.
///
/// The settings contract mirrors eClassify's `SystemSetting` keys, which the
/// SOOM API inherits. See `soom-docs/eClassify_API_Contract.md`.
///
/// Two deliberate fail-safes: an unreachable backend is reported as retryable
/// rather than trapping the user on a spinner, and a missing or malformed
/// settings payload yields no restrictions rather than locking everyone out.
class BootstrapCubit extends Cubit<BootstrapState> {
  BootstrapCubit({
    required this.apiClient,
    required this.preferences,
    required this.auth,
    required this.appVersionReader,
    this.platformOverride,
  }) : super(const BootstrapState());

  // Public finals rather than private fields: Dart cannot bind a named
  // parameter to a private field with an initializing formal, and the
  // workaround costs more than the encapsulation is worth here.
  final ApiClient apiClient;
  final AppPreferences preferences;
  final AuthStateNotifier auth;

  /// Reads this build's version. Injected so tests need no platform channel.
  final Future<String> Function() appVersionReader;

  /// Forces a platform for the version check. Tests only.
  final TargetPlatform? platformOverride;

  /// Endpoint carrying startup settings.
  ///
  /// eClassify exposes this flat as `get-system-settings`; SOOM versions and
  /// namespaces it (Architecture Decisions §2). B0.2 must expose the same
  /// fields — see the API contract doc.
  static const String settingsPath = '/system/settings';

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

    final SystemSettings settings = await _fetchSettings();

    // Version floors and store links are per platform: Android and iOS
    // releases diverge, so a single minimum would force-update one wrongly.
    // Resolved here, where the platform is known, and passed into state.
    final String? minimum = settings.minimumVersionFor(platformOverride);
    final String? storeLink = settings.storeLinkFor(platformOverride);

    if (settings.maintenanceMode) {
      emit(
        state.copyWith(
          status: BootstrapStatus.maintenance,
          appVersion: version,
          isFirstRun: isFirstRun,
          settings: settings,
          requiredVersion: minimum,
          storeLink: storeLink,
        ),
      );
      return;
    }

    final bool outOfDate = VersionCheck.isUpdateRequired(
      current: version,
      minimumSupported: minimum,
    );

    // Only block when the backend actually mandates it. Otherwise the backend
    // is advertising a newer build, not requiring one.
    if (outOfDate && settings.forceUpdate) {
      emit(
        state.copyWith(
          status: BootstrapStatus.forceUpdateRequired,
          appVersion: version,
          isFirstRun: isFirstRun,
          settings: settings,
          requiredVersion: minimum,
          storeLink: storeLink,
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
        isFirstRun: isFirstRun,
        settings: settings,
        requiredVersion: minimum,
        storeLink: storeLink,
      ),
    );
  }

  /// Reads startup settings from the backend.
  ///
  /// Returns defaults on any failure: a settings endpoint that is missing or
  /// broken must not lock users out of the app.
  Future<SystemSettings> _fetchSettings() async {
    try {
      final Map<String, dynamic> body =
          await apiClient.get<Map<String, dynamic>>(settingsPath);

      // Tolerate both a bare object and one wrapped in a `data` envelope,
      // since B0.2 has not frozen the envelope yet.
      final Object? data = body['data'];
      return SystemSettings.fromJson(
        data is Map<String, dynamic> ? data : body,
      );
    } on Object {
      return const SystemSettings();
    }
  }
}
