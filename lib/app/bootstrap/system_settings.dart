import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Startup-relevant settings the backend controls.
///
/// The field set mirrors eClassify's `SystemSetting` keys, which the SOOM API
/// inherits — see `soom-docs/eClassify_API_Contract.md`. Two of them matter a
/// great deal and are easy to get wrong:
///
/// * **Versions are per platform.** Android and iOS builds diverge routinely
///   (App Store review lag alone guarantees it), so a single
///   "minimum supported version" would force-update one platform wrongly.
/// * **A force-update screen needs somewhere to go.** Without the store link
///   the user is told to update with no way to do it.
class SystemSettings extends Equatable {
  const SystemSettings({
    this.maintenanceMode = false,
    this.forceUpdate = false,
    this.androidVersion,
    this.iosVersion,
    this.playStoreLink,
    this.appStoreLink,
  });

  /// Reads the backend payload, tolerating missing or oddly-typed fields.
  ///
  /// Everything is optional by design: a malformed settings response must
  /// degrade to "no restrictions" rather than lock users out.
  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    return SystemSettings(
      maintenanceMode: _asBool(json['maintenance_mode']),
      forceUpdate: _asBool(json['force_update']),
      androidVersion: _asString(json['android_version']),
      iosVersion: _asString(json['ios_version']),
      playStoreLink: _asString(json['play_store_link']),
      appStoreLink: _asString(json['app_store_link']),
    );
  }

  /// Backend is down for planned maintenance.
  final bool maintenanceMode;

  /// Whether falling below the platform minimum blocks the app.
  ///
  /// When false, an out-of-date build is allowed through — the backend is
  /// advertising a newer version, not mandating it.
  final bool forceUpdate;

  /// Minimum supported Android version.
  final String? androidVersion;

  /// Minimum supported iOS version.
  final String? iosVersion;

  final String? playStoreLink;
  final String? appStoreLink;

  /// The minimum version for [platform], defaulting to the host platform.
  String? minimumVersionFor([TargetPlatform? platform]) {
    return switch (platform ?? defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => iosVersion,
      _ => androidVersion,
    };
  }

  /// The store URL for [platform], defaulting to the host platform.
  String? storeLinkFor([TargetPlatform? platform]) {
    return switch (platform ?? defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => appStoreLink,
      _ => playStoreLink,
    };
  }

  static bool _asBool(Object? value) {
    if (value is bool) return value;
    // Laravel settings are stored as strings; "1"/"true" both appear.
    if (value is num) return value != 0;
    if (value is String) {
      final String v = value.trim().toLowerCase();
      return v == '1' || v == 'true' || v == 'yes';
    }
    return false;
  }

  static String? _asString(Object? value) {
    if (value == null) return null;
    final String s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  @override
  List<Object?> get props => <Object?>[
        maintenanceMode,
        forceUpdate,
        androidVersion,
        iosVersion,
        playStoreLink,
        appStoreLink,
      ];
}
