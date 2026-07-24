import 'package:dio/dio.dart';
import 'package:soom_mobile/core/errors/api_exception.dart';

/// Turns Dio failures into [ApiException].
///
/// The one place that knows about Dio error types — keeping this boundary
/// tight is what lets the rest of the app stay transport-agnostic.
abstract final class ApiErrorMapper {
  /// Maps [error] to a normalized [ApiException].
  static ApiException map(DioException error) {
    final int? status = error.response?.statusCode;

    final ApiErrorKind kind = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout =>
        ApiErrorKind.timeout,
      DioExceptionType.connectionError => ApiErrorKind.noConnection,
      DioExceptionType.cancel => ApiErrorKind.cancelled,
      DioExceptionType.badCertificate => ApiErrorKind.unknown,
      DioExceptionType.badResponse => _kindForStatus(status),
      DioExceptionType.unknown => _isSocketFailure(error)
          ? ApiErrorKind.noConnection
          : ApiErrorKind.unknown,
    };

    final Map<String, dynamic>? body = _asMap(error.response?.data);

    return ApiException(
      kind: kind,
      statusCode: status,
      message: _messageFrom(body) ?? _defaultMessage(kind),
      code: body?['code'] as String?,
      fieldErrors: _fieldErrorsFrom(body),
    );
  }

  static ApiErrorKind _kindForStatus(int? status) {
    if (status == null) return ApiErrorKind.unknown;
    if (status == 401) return ApiErrorKind.unauthorized;
    if (status == 403) return ApiErrorKind.forbidden;
    if (status == 404) return ApiErrorKind.notFound;
    if (status == 422) return ApiErrorKind.validation;
    if (status == 429) return ApiErrorKind.rateLimited;
    if (status >= 500) return ApiErrorKind.server;
    return ApiErrorKind.unknown;
  }

  /// `DioExceptionType.unknown` wraps `SocketException` when DNS fails or the
  /// host is unreachable — that is an offline condition, not a mystery.
  static bool _isSocketFailure(DioException error) {
    final String description = error.error?.toString() ?? '';
    return description.contains('SocketException') ||
        description.contains('Failed host lookup');
  }

  static Map<String, dynamic>? _asMap(Object? data) =>
      data is Map<String, dynamic> ? data : null;

  static String? _messageFrom(Map<String, dynamic>? body) {
    final Object? message = body?['message'];
    return message is String && message.isNotEmpty ? message : null;
  }

  /// Reads Laravel's `errors: {field: [messages]}` shape.
  static Map<String, List<String>> _fieldErrorsFrom(
    Map<String, dynamic>? body,
  ) {
    final Object? errors = body?['errors'];
    if (errors is! Map<String, dynamic>) return const <String, List<String>>{};

    return errors.map(
      (String field, Object? messages) => MapEntry<String, List<String>>(
        field,
        messages is List
            ? messages.map((Object? m) => m.toString()).toList()
            : <String>[messages.toString()],
      ),
    );
  }

  static String _defaultMessage(ApiErrorKind kind) => switch (kind) {
        ApiErrorKind.noConnection => 'No internet connection.',
        ApiErrorKind.timeout => 'The request timed out.',
        ApiErrorKind.unauthorized => 'Your session has expired.',
        ApiErrorKind.forbidden => 'You do not have access to this.',
        ApiErrorKind.notFound => 'Not found.',
        ApiErrorKind.validation => 'Please check the highlighted fields.',
        ApiErrorKind.rateLimited => 'Too many attempts. Please wait.',
        ApiErrorKind.server => 'The server is having trouble.',
        ApiErrorKind.cancelled => 'The request was cancelled.',
        ApiErrorKind.unknown => 'Something went wrong.',
      };
}
