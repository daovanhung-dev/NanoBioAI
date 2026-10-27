import 'package:flutter/services.dart';

class NabiEspHotspotCredentials {
  const NabiEspHotspotCredentials({required this.ssid, required this.password});

  final String ssid;
  final String password;
}

/// Narrow Android-only bridge for the app-owned local hotspot and notification.
class NabiEspAndroidBridge {
  NabiEspAndroidBridge._();

  static const MethodChannel _channel = MethodChannel(
    'com.nanobioai.app/nabi_esp',
  );
  static Future<void> Function()? _stopRequested;
  static Future<void> Function()? _hotspotStopped;
  static bool _initialized = false;

  static void initialize({
    required Future<void> Function() onStopRequested,
    required Future<void> Function() onHotspotStopped,
  }) {
    _stopRequested = onStopRequested;
    _hotspotStopped = onHotspotStopped;
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'stopFromNotification') {
        await _stopRequested?.call();
      } else if (call.method == 'hotspotStopped') {
        await _hotspotStopped?.call();
      }
    });
  }

  static Future<void> startForegroundService() =>
      _channel.invokeMethod<void>('startForegroundService');

  static Future<void> updateForegroundNotification({
    required String title,
    required String message,
  }) => _channel.invokeMethod<void>('updateForegroundNotification', {
    'title': title,
    'message': message,
  });

  static Future<void> stopForegroundService() =>
      _channel.invokeMethod<void>('stopForegroundService');

  static Future<int> androidSdkInt() async =>
      await _channel.invokeMethod<int>('androidSdkInt') ?? 30;

  static Future<NabiEspHotspotCredentials> startLocalOnlyHotspot() async {
    final result = await _channel.invokeMapMethod<String, String>(
      'startLocalOnlyHotspot',
    );
    final ssid = result?['ssid']?.trim();
    final password = result?['password']?.trim();
    if (ssid == null || ssid.isEmpty || password == null || password.isEmpty) {
      throw PlatformException(
        code: 'hotspot_credentials_missing',
        message: 'Android không trả thông tin hotspot.',
      );
    }
    return NabiEspHotspotCredentials(ssid: ssid, password: password);
  }

  static Future<void> stopLocalOnlyHotspot() =>
      _channel.invokeMethod<void>('stopLocalOnlyHotspot');

  static Future<Map<String, Object?>> provisionEsp({
    required String ssid,
    required String password,
    String? pairingCode,
  }) async {
    final result = await _channel
        .invokeMapMethod<String, Object?>('provisionEsp', {
          'ssid': ssid,
          'password': password,
          if (pairingCode != null) 'pairingCode': pairingCode,
        });
    if (result == null) {
      throw PlatformException(code: 'ble_provision_failed');
    }
    return result;
  }
}
