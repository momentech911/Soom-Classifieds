import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soom_mobile/core/utils/arabic_digits.dart';
import 'package:soom_mobile/features/auth/domain/qatar_phone.dart';
import 'package:soom_mobile/features/auth/presentation/phone_login_cubit.dart';

/// Where OTP verification stands.
///
/// Mirrors the states UX Spec v2.0 lists for S03: Default, Auto-filled,
/// Invalid, Expired, Rate limited.
enum OtpStatus {
  /// Waiting for the code.
  entering,

  /// Verifying with the provider.
  verifying,

  /// Verified — resume the interrupted action.
  verified,

  /// Wrong code.
  invalid,

  /// The code timed out. Resend is the only way forward.
  expired,

  /// Too many resends.
  rateLimited,

  /// Anything else.
  failure,
}

class OtpState extends Equatable {
  const OtpState({
    required this.phone,
    this.code = '',
    this.status = OtpStatus.entering,
    this.expiresIn = OtpCubit.codeLifetime,
    this.resendIn = OtpCubit.resendCooldown,
    this.wasAutoFilled = false,
  });

  /// The number the code was sent to.
  final QatarPhone phone;

  /// Digits entered so far, 0-6.
  final String code;

  final OtpStatus status;

  /// Time left before the code expires.
  final Duration expiresIn;

  /// Time left before another code may be requested.
  final Duration resendIn;

  /// Whether the platform filled the code in rather than the user.
  final bool wasAutoFilled;

  bool get isComplete => code.length == OtpCubit.codeLength;

  bool get isVerifying => status == OtpStatus.verifying;

  /// Verify is available once six digits are in and the code is still alive.
  bool get canVerify =>
      isComplete && !isVerifying && status != OtpStatus.expired;

  /// Resend unlocks when the cooldown reaches zero.
  bool get canResend => resendIn == Duration.zero && !isVerifying;

  bool get hasExpired => status == OtpStatus.expired;

  OtpState copyWith({
    String? code,
    OtpStatus? status,
    Duration? expiresIn,
    Duration? resendIn,
    bool? wasAutoFilled,
  }) {
    return OtpState(
      phone: phone,
      code: code ?? this.code,
      status: status ?? this.status,
      expiresIn: expiresIn ?? this.expiresIn,
      resendIn: resendIn ?? this.resendIn,
      wasAutoFilled: wasAutoFilled ?? this.wasAutoFilled,
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[phone, code, status, expiresIn, resendIn, wasAutoFilled];
}

/// Drives S03 — OTP Verification.
///
/// Runs two independent countdowns: how long the code stays valid, and how
/// long until another may be requested. They are separate because the resend
/// cooldown is shorter — a user whose SMS never arrived should not have to
/// wait out the full code lifetime.
///
/// Verification and resending are injected so this is testable without
/// Firebase, and so swapping provider does not touch the screen.
class OtpCubit extends Cubit<OtpState> {
  OtpCubit({
    required QatarPhone phone,
    required this.verifyCode,
    required this.resendCode,
  }) : super(OtpState(phone: phone));

  /// Digits in the code. Six, per the UX spec.
  static const int codeLength = 6;

  /// How long a code stays valid.
  static const Duration codeLifetime = Duration(minutes: 2);

  /// How long before another code may be requested.
  static const Duration resendCooldown = Duration(seconds: 60);

  /// Verifies [code]. Throws to signal failure.
  final Future<void> Function(String code) verifyCode;

  /// Requests a fresh code. Throws to signal failure.
  final Future<void> Function() resendCode;

  Timer? _ticker;

  /// Starts both countdowns. The screen calls this once it is mounted.
  ///
  /// Deliberately not done in the constructor: a constructor that silently
  /// starts a periodic timer is a trap. Every test that merely builds the
  /// cubit would leak one, and callers get a side effect they did not ask
  /// for. Tests that do not care about time simply never call this.
  void start() => _startTimers();

  /// Stops the countdowns. Called when the screen is disposed, so a screen
  /// the user has left does not keep ticking in the background.
  void stop() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _startTimers() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (isClosed) return;

    final Duration expires = state.expiresIn - const Duration(seconds: 1);
    final Duration resend = state.resendIn - const Duration(seconds: 1);

    final bool justExpired =
        expires <= Duration.zero && state.status != OtpStatus.expired;

    emit(
      state.copyWith(
        expiresIn: expires.isNegative ? Duration.zero : expires,
        resendIn: resend.isNegative ? Duration.zero : resend,
        // Expiry overrides whatever else was showing: the code is dead and
        // the only way forward is a resend.
        status: justExpired ? OtpStatus.expired : null,
      ),
    );

    if (expires <= Duration.zero && resend <= Duration.zero) {
      _ticker?.cancel();
    }
  }

  /// Called as the user types. Non-digits are ignored.
  ///
  /// Arabic-Indic digits are converted, so a code typed on an Arabic keyboard
  /// works exactly like one typed on a Western one.
  void onCodeChanged(String code, {bool autoFilled = false}) {
    final String digits = ArabicDigits.digitsOnly(code);
    final String trimmed = digits.length > codeLength
        ? digits.substring(0, codeLength)
        : digits;

    emit(
      state.copyWith(
        code: trimmed,
        wasAutoFilled: autoFilled,
        // Editing clears a previous rejection, but never clears expiry —
        // that needs a new code, not a new guess.
        status: state.status == OtpStatus.invalid ? OtpStatus.entering : null,
      ),
    );
  }

  /// Verifies the entered code.
  Future<void> verify() async {
    if (!state.canVerify) return;

    emit(state.copyWith(status: OtpStatus.verifying));

    try {
      await verifyCode(state.code);
      _ticker?.cancel();
      emit(state.copyWith(status: OtpStatus.verified));
    } on OtpRateLimitedException {
      emit(state.copyWith(status: OtpStatus.rateLimited));
    } on Object {
      emit(state.copyWith(status: OtpStatus.invalid));
    }
  }

  /// Requests a new code and restarts both countdowns.
  Future<void> resend() async {
    if (!state.canResend) return;

    try {
      await resendCode();

      emit(
        state.copyWith(
          code: '',
          status: OtpStatus.entering,
          expiresIn: codeLifetime,
          resendIn: resendCooldown,
          wasAutoFilled: false,
        ),
      );
      _startTimers();
    } on OtpRateLimitedException {
      emit(state.copyWith(status: OtpStatus.rateLimited));
    } on Object {
      emit(state.copyWith(status: OtpStatus.failure));
    }
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
