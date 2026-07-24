import 'package:connectivity_plus/connectivity_plus.dart';

/// Reports whether the device has a network path.
///
/// This answers "is there an interface up", not "is the internet reachable" —
/// captive portals and dead backends still look connected. Treat it as a fast
/// pre-check that avoids pointless requests, and let [ApiException] handle the
/// real failures.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Whether any usable interface is currently up.
  Future<bool> get isConnected async {
    final List<ConnectivityResult> results =
        await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  /// Emits true/false as connectivity changes.
  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map(_hasConnection);

  static bool _hasConnection(List<ConnectivityResult> results) =>
      results.isNotEmpty &&
      results.any((ConnectivityResult r) => r != ConnectivityResult.none);
}
