import 'package:dio/dio.dart';
import 'package:soom_mobile/core/api/api_config.dart';
import 'package:soom_mobile/core/api/api_error_mapper.dart';
import 'package:soom_mobile/core/api/connectivity_service.dart';
import 'package:soom_mobile/core/api/interceptors.dart';
import 'package:soom_mobile/core/errors/api_exception.dart';

/// The app's HTTP client.
///
/// Every network call goes through here. Repositories depend on this, not on
/// Dio, and it throws [ApiException] rather than [DioException] so failures
/// are already normalized by the time they reach a cubit.
class ApiClient {
  ApiClient({
    required this.config,
    required ConnectivityService connectivity,
    String? Function()? tokenProvider,
    String Function()? localeCode,
    void Function()? onUnauthorized,
    Dio? dio,
  }) : _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = config.apiBaseUrl
      ..connectTimeout = config.connectTimeout
      ..receiveTimeout = config.receiveTimeout
      ..sendTimeout = config.sendTimeout
      ..contentType = Headers.jsonContentType
      ..responseType = ResponseType.json;

    _dio.interceptors.addAll(<Interceptor>[
      ConnectivityInterceptor(connectivity: connectivity),
      AuthHeaderInterceptor(
        tokenProvider: tokenProvider ?? () => null,
        localeCode: localeCode ?? () => 'en',
      ),
      if (onUnauthorized != null)
        UnauthorizedInterceptor(onUnauthorized: onUnauthorized),
      LoggingInterceptor(enabled: config.isDebugEnvironment),
    ]);
  }

  final ApiConfig config;
  final Dio _dio;

  /// Escape hatch for wiring extra interceptors in tests or at startup.
  Dio get raw => _dio;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return _send<T>(
      () => _dio.get<T>(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return _send<T>(
      () => _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<T> put<T>(
    String path, {
    Object? data,
    CancelToken? cancelToken,
  }) {
    return _send<T>(
      () => _dio.put<T>(path, data: data, cancelToken: cancelToken),
    );
  }

  Future<T> patch<T>(
    String path, {
    Object? data,
    CancelToken? cancelToken,
  }) {
    return _send<T>(
      () => _dio.patch<T>(path, data: data, cancelToken: cancelToken),
    );
  }

  Future<T> delete<T>(
    String path, {
    Object? data,
    CancelToken? cancelToken,
  }) {
    return _send<T>(
      () => _dio.delete<T>(path, data: data, cancelToken: cancelToken),
    );
  }

  /// Backend liveness check — the Phase 0 gate calls this.
  ///
  /// Returns true only on a clean 2xx; any failure means "not reachable".
  Future<bool> healthCheck() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>('/health');
      final int status = response.statusCode ?? 0;
      return status >= 200 && status < 300;
    } on DioException {
      return false;
    }
  }

  /// Runs [request], normalizing every failure into [ApiException].
  Future<T> _send<T>(Future<Response<T>> Function() request) async {
    try {
      final Response<T> response = await request();
      final T? data = response.data;

      if (data == null) {
        throw ApiException(
          kind: ApiErrorKind.unknown,
          message: 'Empty response body.',
          statusCode: response.statusCode,
        );
      }
      return data;
    } on DioException catch (error) {
      // ConnectivityInterceptor rejects with a ready-made ApiException.
      final Object? inner = error.error;
      if (inner is ApiException) throw inner;

      throw ApiErrorMapper.map(error);
    }
  }

  void close() => _dio.close();
}
