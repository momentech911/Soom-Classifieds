import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soom_mobile/app/bootstrap/bootstrap_cubit.dart';
import 'package:soom_mobile/app/bootstrap/bootstrap_state.dart';
import 'package:soom_mobile/core/auth/auth_state.dart';
import 'package:soom_mobile/core/storage/app_preferences.dart';

import '../../helpers/stub_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<(BootstrapCubit, AuthStateNotifier, AppPreferences)> build({
    required StubAdapter adapter,
    bool connected = true,
    String version = '1.0.0',
    AuthStatus initialAuth = AuthStatus.unknown,
    TargetPlatform platform = TargetPlatform.android,
  }) async {
    final AppPreferences preferences = await AppPreferences.create();
    final AuthStateNotifier auth = AuthStateNotifier(initial: initialAuth);

    final BootstrapCubit cubit = BootstrapCubit(
      apiClient: buildTestApiClient(adapter: adapter, connected: connected),
      preferences: preferences,
      auth: auth,
      appVersionReader: () async => version,
      platformOverride: platform,
    );
    return (cubit, auth, preferences);
  }

  /// A healthy backend returning [settings] from the settings endpoint.
  StubAdapter backend({Map<String, Object?> settings = const <String, Object?>{}}) {
    return StubAdapter(
      routes: <String, StubResponse>{
        '/health': const StubResponse(
          statusCode: 200,
          body: <String, Object>{'status': 'ok'},
        ),
        '/system/settings': StubResponse(statusCode: 200, body: settings),
      },
    );
  }

  group('happy path', () {
    test('reaches ready when the backend is healthy', () async {
      final (BootstrapCubit cubit, _, _) = await build(adapter: backend());

      await cubit.run();

      expect(cubit.state.status, BootstrapStatus.ready);
      expect(cubit.state.appVersion, '1.0.0');
    });

    test('releases the router by resolving auth to guest', () async {
      final (BootstrapCubit cubit, AuthStateNotifier auth, _) =
          await build(adapter: backend());
      expect(auth.isResolving, isTrue);

      await cubit.run();

      expect(auth.status, AuthStatus.guest);
    });

    test('does not clobber an already-restored session', () async {
      final (BootstrapCubit cubit, AuthStateNotifier auth, _) = await build(
        adapter: backend(),
        initialAuth: AuthStatus.authenticated,
      );

      await cubit.run();

      expect(auth.status, AuthStatus.authenticated);
    });

    test('records the version it launched', () async {
      final (BootstrapCubit cubit, _, AppPreferences preferences) =
          await build(adapter: backend(), version: '1.4.2');

      await cubit.run();

      expect(preferences.lastSeenVersion, '1.4.2');
    });
  });

  group('first run', () {
    test('is true on a clean install and then marked complete', () async {
      final (BootstrapCubit cubit, _, AppPreferences preferences) =
          await build(adapter: backend());

      await cubit.run();

      expect(cubit.state.isFirstRun, isTrue);
      expect(preferences.hasCompletedFirstRun, isTrue);
    });

    test('is false on a subsequent launch', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'has_completed_first_run': true,
      });
      final (BootstrapCubit cubit, _, _) = await build(adapter: backend());

      await cubit.run();

      expect(cubit.state.isFirstRun, isFalse);
    });
  });

  group('backend unreachable', () {
    test('reports a retryable failure when health check fails', () async {
      final (BootstrapCubit cubit, _, _) = await build(
        adapter: StubAdapter.single(statusCode: 500),
      );

      await cubit.run();

      expect(cubit.state.status, BootstrapStatus.backendUnreachable);
      expect(cubit.state.isRetryable, isTrue);
    });

    test('reports unreachable when the device is offline', () async {
      final (BootstrapCubit cubit, _, _) =
          await build(adapter: backend(), connected: false);

      await cubit.run();

      expect(cubit.state.status, BootstrapStatus.backendUnreachable);
    });

    test('leaves auth unresolved so the router keeps holding', () async {
      final (BootstrapCubit cubit, AuthStateNotifier auth, _) = await build(
        adapter: StubAdapter.single(statusCode: 500),
      );

      await cubit.run();

      expect(auth.isResolving, isTrue);
    });

    test('does not mark first run complete on failure', () async {
      final (BootstrapCubit cubit, _, AppPreferences preferences) =
          await build(adapter: StubAdapter.single(statusCode: 500));

      await cubit.run();

      expect(preferences.hasCompletedFirstRun, isFalse);
    });

    test('a retry succeeds once the backend recovers', () async {
      final StubAdapter adapter = StubAdapter.single(statusCode: 500);
      final (BootstrapCubit cubit, _, _) = await build(adapter: adapter);

      await cubit.run();
      expect(cubit.state.status, BootstrapStatus.backendUnreachable);

      adapter.routes['/health'] = const StubResponse(
        statusCode: 200,
        body: <String, Object>{'status': 'ok'},
      );
      adapter.routes['/system/settings'] =
          const StubResponse(statusCode: 200, body: <String, Object>{});

      await cubit.run();
      expect(cubit.state.status, BootstrapStatus.ready);
    });
  });

  group('maintenance mode', () {
    test('blocks when the backend reports maintenance', () async {
      final (BootstrapCubit cubit, _, _) = await build(
        adapter: backend(
          settings: <String, Object?>{'maintenance_mode': true},
        ),
      );

      await cubit.run();

      expect(cubit.state.status, BootstrapStatus.maintenance);
      expect(cubit.state.canProceed, isFalse);
      // Maintenance ends on its own, so retrying is worthwhile.
      expect(cubit.state.isRetryable, isTrue);
    });

    test('accepts Laravel string booleans', () async {
      // Settings are stored as strings server-side; "1" means true.
      final (BootstrapCubit cubit, _, _) = await build(
        adapter: backend(settings: <String, Object?>{'maintenance_mode': '1'}),
      );

      await cubit.run();

      expect(cubit.state.status, BootstrapStatus.maintenance);
    });

    test('takes precedence over a force update', () async {
      final (BootstrapCubit cubit, _, _) = await build(
        adapter: backend(
          settings: <String, Object?>{
            'maintenance_mode': true,
            'force_update': true,
            'android_version': '9.0.0',
          },
        ),
      );

      await cubit.run();

      expect(cubit.state.status, BootstrapStatus.maintenance);
    });
  });

  group('force update', () {
    test('blocks an out-of-date build when the backend mandates it', () async {
      final (BootstrapCubit cubit, _, _) = await build(
        adapter: backend(
          settings: <String, Object?>{
            'force_update': true,
            'android_version': '2.0.0',
            'play_store_link': 'https://play.google.com/store/apps/details?id=qa.soom',
          },
        ),
        version: '1.0.0',
      );

      await cubit.run();

      expect(cubit.state.status, BootstrapStatus.forceUpdateRequired);
      expect(cubit.state.requiredVersion, '2.0.0');
      expect(cubit.state.storeLink, contains('play.google.com'));
      // Retrying cannot change the installed version.
      expect(cubit.state.isRetryable, isFalse);
    });

    test('does NOT block when the backend only advertises a newer build',
        () async {
      // Out of date, but force_update is false — let the user through.
      final (BootstrapCubit cubit, _, _) = await build(
        adapter: backend(
          settings: <String, Object?>{
            'force_update': false,
            'android_version': '2.0.0',
          },
        ),
        version: '1.0.0',
      );

      await cubit.run();

      expect(cubit.state.status, BootstrapStatus.ready);
    });

    test('uses the Android floor on Android', () async {
      final (BootstrapCubit cubit, _, _) = await build(
        adapter: backend(
          settings: <String, Object?>{
            'force_update': true,
            'android_version': '2.0.0',
            'ios_version': '1.0.0',
          },
        ),
        version: '1.0.0',
        platform: TargetPlatform.android,
      );

      await cubit.run();

      expect(cubit.state.status, BootstrapStatus.forceUpdateRequired);
      expect(cubit.state.requiredVersion, '2.0.0');
    });

    test('uses the iOS floor on iOS, independently of Android', () async {
      // The versions diverge: Android demands 2.0.0, iOS only 1.0.0. An iOS
      // build at 1.0.0 must NOT be force-updated by the Android floor.
      final (BootstrapCubit cubit, _, _) = await build(
        adapter: backend(
          settings: <String, Object?>{
            'force_update': true,
            'android_version': '2.0.0',
            'ios_version': '1.0.0',
          },
        ),
        version: '1.0.0',
        platform: TargetPlatform.iOS,
      );

      await cubit.run();

      expect(cubit.state.status, BootstrapStatus.ready);
    });

    test('shows the App Store link on iOS', () async {
      final (BootstrapCubit cubit, _, _) = await build(
        adapter: backend(
          settings: <String, Object?>{
            'force_update': true,
            'ios_version': '3.0.0',
            'play_store_link': 'https://play.google.com/x',
            'app_store_link': 'https://apps.apple.com/x',
          },
        ),
        version: '1.0.0',
        platform: TargetPlatform.iOS,
      );

      await cubit.run();

      expect(cubit.state.storeLink, 'https://apps.apple.com/x');
    });

    test('proceeds when the settings endpoint is broken', () async {
      // A missing or failing settings endpoint must never lock users out.
      final StubAdapter adapter = StubAdapter(
        routes: <String, StubResponse>{
          '/health': const StubResponse(
            statusCode: 200,
            body: <String, Object>{'status': 'ok'},
          ),
          '/system/settings': const StubResponse(statusCode: 500),
        },
      );
      final (BootstrapCubit cubit, _, _) = await build(adapter: adapter);

      await cubit.run();

      expect(cubit.state.status, BootstrapStatus.ready);
    });

    test('proceeds when no floor is declared for this platform', () async {
      final (BootstrapCubit cubit, _, _) = await build(
        adapter: backend(settings: <String, Object?>{'force_update': true}),
        version: '0.0.1',
      );

      await cubit.run();

      expect(cubit.state.status, BootstrapStatus.ready);
    });

    test('reads settings wrapped in a data envelope', () async {
      // B0.2 has not frozen the envelope, so both shapes are accepted.
      final StubAdapter adapter = StubAdapter(
        routes: <String, StubResponse>{
          '/health': const StubResponse(
            statusCode: 200,
            body: <String, Object>{'status': 'ok'},
          ),
          '/system/settings': const StubResponse(
            statusCode: 200,
            body: <String, Object>{
              'data': <String, Object>{'maintenance_mode': true},
            },
          ),
        },
      );
      final (BootstrapCubit cubit, _, _) = await build(adapter: adapter);

      await cubit.run();

      expect(cubit.state.status, BootstrapStatus.maintenance);
    });

    test('does not mark first run complete while blocked', () async {
      final (BootstrapCubit cubit, _, AppPreferences preferences) =
          await build(
        adapter: backend(
          settings: <String, Object?>{
            'force_update': true,
            'android_version': '9.0.0',
          },
        ),
        version: '1.0.0',
      );

      await cubit.run();

      expect(preferences.hasCompletedFirstRun, isFalse);
    });
  });
}
