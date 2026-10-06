import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

abstract interface class SleepSafetyPhoneGateway {
  bool get supportsDirectCalling;

  Future<bool> ensureDirectCallPermission();

  Future<bool> startCall(String phoneE164, {String? eventId});

  Future<bool> openDialer(String phoneE164, {String? eventId});
}

class UrlLauncherSleepSafetyPhoneGateway implements SleepSafetyPhoneGateway {
  const UrlLauncherSleepSafetyPhoneGateway();

  static const _control = MethodChannel(
    'com.nanobioai.app/sleep_safety/control',
  );

  @override
  bool get supportsDirectCalling =>
      defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> ensureDirectCallPermission() async {
    if (!supportsDirectCalling) return false;
    final status = await Permission.phone.status;
    if (status.isGranted) return true;
    return (await Permission.phone.request()).isGranted;
  }

  @override
  Future<bool> startCall(String phoneE164, {String? eventId}) async {
    if (!supportsDirectCalling ||
        !RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(phoneE164)) {
      return false;
    }
    try {
      return await _control.invokeMethod<bool>('callPhone', {
            'phoneE164': phoneE164,
            if (eventId != null) 'eventId': eventId,
          }) ??
          false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> openDialer(String phoneE164, {String? eventId}) async {
    if (!RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(phoneE164)) return false;
    try {
      return await _control.invokeMethod<bool>('openDialer', {
            'phoneE164': phoneE164,
            if (eventId != null) 'eventId': eventId,
          }) ??
          false;
    } on PlatformException {
      return false;
    }
  }
}
