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

  /// Builds a cubit over [adapter], with [auth] starting unresolved.
  Future<(BootstrapCubit, AuthStateNotifier, AppPreferences)> build({
    required StubAdapter adapter,
    bool connected = true,
    String version = '1.0.0',
    AuthStatus initialAuth = AuthStatus.unknown,
  }) async {
    final AppPreferences preferences = await AppPreferences.create();
    final AuthStateNotifier auth = AuthStateNotifier(initial: initialAuth);

    final BootstrapCubit cubit = BootstrapCubit(
      apiClient: buildTestApiClient(adapter: adapter, connected: connected),
      preferences: preferences,
      auth: auth,
      appVersionReader: () async => version,
    );
    return (cubit, auth, preferences);
  }

  /// A backend that is healthy and imposes no version floor.
  StubAdapter healthyBackend({String? minimumVersion}) {
    return StubAdapter(
      routes: <String, StubResponse>{
        '/health': const StubResponse(
          statusCode: 200,
          body: <String, Object>{'status': 'ok'},
        ),
        '/config': StubResponse(
          statusCode: 200,
          body: <String, Object?>{
            'minimum_supported_version': ?minimumVersion,
          },
        ),
      },
    );
  }

  group('happy path', () {
    test('reaches ready when the backend is healthy', () async {
      final (BootstrapCubit cubit, _, _) =
          await build(adapter: healthyBackend());

      await cubit.run();

      expect(cubit.state.status, BootstrapStatus.ready);
      expect(cubit.state.canProceed, isTrue);
      expect(cubit.state.appVersion, '1.0.0');
    });

    test('releases the router by resolving auth to guest', () async {
      final (BootstrapCubit cubit, AuthStateNotifier auth, _) =
          await build(adapter: healthyBackend());
      expect(auth.isResolving, isTrue);

      await cubit.run();

      expect(auth.isResolving, isFalse);
      expect(auth.status, AuthStatus.guest);
    });

    test('does not clobber an already-restored session', () async {
      final (BootstrapCubit cubit, AuthStateNotifier auth, _) = await build(
        adapter: healthyBackend(),
        initialAuth: AuthStatus.authenticated,
      );

      await cubit.run();

      expect(auth.status, AuthStatus.authenticated);
    });

    test('records the version it launched', () async {
      final (BootstrapCubit cubit, _, AppPreferences preferences) =
          await build(adapter: healthyBackend(), version: '1.4.2');

      await cubit.run();

      expect(preferences.lastSeenVersion, '1.4.2');
    });
  });

  group('first run', () {
    test('is true on a clean install and then marked complete', () async {
      final (BootstrapCubit cubit, _, AppPreferences preferences) =
          await build(adapter: healthyBackend());

      await cubit.run();

      expect(cubit.state.isFirstRun, isTrue);
      expect(preferences.hasCompletedFirstRun, isTrue);
    });

    test('is false on a subsequent launch', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'has_completed_first_run': true,
      });
      final (BootstrapCubit cubit, _, _) =
          await build(adapter: healthyBackend());

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
      expect(cubit.state.canProceed, isFalse);
    });

    test('reports unreachable when the device is offline', () async {
      final (BootstrapCubit cubit, _, _) = await build(
        adapter: healthyBackend(),
        connected: false,
      );

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

      // The user has not actually seen the app yet.
      expect(preferences.hasCompletedFirstRun, isFalse);
    });

    test('a retry succeeds once the backend recovers', () async {
      final StubAdapter adapter = StubAdapter.single(statusCode: 500);
      final (BootstrapCubit cubit, _, _) = await build(adapter: adapter);

      await cubit.run();
      expect(cubit.state.status, BootstrapStatus.backendUnreachable);

      // Backend comes back.
      adapter.routes['/health'] = const StubResponse(
        statusCode: 200,
        body: <String, Object>{'status': 'ok'},
      );
      adapter.routes['/config'] = const StubResponse(
        statusCode: 200,
        body: <String, Object>{},
      );

      await cubit.run();
      expect(cubit.state.status, BootstrapStatus.ready);
    });
  });

  group('force update', () {
    test('blocks when the build is below the backend floor', () async {
      final (BootstrapCubit cubit, _, _) = await build(
        adapter: healthyBackend(minimumVersion: '2.0.0'),
        version: '1.0.0',
      );

      await cubit.run();

      expect(cubit.state.status, BootstrapStatus.forceUpdateRequired);
      expect(cubit.state.canProceed, isFalse);
      // Not retryable: retrying cannot change the installed version.
      expect(cubit.state.isRetryable, isFalse);
      expect(cubit.state.minimumSupportedVersion, '2.0.0');
    });

    test('allows a build that meets the floor', () async {
      final (BootstrapCubit cubit, _, _) = await build(
        adapter: healthyBackend(minimumVersion: '1.0.0'),
        version: '1.0.0',
      );

      await cubit.run();

      expect(cubit.state.status, BootstrapStatus.ready);
    });

    test('proceeds when the backend declares no floor', () async {
      final (BootstrapCubit cubit, _, _) = await build(
        adapter: healthyBackend(),
        version: '0.0.1',
      );

      await cubit.run();

      expect(cubit.state.status, BootstrapStatus.ready);
    });

    test('proceeds when the config endpoint is broken', () async {
      // A missing or failing /config must never lock users out.
      final StubAdapter adapter = StubAdapter(
        routes: <String, StubResponse>{
          '/health': const StubResponse(
            statusCode: 200,
            body: <String, Object>{'status': 'ok'},
          ),
          '/config': const StubResponse(statusCode: 500),
        },
      );
      final (BootstrapCubit cubit, _, _) = await build(adapter: adapter);

      await cubit.run();

      expect(cubit.state.status, BootstrapStatus.ready);
    });

    test('does not mark first run complete while blocked', () async {
      final (BootstrapCubit cubit, _, AppPreferences preferences) =
          await build(
        adapter: healthyBackend(minimumVersion: '9.0.0'),
        version: '1.0.0',
      );

      await cubit.run();

      expect(preferences.hasCompletedFirstRun, isFalse);
    });
  });

  group('state transitions', () {
    test('starts in progress and ends ready', () async {
      final (BootstrapCubit cubit, _, _) =
          await build(adapter: healthyBackend());

      final List<BootstrapStatus> seen = <BootstrapStatus>[];
      final subscription =
          cubit.stream.listen((BootstrapState s) => seen.add(s.status));

      await cubit.run();
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(seen.last, BootstrapStatus.ready);
    });
  });
}
