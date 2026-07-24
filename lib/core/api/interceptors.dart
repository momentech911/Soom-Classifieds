import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:soom_mobile/core/api/connectivity_service.dart';
import 'package:soom_mobile/core/errors/api_exception.dart';

/// Attaches the bearer token and the locale to every request.
///
/// The token is read through a callback rather than held here, so it always
/// reflects the current session without this interceptor being rebuilt.
class AuthHeaderInterceptor extends Interceptor {
  AuthHeaderInterceptor({required this.tokenProvider, required this.localeCode});

  /// Returns the current token, or null when signed out.
  final String? Function() tokenProvider;

  /// Returns the active language code (`ar` / `en`).
  final String Function() localeCode;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final String? token = tokenProvider();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // The backend localizes by Content-Language, NOT Accept-Language.
    // eClassify's ApiLocalizationMiddleware reads Content-Language and the
    // SOOM API is adapted from it — sending the conventional Accept-Language
    // would silently return English for Arabic users. Both are sent so the
    // app still works if the backend is later corrected to the standard.
    options.headers['Content-Language'] = localeCode();
    options.headers['Accept-Language'] = localeCode();
    options.headers['Accept'] = 'application/json';

    handler.next(options);
  }
}

/// Fails fast when the device is offline.
///
/// Saves a timeout's worth of waiting and produces a precise error instead of
/// a vague connection failure.
class ConnectivityInterceptor extends Interceptor {
  ConnectivityInterceptor({required this.connectivity});

  final ConnectivityService connectivity;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (await connectivity.isConnected) {
      handler.next(options);
      return;
    }

    handler.reject(
      DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: const ApiException(
          kind: ApiErrorKind.noConnection,
          message: 'No internet connection.',
        ),
      ),
    );
  }
}

/// Logs requests and responses in non-production builds.
class LoggingInterceptor extends Interceptor {
  const LoggingInterceptor({this.enabled = true});

  final bool enabled;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (enabled) {
      _log('→ ${options.method} ${options.uri}');
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (enabled) {
      _log(
        '← ${response.statusCode} '
        '${response.requestOptions.method} ${response.requestOptions.uri}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (enabled) {
      _log(
        '✗ ${err.response?.statusCode ?? err.type.name} '
        '${err.requestOptions.method} ${err.requestOptions.uri}',
      );
    }
    handler.next(err);
  }

  // developer.log rather than print — avoid_print, and it is filterable.
  void _log(String message) => developer.log(message, name: 'SOOM.api');
}

/// Signs the user out when the backend rejects the token.
///
/// A 401 means the session is gone server-side; the app must not keep
/// pretending otherwise.
class UnauthorizedInterceptor extends Interceptor {
  const UnauthorizedInterceptor({required this.onUnauthorized});

  final void Function() onUnauthorized;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      onUnauthorized();
    }
    handler.next(err);
  }
}
