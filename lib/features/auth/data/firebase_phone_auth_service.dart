import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:soom_mobile/features/auth/domain/qatar_phone.dart';
import 'package:soom_mobile/features/auth/presentation/phone_login_cubit.dart';

/// Phone OTP via Firebase Auth (M1.1).
///
/// Wraps `verifyPhoneNumber`, whose callback-based API does not fit the
/// `Future`-returning contract the cubits expect, and translates Firebase's
/// error codes into SOOM's exceptions so no screen ever imports
/// `firebase_auth`.
///
/// ## What this does and does not do
///
/// Verifying the code yields a Firebase credential proving the user controls
/// the number. That is **not** a SOOM session. Exchanging the Firebase ID
/// token for a SOOM token is B1 work on the backend, using the service
/// account. Until that lands, [verifyCode] signs in to Firebase and stops
/// there — [lastIdToken] is what the backend will need.
class FirebasePhoneAuthService {
  FirebasePhoneAuthService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Set by [requestOtp]; needed to build the credential on verify.
  String? _verificationId;

  /// Firebase's resend token, so a resend is treated as a continuation of the
  /// same attempt rather than a fresh one — this is what stops legitimate
  /// resends tripping the abuse limits.
  int? _resendToken;

  /// How long to wait for the SMS before giving up.
  static const Duration _timeout = Duration(seconds: 60);

  /// The Firebase ID token for the signed-in user, or null.
  ///
  /// This is what gets exchanged for a SOOM session once B1 exists.
  Future<String?> get lastIdToken async =>
      _auth.currentUser?.getIdToken();

  /// Sends an OTP to [phone]. Completes when the SMS is on its way.
  ///
  /// Throws [OtpRateLimitedException] or [OtpNetworkException] so callers stay
  /// free of Firebase types.
  Future<void> requestOtp(QatarPhone phone, {bool isResend = false}) {
    final Completer<void> completer = Completer<void>();

    unawaited(
      _auth.verifyPhoneNumber(
        phoneNumber: phone.e164,
        timeout: _timeout,
        forceResendingToken: isResend ? _resendToken : null,

        // Android can verify without the user typing anything (Play Services
        // reads the SMS). The credential is kept so verify() can use it, but
        // the screen is not skipped — the user still sees what happened.
        verificationCompleted: (PhoneAuthCredential credential) {
          _autoCredential = credential;
        },

        verificationFailed: (FirebaseAuthException e) {
          if (!completer.isCompleted) {
            completer.completeError(_translate(e));
          }
        },

        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          if (!completer.isCompleted) completer.complete();
        },

        // Fires when auto-retrieval gives up. The code may still be typed in,
        // so this is not a failure.
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      ),
    );

    return completer.future;
  }

  /// Credential captured by Android's automatic verification, if any.
  PhoneAuthCredential? _autoCredential;

  /// Verifies [code] and signs in to Firebase.
  ///
  /// Throws on a wrong or expired code.
  Future<void> verifyCode(String code) async {
    final String? verificationId = _verificationId;

    if (verificationId == null && _autoCredential == null) {
      throw StateError('verifyCode called before requestOtp');
    }

    final PhoneAuthCredential credential = _autoCredential ??
        PhoneAuthProvider.credential(
          verificationId: verificationId!,
          smsCode: code,
        );

    try {
      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _translate(e);
    }
  }

  /// Requests a fresh code for the number already in flight.
  Future<void> resend(QatarPhone phone) =>
      requestOtp(phone, isResend: true);

  /// Clears in-flight state. Call when leaving the auth flow.
  void reset() {
    _verificationId = null;
    _resendToken = null;
    _autoCredential = null;
  }

  /// Maps Firebase error codes onto SOOM's exceptions.
  ///
  /// Only the ones worth distinguishing to a user are translated; the rest
  /// surface as a generic failure rather than leaking Firebase wording.
  Object _translate(FirebaseAuthException e) {
    return switch (e.code) {
      // Firebase's own abuse throttling, per number and per device.
      'too-many-requests' || 'quota-exceeded' =>
        const OtpRateLimitedException(),
      'network-request-failed' => const OtpNetworkException(),
      // Wrong or stale code — the cubit already renders these distinctly.
      'invalid-verification-code' ||
      'session-expired' ||
      'invalid-verification-id' =>
        Exception('invalid-code'),
      _ => Exception(e.code),
    };
  }
}
