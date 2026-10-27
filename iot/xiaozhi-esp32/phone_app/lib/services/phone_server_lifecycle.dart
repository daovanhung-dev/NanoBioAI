import 'package:flutter/services.dart';

class PhoneServerLifecycle {
  static const MethodChannel _serviceChannel = MethodChannel(
    'xiaozhi.local_ai/server_service',
  );
  static const MethodChannel _permissionChannel = MethodChannel(
    'xiaozhi.local_ai/server_permissions',
  );
  static Future<void> Function()? _stopFromNotification;

  static void initialize({required Future<void> Function() onStopRequested}) {
    _stopFromNotification = onStopRequested;
    _serviceChannel.setMethodCallHandler((call) async {
      if (call.method == 'stopServerFromNotification') {
        await _stopFromNotification?.call();
      }
    });
  }

  static Future<bool> requestServerPermissions() async =>
      await _permissionChannel.invokeMethod<bool>('requestServerPermissions') ??
      false;

  static Future<void> startForegroundService() =>
      _serviceChannel.invokeMethod<void>('startForegroundService');

  static Future<void> stopForegroundService() =>
      _serviceChannel.invokeMethod<void>('stopForegroundService');

  static Future<void> updateForegroundService(String title, String body) =>
      _serviceChannel.invokeMethod<void>('updateForegroundService', {
        'title': title,
        'body': body,
      });
}
