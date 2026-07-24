import 'package:equatable/equatable.dart';

/// What went wrong, in terms the UI can act on.
///
/// Deliberately transport-agnostic: screens switch on this, never on Dio
/// types, so swapping the HTTP client would not ripple into the UI.
enum ApiErrorKind {
  /// Device is offline or the host is unreachable.
  noConnection,

  /// Request outlived its timeout.
  timeout,

  /// 401 — no or invalid session. Triggers sign-out.
  unauthorized,

  /// 403 — signed in but not allowed.
  forbidden,

  /// 404.
  notFound,

  /// 422 — validation failed; see [ApiException.fieldErrors].
  validation,

  /// 429 — rate limited. Relevant to OTP requests.
  rateLimited,

  /// 5xx.
  server,

  /// Request was cancelled deliberately.
  cancelled,

  /// Anything else, including a malformed response body.
  unknown,
}

/// A failed API call, normalized from whatever the transport threw.
///
/// Carries the backend's stable error [code] so the UI can branch on the
/// contract rather than on message text, which is localized and may change.
class ApiException extends Equatable implements Exception {
  const ApiException({
    required this.kind,
    required this.message,
    this.statusCode,
    this.code,
    this.fieldErrors = const <String, List<String>>{},
  });

  final ApiErrorKind kind;

  /// Human-readable fallback. Prefer a localized string keyed off [kind] or
  /// [code]; this is for logs and last-resort display.
  final String message;

  final int? statusCode;

  /// Stable machine-readable code from the API envelope, when present.
  final String? code;

  /// Per-field validation messages, for 422 responses.
  final Map<String, List<String>> fieldErrors;

  /// Whether retrying unchanged could plausibly succeed.
  bool get isRetryable =>
      kind == ApiErrorKind.noConnection ||
      kind == ApiErrorKind.timeout ||
      kind == ApiErrorKind.server;

  /// Whether this should force the session to end.
  bool get requiresSignOut => kind == ApiErrorKind.unauthorized;

  @override
  List<Object?> get props =>
      <Object?>[kind, message, statusCode, code, fieldErrors];

  @override
  String toString() =>
      'ApiException($kind, status: $statusCode, code: $code, $message)';
}
