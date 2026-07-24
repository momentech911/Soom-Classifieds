import 'package:flutter/foundation.dart';

/// Whether the app currently has a signed-in session.
enum AuthStatus {
  /// Session restore has not finished — the gate is still deciding.
  unknown,

  /// Browsing as a guest. Public routes only.
  guest,

  /// Signed in, but the profile is incomplete (name is required).
  needsProfile,

  /// Signed in with a complete profile.
  authenticated,
}

/// Holds auth status for route guarding.
///
/// **Stub for M0.5.** Real Firebase phone OTP, token storage and session
/// restore arrive in M1.4; this exists so the router's guards can be written
/// and tested now. It extends [ChangeNotifier] so `GoRouter` can use it as a
/// `refreshListenable` and re-evaluate redirects when auth changes.
class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier({AuthStatus initial = AuthStatus.guest})
      : _status = initial;

  AuthStatus _status;

  AuthStatus get status => _status;

  /// True once the user holds a session, complete profile or not.
  bool get isSignedIn =>
      _status == AuthStatus.authenticated || _status == AuthStatus.needsProfile;

  /// True when the session is usable for protected routes.
  bool get isFullyOnboarded => _status == AuthStatus.authenticated;

  /// True while session restore is still in flight.
  bool get isResolving => _status == AuthStatus.unknown;

  set status(AuthStatus value) {
    if (_status == value) return;
    _status = value;
    notifyListeners();
  }

  // Convenience transitions used by the gate and, later, the auth cubit.

  void signOut() => status = AuthStatus.guest;

  void signInPendingProfile() => status = AuthStatus.needsProfile;

  void completeProfile() => status = AuthStatus.authenticated;
}
