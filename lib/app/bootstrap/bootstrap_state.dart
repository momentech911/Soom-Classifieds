import 'package:equatable/equatable.dart';
import 'package:soom_mobile/app/bootstrap/system_settings.dart';

/// How the startup gate ended.
enum BootstrapStatus {
  /// Checks are running.
  inProgress,

  /// A mandatory update blocks use of the app.
  forceUpdateRequired,

  /// Backend is in planned maintenance.
  maintenance,

  /// The backend could not be reached. Offer a retry.
  backendUnreachable,

  /// Checks passed; the app may proceed.
  ready,
}

/// Result of the startup gate.
class BootstrapState extends Equatable {
  const BootstrapState({
    this.status = BootstrapStatus.inProgress,
    this.isFirstRun = false,
    this.appVersion,
    this.settings = const SystemSettings(),
    this.requiredVersion,
    this.storeLink,
  });

  final BootstrapStatus status;

  /// True the first time the app is ever opened — drives onboarding later.
  final bool isFirstRun;

  /// This build's version, e.g. `1.0.0`.
  final String? appVersion;

  /// Backend-controlled startup settings.
  final SystemSettings settings;

  /// Whether the app may continue to its normal routes.
  bool get canProceed => status == BootstrapStatus.ready;

  /// Whether the failure is worth offering a retry for.
  ///
  /// Maintenance is retryable — it ends on its own. A force update is not:
  /// retrying cannot change the installed version.
  bool get isRetryable =>
      status == BootstrapStatus.backendUnreachable ||
      status == BootstrapStatus.maintenance;

  /// Minimum version required on the running platform, if any.
  ///
  /// Resolved by the cubit, which knows the platform — the state deliberately
  /// does no platform lookup of its own, so it stays a plain value object and
  /// tests can drive any platform.
  final String? requiredVersion;

  /// Where to send the user to update, if the backend supplied a link.
  final String? storeLink;

  BootstrapState copyWith({
    BootstrapStatus? status,
    bool? isFirstRun,
    String? appVersion,
    SystemSettings? settings,
    String? requiredVersion,
    String? storeLink,
  }) {
    return BootstrapState(
      status: status ?? this.status,
      isFirstRun: isFirstRun ?? this.isFirstRun,
      appVersion: appVersion ?? this.appVersion,
      settings: settings ?? this.settings,
      requiredVersion: requiredVersion ?? this.requiredVersion,
      storeLink: storeLink ?? this.storeLink,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        isFirstRun,
        appVersion,
        settings,
        requiredVersion,
        storeLink,
      ];
}
