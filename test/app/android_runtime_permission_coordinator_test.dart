import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app/android_runtime_permission_coordinator.dart';

void main() {
  test('requests all missing runtime permissions in a stable order', () async {
    final gateway = _FakeAndroidRuntimePermissionGateway();
    final coordinator = AndroidRuntimePermissionCoordinator(
      gateway: gateway,
      isAndroid: true,
    );

    final permanentlyDenied = await coordinator.checkAndRequestMissing();

    expect(permanentlyDenied, isEmpty);
    expect(gateway.requests, AndroidRuntimePermissionCoordinator.requestOrder);
  });

  test('does not request permissions that are already granted', () async {
    final gateway = _FakeAndroidRuntimePermissionGateway(
      initialStatus: AndroidRuntimePermissionStatus.granted,
    );
    final coordinator = AndroidRuntimePermissionCoordinator(
      gateway: gateway,
      isAndroid: true,
    );

    final permanentlyDenied = await coordinator.checkAndRequestMissing();

    expect(permanentlyDenied, isEmpty);
    expect(
      gateway.statusChecks,
      AndroidRuntimePermissionCoordinator.requestOrder,
    );
    expect(gateway.requests, isEmpty);
  });

  test('returns permissions that must be enabled from app settings', () async {
    final gateway = _FakeAndroidRuntimePermissionGateway(
      statusOverrides: const {
        AndroidRuntimePermission.callPhone:
            AndroidRuntimePermissionStatus.permanentlyDenied,
      },
      requestOverrides: const {
        AndroidRuntimePermission.camera:
            AndroidRuntimePermissionStatus.permanentlyDenied,
      },
    );
    final coordinator = AndroidRuntimePermissionCoordinator(
      gateway: gateway,
      isAndroid: true,
    );

    final permanentlyDenied = await coordinator.checkAndRequestMissing();

    expect(permanentlyDenied, {
      AndroidRuntimePermission.callPhone,
      AndroidRuntimePermission.camera,
    });
    expect(
      gateway.requests,
      AndroidRuntimePermissionCoordinator.requestOrder.skip(1),
    );
  });

  test('does not treat a normal denial as a settings-only denial', () async {
    final gateway = _FakeAndroidRuntimePermissionGateway(
      requestOverrides: const {
        AndroidRuntimePermission.microphone:
            AndroidRuntimePermissionStatus.denied,
      },
    );
    final coordinator = AndroidRuntimePermissionCoordinator(
      gateway: gateway,
      isAndroid: true,
    );

    final permanentlyDenied = await coordinator.checkAndRequestMissing();

    expect(permanentlyDenied, isEmpty);
    expect(gateway.requests, AndroidRuntimePermissionCoordinator.requestOrder);
  });

  test(
    'ignores overlapping resume checks while a permission prompt is open',
    () async {
      final requestGate = Completer<AndroidRuntimePermissionStatus>();
      final gateway = _FakeAndroidRuntimePermissionGateway(
        requestHandler: (permission) =>
            permission == AndroidRuntimePermission.callPhone
            ? requestGate.future
            : Future.value(AndroidRuntimePermissionStatus.granted),
      );
      final coordinator = AndroidRuntimePermissionCoordinator(
        gateway: gateway,
        isAndroid: true,
      );

      final firstCheck = coordinator.checkAndRequestMissing();
      await Future<void>.delayed(Duration.zero);
      final resumedCheck = coordinator.checkAndRequestMissing();
      await Future<void>.delayed(Duration.zero);

      expect(gateway.requests, [AndroidRuntimePermission.callPhone]);

      requestGate.complete(AndroidRuntimePermissionStatus.granted);
      await Future.wait([firstCheck, resumedCheck]);

      expect(
        gateway.requests,
        AndroidRuntimePermissionCoordinator.requestOrder,
      );
    },
  );

  test('does not request Android permissions on another platform', () async {
    final gateway = _FakeAndroidRuntimePermissionGateway();
    final coordinator = AndroidRuntimePermissionCoordinator(
      gateway: gateway,
      isAndroid: false,
    );

    final permanentlyDenied = await coordinator.checkAndRequestMissing();

    expect(permanentlyDenied, isEmpty);
    expect(gateway.statusChecks, isEmpty);
    expect(gateway.requests, isEmpty);
  });
}

class _FakeAndroidRuntimePermissionGateway
    implements AndroidRuntimePermissionGateway {
  _FakeAndroidRuntimePermissionGateway({
    this.initialStatus = AndroidRuntimePermissionStatus.denied,
    this.statusOverrides = const {},
    this.requestOverrides = const {},
    this.requestHandler,
  });

  final AndroidRuntimePermissionStatus initialStatus;
  final Map<AndroidRuntimePermission, AndroidRuntimePermissionStatus>
  statusOverrides;
  final Map<AndroidRuntimePermission, AndroidRuntimePermissionStatus>
  requestOverrides;
  final Future<AndroidRuntimePermissionStatus> Function(
    AndroidRuntimePermission permission,
  )?
  requestHandler;

  final statusChecks = <AndroidRuntimePermission>[];
  final requests = <AndroidRuntimePermission>[];
  final _currentStatuses =
      <AndroidRuntimePermission, AndroidRuntimePermissionStatus>{};

  @override
  Future<AndroidRuntimePermissionStatus> status(
    AndroidRuntimePermission permission,
  ) async {
    statusChecks.add(permission);
    return _currentStatuses[permission] ??
        statusOverrides[permission] ??
        initialStatus;
  }

  @override
  Future<AndroidRuntimePermissionStatus> request(
    AndroidRuntimePermission permission,
  ) async {
    requests.add(permission);
    final next =
        await (requestHandler?.call(permission) ??
            Future.value(
              requestOverrides[permission] ??
                  AndroidRuntimePermissionStatus.granted,
            ));
    _currentStatuses[permission] = next;
    return next;
  }

  @override
  Future<bool> openAppSettings() async => true;
}
