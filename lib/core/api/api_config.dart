/// Which backend the app talks to.
enum ApiEnvironment {
  /// Local `soom-api` during development.
  local,

  /// Shared staging backend.
  staging,

  /// Live backend.
  production,
}

/// Base URLs, timeouts and versioning for the SOOM API.
///
/// Values come from `--dart-define` so a build is pinned at compile time and
/// no environment switcher ships in the binary:
///
/// ```bash
/// flutter run --dart-define=SOOM_ENV=staging
/// flutter run --dart-define=SOOM_API_BASE_URL=http://10.0.2.2:8000
/// ```
class ApiConfig {
  const ApiConfig({
    required this.environment,
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 20),
    this.sendTimeout = const Duration(seconds: 30),
  });

  /// Reads the config from `--dart-define`, defaulting to local development.
  factory ApiConfig.fromEnvironment() {
    const String env = String.fromEnvironment(
      'SOOM_ENV',
      defaultValue: 'local',
    );
    const String overrideUrl = String.fromEnvironment('SOOM_API_BASE_URL');

    final ApiEnvironment environment = switch (env) {
      'production' => ApiEnvironment.production,
      'staging' => ApiEnvironment.staging,
      _ => ApiEnvironment.local,
    };

    return ApiConfig(
      environment: environment,
      baseUrl: overrideUrl.isNotEmpty
          ? overrideUrl
          : _defaultBaseUrl(environment),
    );
  }

  final ApiEnvironment environment;

  /// Host root, without the `/api/v1` suffix — see [apiBaseUrl].
  final String baseUrl;

  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;

  /// The API version every endpoint sits under.
  static const String apiVersion = 'v1';

  /// Full versioned base, e.g. `https://api.soom.qa/api/v1`.
  String get apiBaseUrl {
    final String root =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return '$root/api/$apiVersion';
  }

  /// True for anything other than production — gates verbose logging.
  bool get isDebugEnvironment => environment != ApiEnvironment.production;

  static String _defaultBaseUrl(ApiEnvironment environment) {
    return switch (environment) {
      // 10.0.2.2 is the host machine as seen from the Android emulator.
      // iOS simulators reach the host on localhost; override with
      // --dart-define=SOOM_API_BASE_URL when running there.
      ApiEnvironment.local => 'http://10.0.2.2:8000',
      ApiEnvironment.staging => 'https://staging-api.soom.qa',
      ApiEnvironment.production => 'https://api.soom.qa',
    };
  }
}
