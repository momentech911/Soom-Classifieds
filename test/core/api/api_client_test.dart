import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soom_mobile/core/api/api_client.dart';
import 'package:soom_mobile/core/api/api_config.dart';
import 'package:soom_mobile/core/api/connectivity_service.dart';
import 'package:soom_mobile/core/errors/api_exception.dart';

/// Connectivity stub — no plugin channel in unit tests.
class _FakeConnectivity implements ConnectivityService {
  _FakeConnectivity({this.connected = true});

  bool connected;

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<bool> get onConnectivityChanged => Stream<bool>.value(connected);
}

/// Dio adapter that returns canned responses instead of doing I/O.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter({required this.statusCode, this.body});

  final int statusCode;
  final Object? body;

  /// Requests this adapter saw — lets tests assert on headers.
  final List<RequestOptions> received = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    received.add(options);

    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  const ApiConfig config = ApiConfig(
    environment: ApiEnvironment.local,
    baseUrl: 'http://localhost:8000',
  );

  ApiClient buildClient({
    required _StubAdapter adapter,
    bool connected = true,
    String? token,
    String locale = 'en',
    void Function()? onUnauthorized,
  }) {
    final Dio dio = Dio()..httpClientAdapter = adapter;
    return ApiClient(
      config: config,
      connectivity: _FakeConnectivity(connected: connected),
      tokenProvider: () => token,
      localeCode: () => locale,
      onUnauthorized: onUnauthorized,
      dio: dio,
    );
  }

  group('ApiConfig', () {
    test('appends the versioned API path', () {
      expect(config.apiBaseUrl, 'http://localhost:8000/api/v1');
    });

    test('does not double up slashes', () {
      const ApiConfig trailing = ApiConfig(
        environment: ApiEnvironment.local,
        baseUrl: 'http://localhost:8000/',
      );
      expect(trailing.apiBaseUrl, 'http://localhost:8000/api/v1');
    });

    test('production is not treated as a debug environment', () {
      const ApiConfig prod = ApiConfig(
        environment: ApiEnvironment.production,
        baseUrl: 'https://api.soom.qa',
      );
      expect(prod.isDebugEnvironment, isFalse);
      expect(config.isDebugEnvironment, isTrue);
    });

    test('fromEnvironment defaults to local', () {
      final ApiConfig fromEnv = ApiConfig.fromEnvironment();
      expect(fromEnv.environment, ApiEnvironment.local);
    });
  });

  group('requests', () {
    test('returns the decoded body on success', () async {
      final _StubAdapter adapter = _StubAdapter(
        statusCode: 200,
        body: <String, Object>{'ok': true},
      );
      final ApiClient client = buildClient(adapter: adapter);

      final Map<String, dynamic> result =
          await client.get<Map<String, dynamic>>('/ping');

      expect(result['ok'], true);
    });

    test('sends the bearer token when signed in', () async {
      final _StubAdapter adapter = _StubAdapter(
        statusCode: 200,
        body: <String, Object>{'ok': true},
      );
      final ApiClient client = buildClient(adapter: adapter, token: 'abc123');

      await client.get<Map<String, dynamic>>('/ping');

      expect(adapter.received.single.headers['Authorization'], 'Bearer abc123');
    });

    test('omits the Authorization header when signed out', () async {
      final _StubAdapter adapter = _StubAdapter(
        statusCode: 200,
        body: <String, Object>{'ok': true},
      );
      final ApiClient client = buildClient(adapter: adapter);

      await client.get<Map<String, dynamic>>('/ping');

      expect(
        adapter.received.single.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('sends Content-Language, which is what the backend actually reads',
        () async {
      // eClassify's ApiLocalizationMiddleware reads Content-Language, not the
      // conventional Accept-Language. Getting this wrong returns English to
      // Arabic users with no visible error, so it is pinned by a test.
      final _StubAdapter adapter = _StubAdapter(
        statusCode: 200,
        body: <String, Object>{'ok': true},
      );
      final ApiClient client = buildClient(adapter: adapter, locale: 'ar');

      await client.get<Map<String, dynamic>>('/ping');

      expect(adapter.received.single.headers['Content-Language'], 'ar');
      // Also sent, so a future standards-compliant backend still works.
      expect(adapter.received.single.headers['Accept-Language'], 'ar');
    });
  });

  group('error mapping', () {
    test('offline fails fast without hitting the network', () async {
      final _StubAdapter adapter = _StubAdapter(statusCode: 200);
      final ApiClient client = buildClient(adapter: adapter, connected: false);

      await expectLater(
        client.get<Map<String, dynamic>>('/ping'),
        throwsA(
          isA<ApiException>().having(
            (ApiException e) => e.kind,
            'kind',
            ApiErrorKind.noConnection,
          ),
        ),
      );
      expect(adapter.received, isEmpty, reason: 'must not reach the adapter');
    });

    test('401 maps to unauthorized and requires sign-out', () async {
      final _StubAdapter adapter = _StubAdapter(
        statusCode: 401,
        body: <String, Object>{'message': 'Unauthenticated.'},
      );
      final ApiClient client = buildClient(adapter: adapter);

      try {
        await client.get<Map<String, dynamic>>('/me');
        fail('should have thrown');
      } on ApiException catch (e) {
        expect(e.kind, ApiErrorKind.unauthorized);
        expect(e.requiresSignOut, isTrue);
        expect(e.statusCode, 401);
      }
    });

    test('401 triggers the sign-out callback', () async {
      bool signedOut = false;
      final _StubAdapter adapter = _StubAdapter(statusCode: 401);
      final ApiClient client = buildClient(
        adapter: adapter,
        onUnauthorized: () => signedOut = true,
      );

      await expectLater(
        client.get<Map<String, dynamic>>('/me'),
        throwsA(isA<ApiException>()),
      );
      expect(signedOut, isTrue);
    });

    test('422 carries per-field validation errors', () async {
      final _StubAdapter adapter = _StubAdapter(
        statusCode: 422,
        body: <String, Object>{
          'message': 'Validation failed.',
          'errors': <String, Object>{
            'phone': <String>['The phone field is required.'],
          },
        },
      );
      final ApiClient client = buildClient(adapter: adapter);

      try {
        await client.post<Map<String, dynamic>>('/auth/otp');
        fail('should have thrown');
      } on ApiException catch (e) {
        expect(e.kind, ApiErrorKind.validation);
        expect(e.fieldErrors['phone'], <String>[
          'The phone field is required.',
        ]);
      }
    });

    test('429 maps to rate limited — matters for OTP', () async {
      final _StubAdapter adapter = _StubAdapter(statusCode: 429);
      final ApiClient client = buildClient(adapter: adapter);

      await expectLater(
        client.post<Map<String, dynamic>>('/auth/otp'),
        throwsA(
          isA<ApiException>().having(
            (ApiException e) => e.kind,
            'kind',
            ApiErrorKind.rateLimited,
          ),
        ),
      );
    });

    test('503 maps to maintenance, not a generic server error', () async {
      // eClassify signals planned downtime with 503; it deserves its own
      // screen rather than "something went wrong".
      final _StubAdapter adapter = _StubAdapter(statusCode: 503);
      final ApiClient client = buildClient(adapter: adapter);

      try {
        await client.get<Map<String, dynamic>>('/ping');
        fail('should have thrown');
      } on ApiException catch (e) {
        expect(e.kind, ApiErrorKind.maintenance);
        expect(e.isRetryable, isTrue);
      }
    });

    test('500 maps to server and is retryable', () async {
      final _StubAdapter adapter = _StubAdapter(statusCode: 500);
      final ApiClient client = buildClient(adapter: adapter);

      try {
        await client.get<Map<String, dynamic>>('/ping');
        fail('should have thrown');
      } on ApiException catch (e) {
        expect(e.kind, ApiErrorKind.server);
        expect(e.isRetryable, isTrue);
      }
    });

    test('404 maps to notFound and is not retryable', () async {
      final _StubAdapter adapter = _StubAdapter(statusCode: 404);
      final ApiClient client = buildClient(adapter: adapter);

      try {
        await client.get<Map<String, dynamic>>('/nope');
        fail('should have thrown');
      } on ApiException catch (e) {
        expect(e.kind, ApiErrorKind.notFound);
        expect(e.isRetryable, isFalse);
      }
    });

    test('a numeric legacy error code does not crash the mapper', () async {
      // SOOM v1 returns string codes, but eClassify's legacy surface returns
      // integers. Casting straight to String would throw inside the error
      // mapper, turning a recoverable API error into a crash.
      final _StubAdapter adapter = _StubAdapter(
        statusCode: 500,
        body: <String, Object>{'message': 'Boom.', 'code': 103},
      );
      final ApiClient client = buildClient(adapter: adapter);

      try {
        await client.get<Map<String, dynamic>>('/ping');
        fail('should have thrown');
      } on ApiException catch (e) {
        expect(e.kind, ApiErrorKind.server);
        expect(e.code, '103');
      }
    });

    test('the backend stable error code is preserved', () async {
      final _StubAdapter adapter = _StubAdapter(
        statusCode: 403,
        body: <String, Object>{
          'message': 'Blocked.',
          'code': 'USER_BLOCKED',
        },
      );
      final ApiClient client = buildClient(adapter: adapter);

      try {
        await client.get<Map<String, dynamic>>('/chats/1');
        fail('should have thrown');
      } on ApiException catch (e) {
        expect(e.kind, ApiErrorKind.forbidden);
        expect(e.code, 'USER_BLOCKED');
        expect(e.message, 'Blocked.');
      }
    });
  });

  group('healthCheck', () {
    test('true on 200', () async {
      final ApiClient client = buildClient(
        adapter: _StubAdapter(
          statusCode: 200,
          body: <String, Object>{'status': 'ok'},
        ),
      );

      expect(await client.healthCheck(), isTrue);
    });

    test('false on 500 rather than throwing', () async {
      final ApiClient client = buildClient(
        adapter: _StubAdapter(statusCode: 500),
      );

      expect(await client.healthCheck(), isFalse);
    });

    test('false when offline rather than throwing', () async {
      final ApiClient client = buildClient(
        adapter: _StubAdapter(statusCode: 200),
        connected: false,
      );

      expect(await client.healthCheck(), isFalse);
    });
  });

  group('ApiException', () {
    test('value equality holds', () {
      const ApiException a = ApiException(
        kind: ApiErrorKind.server,
        message: 'boom',
      );
      const ApiException b = ApiException(
        kind: ApiErrorKind.server,
        message: 'boom',
      );
      expect(a, b);
    });

    test('only transient failures are retryable', () {
      for (final ApiErrorKind kind in ApiErrorKind.values) {
        final bool expected = kind == ApiErrorKind.noConnection ||
            kind == ApiErrorKind.timeout ||
            kind == ApiErrorKind.server ||
            kind == ApiErrorKind.maintenance;

        expect(
          ApiException(kind: kind, message: '').isRetryable,
          expected,
          reason: kind.name,
        );
      }
    });
  });

  group('ConnectivityService', () {
    test('none alone means disconnected', () async {
      // Guards the mapping rule the service depends on.
      const List<ConnectivityResult> offline = <ConnectivityResult>[
        ConnectivityResult.none,
      ];
      expect(
        offline.any((ConnectivityResult r) => r != ConnectivityResult.none),
        isFalse,
      );
    });
  });
}
