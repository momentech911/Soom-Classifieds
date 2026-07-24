import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:soom_mobile/core/api/api_client.dart';
import 'package:soom_mobile/core/api/api_config.dart';
import 'package:soom_mobile/core/api/connectivity_service.dart';

/// Connectivity stub — unit tests have no plugin channel.
class FakeConnectivity implements ConnectivityService {
  FakeConnectivity({this.connected = true});

  bool connected;

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<bool> get onConnectivityChanged => Stream<bool>.value(connected);
}

/// One canned HTTP reply.
class StubResponse {
  const StubResponse({required this.statusCode, this.body});

  final int statusCode;
  final Object? body;
}

/// Dio adapter that replays canned responses instead of doing I/O.
///
/// Matches on a path substring, so a test can stub `/health` and `/config`
/// independently. Unmatched paths fall back to [fallback].
class StubAdapter implements HttpClientAdapter {
  StubAdapter({
    Map<String, StubResponse>? routes,
    this.fallback = const StubResponse(statusCode: 404),
  }) : routes = routes ?? <String, StubResponse>{};

  /// Path substring -> reply.
  final Map<String, StubResponse> routes;

  /// Used when no route matches.
  final StubResponse fallback;

  /// Requests seen, so tests can assert on headers and ordering.
  final List<RequestOptions> received = <RequestOptions>[];

  /// Convenience: a single reply for every request.
  factory StubAdapter.single({required int statusCode, Object? body}) {
    return StubAdapter(
      fallback: StubResponse(statusCode: statusCode, body: body),
    );
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    received.add(options);

    final String path = options.uri.path;
    final StubResponse reply = routes.entries
            .where((MapEntry<String, StubResponse> e) => path.contains(e.key))
            .map((MapEntry<String, StubResponse> e) => e.value)
            .firstOrNull ??
        fallback;

    return ResponseBody.fromString(
      reply.body == null ? '' : jsonEncode(reply.body),
      reply.statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Test [ApiConfig] pointing at a local host.
const ApiConfig testApiConfig = ApiConfig(
  environment: ApiEnvironment.local,
  baseUrl: 'http://localhost:8000',
);

/// Builds an [ApiClient] wired to [adapter].
ApiClient buildTestApiClient({
  required StubAdapter adapter,
  bool connected = true,
  String? token,
  String locale = 'en',
  void Function()? onUnauthorized,
}) {
  final Dio dio = Dio()..httpClientAdapter = adapter;
  return ApiClient(
    config: testApiConfig,
    connectivity: FakeConnectivity(connected: connected),
    tokenProvider: () => token,
    localeCode: () => locale,
    onUnauthorized: onUnauthorized,
    dio: dio,
  );
}
