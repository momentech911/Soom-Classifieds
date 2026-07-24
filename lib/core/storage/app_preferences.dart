import 'package:shared_preferences/shared_preferences.dart';

/// Small key-value store for app-level flags.
///
/// Deliberately not for tokens — those go to secure storage in M1.4 — and not
/// for cached API data, which Hive handles later. Just first-run state and
/// similar switches.
class AppPreferences {
  AppPreferences(this._preferences);

  /// Opens the platform store.
  static Future<AppPreferences> create() async =>
      AppPreferences(await SharedPreferences.getInstance());

  final SharedPreferences _preferences;

  static const String _keyHasCompletedFirstRun = 'has_completed_first_run';
  static const String _keyLastSeenVersion = 'last_seen_version';

  /// False until [markFirstRunComplete] has been called once.
  bool get hasCompletedFirstRun =>
      _preferences.getBool(_keyHasCompletedFirstRun) ?? false;

  Future<void> markFirstRunComplete() =>
      _preferences.setBool(_keyHasCompletedFirstRun, true);

  /// The app version last launched — used to spot upgrades.
  String? get lastSeenVersion => _preferences.getString(_keyLastSeenVersion);

  Future<void> setLastSeenVersion(String version) =>
      _preferences.setString(_keyLastSeenVersion, version);

  /// Wipes app flags. Used by account deletion and sign-out-everywhere.
  Future<void> clear() => _preferences.clear();
}
