import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;

enum AndroidRuntimePermission { callPhone, microphone, notifications, camera }

enum AndroidRuntimePermissionStatus { granted, denied, permanentlyDenied }

abstract interface class AndroidRuntimePermissionGateway {
  Future<AndroidRuntimePermissionStatus> status(
    AndroidRuntimePermission permission,
  );

  Future<AndroidRuntimePermissionStatus> request(
    AndroidRuntimePermission permission,
  );

  Future<bool> openAppSettings();
}

class PermissionHandlerAndroidRuntimePermissionGateway
    implements AndroidRuntimePermissionGateway {
  const PermissionHandlerAndroidRuntimePermissionGateway();

  permission_handler.Permission _permissionFor(
    AndroidRuntimePermission permission,
  ) => switch (permission) {
    AndroidRuntimePermission.callPhone => permission_handler.Permission.phone,
    AndroidRuntimePermission.microphone =>
      permission_handler.Permission.microphone,
    AndroidRuntimePermission.notifications =>
      permission_handler.Permission.notification,
    AndroidRuntimePermission.camera => permission_handler.Permission.camera,
  };

  AndroidRuntimePermissionStatus _statusFor(
    permission_handler.PermissionStatus status,
  ) {
    if (status.isGranted || status.isLimited || status.isProvisional) {
      return AndroidRuntimePermissionStatus.granted;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return AndroidRuntimePermissionStatus.permanentlyDenied;
    }
    return AndroidRuntimePermissionStatus.denied;
  }

  @override
  Future<AndroidRuntimePermissionStatus> status(
    AndroidRuntimePermission permission,
  ) async => _statusFor(await _permissionFor(permission).status);

  @override
  Future<AndroidRuntimePermissionStatus> request(
    AndroidRuntimePermission permission,
  ) async => _statusFor(await _permissionFor(permission).request());

  @override
  Future<bool> openAppSettings() => permission_handler.openAppSettings();
}

class AndroidRuntimePermissionCoordinator {
  AndroidRuntimePermissionCoordinator({
    required AndroidRuntimePermissionGateway gateway,
    required bool isAndroid,
  }) : _gateway = gateway,
       _isAndroid = isAndroid;

  static const requestOrder = <AndroidRuntimePermission>[
    AndroidRuntimePermission.callPhone,
    AndroidRuntimePermission.microphone,
    AndroidRuntimePermission.notifications,
    AndroidRuntimePermission.camera,
  ];

  final AndroidRuntimePermissionGateway _gateway;
  final bool _isAndroid;
  Future<Set<AndroidRuntimePermission>>? _activeCheck;

  Future<Set<AndroidRuntimePermission>> checkAndRequestMissing() async {
    if (!_isAndroid) return const {};
    final activeCheck = _activeCheck;
    if (activeCheck != null) return activeCheck;

    final check = _checkAndRequestMissing();
    _activeCheck = check;
    try {
      return await check;
    } finally {
      if (identical(_activeCheck, check)) _activeCheck = null;
    }
  }

  Future<Set<AndroidRuntimePermission>> _checkAndRequestMissing() async {
    final permanentlyDenied = <AndroidRuntimePermission>{};
    for (final permission in requestOrder) {
      AndroidRuntimePermissionStatus current;
      try {
        current = await _gateway.status(permission);
      } catch (_) {
        continue;
      }
      if (current == AndroidRuntimePermissionStatus.granted) continue;
      if (current == AndroidRuntimePermissionStatus.permanentlyDenied) {
        permanentlyDenied.add(permission);
        continue;
      }

      try {
        current = await _gateway.request(permission);
      } catch (_) {
        continue;
      }
      if (current == AndroidRuntimePermissionStatus.permanentlyDenied) {
        permanentlyDenied.add(permission);
      }
    }
    return Set.unmodifiable(permanentlyDenied);
  }

  Future<bool> openAppSettings() => _gateway.openAppSettings();
}

final androidRuntimePermissionGatewayProvider =
    Provider<AndroidRuntimePermissionGateway>(
      (ref) => const PermissionHandlerAndroidRuntimePermissionGateway(),
    );

final androidRuntimePermissionCoordinatorProvider =
    Provider<AndroidRuntimePermissionCoordinator>(
      (ref) => AndroidRuntimePermissionCoordinator(
        gateway: ref.watch(androidRuntimePermissionGatewayProvider),
        isAndroid: defaultTargetPlatform == TargetPlatform.android,
      ),
    );
