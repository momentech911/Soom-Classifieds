import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soom_mobile/features/auth/domain/qatar_phone.dart';

/// Where the phone login screen is in its lifecycle.
///
/// Mirrors the states UX Spec v2.0 lists for S02: Default, Invalid number,
/// Rate limited, Network error.
enum PhoneLoginStatus {
  /// Editing, nothing submitted.
  editing,

  /// Requesting an OTP.
  submitting,

  /// OTP sent — move to S03.
  codeSent,

  /// Too many requests for this number.
  rateLimited,

  /// Could not reach the backend.
  networkError,

  /// Anything else.
  failure,
}

class PhoneLoginState extends Equatable {
  const PhoneLoginState({
    this.input = '',
    this.status = PhoneLoginStatus.editing,
    this.error,
    this.showValidation = false,
    this.retryAfter,
  });

  /// Raw text as typed. Kept unnormalised so the field does not fight the
  /// user mid-edit.
  final String input;

  final PhoneLoginStatus status;

  /// Why the current input is invalid, if it is.
  final QatarPhoneError? error;

  /// Whether to surface [error].
  ///
  /// Validation runs on every keystroke, but showing "too short" while
  /// someone is still typing their second digit is hostile. This stays false
  /// until they try to submit, then turns on for live feedback.
  final bool showValidation;

  /// How long until another OTP may be requested, when rate limited.
  final Duration? retryAfter;

  /// The parsed number, or null when the input is not yet valid.
  QatarPhone? get phone => QatarPhone.tryParse(input);

  /// Whether the input is a valid Qatar mobile.
  bool get isValid => error == null && input.isNotEmpty;

  /// Whether Continue should be enabled.
  ///
  /// Enabled as soon as anything is typed, **not** only when the number is
  /// valid. A button greyed out for an invalid number tells the user nothing:
  /// they are left with a dead control and no reason. Tapping it instead
  /// reveals the specific problem — "starts with 3, 5, 6 or 7" — which is the
  /// "Invalid number" state UX Spec v2.0 lists for S02.
  ///
  /// [submit] still refuses to request an OTP for an invalid number.
  bool get canSubmit => input.trim().isNotEmpty && !isSubmitting;

  /// Whether to render the field in its error style.
  bool get showsError => showValidation && error != null;

  bool get isSubmitting => status == PhoneLoginStatus.submitting;

  PhoneLoginState copyWith({
    String? input,
    PhoneLoginStatus? status,
    QatarPhoneError? error,
    bool clearError = false,
    bool? showValidation,
    Duration? retryAfter,
    bool clearRetryAfter = false,
  }) {
    return PhoneLoginState(
      input: input ?? this.input,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      showValidation: showValidation ?? this.showValidation,
      retryAfter: clearRetryAfter ? null : (retryAfter ?? this.retryAfter),
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[input, status, error, showValidation, retryAfter];
}

/// Drives S02 — Phone Login.
///
/// Owns validation and submission only. Sending the SMS is delegated via
/// [requestOtp] so this stays testable without Firebase, and so swapping the
/// OTP provider does not touch the screen.
class PhoneLoginCubit extends Cubit<PhoneLoginState> {
  PhoneLoginCubit({required this.requestOtp}) : super(const PhoneLoginState());

  /// Sends an OTP to [phone]. Throws to signal failure.
  final Future<void> Function(QatarPhone phone) requestOtp;

  /// Called on every keystroke.
  void onInputChanged(String input) {
    emit(
      state.copyWith(
        input: input,
        error: QatarPhone.validate(input),
        clearError: QatarPhone.validate(input) == null,
        // Any edit clears a previous failure — the user is acting on it.
        status: state.status == PhoneLoginStatus.editing
            ? null
            : PhoneLoginStatus.editing,
        clearRetryAfter: true,
      ),
    );
  }

  /// Submits the number and requests an OTP.
  Future<void> submit() async {
    // Reveal validation from here on, whatever happens next.
    emit(state.copyWith(showValidation: true));

    final QatarPhone? phone = state.phone;
    if (phone == null || state.isSubmitting) return;

    emit(state.copyWith(status: PhoneLoginStatus.submitting));

    try {
      await requestOtp(phone);
      emit(state.copyWith(status: PhoneLoginStatus.codeSent));
    } on OtpRateLimitedException catch (e) {
      emit(
        state.copyWith(
          status: PhoneLoginStatus.rateLimited,
          retryAfter: e.retryAfter,
        ),
      );
    } on OtpNetworkException {
      emit(state.copyWith(status: PhoneLoginStatus.networkError));
    } on Object {
      emit(state.copyWith(status: PhoneLoginStatus.failure));
    }
  }

  /// Resets after the screen has navigated away on [PhoneLoginStatus.codeSent].
  void reset() => emit(const PhoneLoginState());
}

/// Too many OTP requests for this number.
class OtpRateLimitedException implements Exception {
  const OtpRateLimitedException({this.retryAfter});

  /// How long to wait, when the backend says.
  final Duration? retryAfter;
}

/// The OTP request could not reach the backend.
class OtpNetworkException implements Exception {
  const OtpNetworkException();
}
