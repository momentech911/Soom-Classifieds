import 'package:equatable/equatable.dart';

/// How the startup gate ended.
enum BootstrapStatus {
  /// Checks are running.
  inProgress,

  /// A mandatory update blocks use of the app.
  forceUpdateRequired,

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
    this.minimumSupportedVersion,
  });

  final BootstrapStatus status;

  /// True the first time the app is ever opened — drives onboarding later.
  final bool isFirstRun;

  /// This build's version, e.g. `1.0.0`.
  final String? appVersion;

  /// Oldest version the backend still accepts, when it reports one.
  final String? minimumSupportedVersion;

  /// Whether the app may continue to its normal routes.
  bool get canProceed => status == BootstrapStatus.ready;

  /// Whether the failure is worth offering a retry for.
  bool get isRetryable => status == BootstrapStatus.backendUnreachable;

  BootstrapState copyWith({
    BootstrapStatus? status,
    bool? isFirstRun,
    String? appVersion,
    String? minimumSupportedVersion,
  }) {
    return BootstrapState(
      status: status ?? this.status,
      isFirstRun: isFirstRun ?? this.isFirstRun,
      appVersion: appVersion ?? this.appVersion,
      minimumSupportedVersion:
          minimumSupportedVersion ?? this.minimumSupportedVersion,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        isFirstRun,
        appVersion,
        minimumSupportedVersion,
      ];
}
