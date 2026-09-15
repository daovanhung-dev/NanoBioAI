import 'dart:async';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class SleepSafetyNativeEvent {
  const SleepSafetyNativeEvent({required this.type, required this.data});

  final String type;
  final Map<String, Object?> data;

  factory SleepSafetyNativeEvent.fromDynamic(Object? raw) {
    if (raw is! Map) {
      return const SleepSafetyNativeEvent(type: 'nativeFailure', data: {});
    }
    final map = Map<String, Object?>.from(raw);
    return SleepSafetyNativeEvent(
      type: map['type']?.toString() ?? 'nativeFailure',
      data: map,
    );
  }
}

class SleepSafetyNativeStartException implements Exception {
  const SleepSafetyNativeStartException(this.code);

  final String code;

  @override
  String toString() => 'SleepSafetyNativeStartException($code)';
}

abstract class SleepSafetyNativeGateway {
  Stream<SleepSafetyNativeEvent> get events;
  Future<bool> ensureMicrophonePermission();
  Future<void> startMonitoring(Map<String, Object?> config);
  Future<void> stopMonitoring(String reason);
  Future<void> startCalibration();
  Future<void> updateRuntimeConfig(Map<String, Object?> config);
  Future<void> respondToAlert({
    required String eventId,
    required String response,
  });
  Future<void> dismissAlert({required String eventId});
  Future<Map<String, Object?>> getMonitoringStatus();
}

class MethodChannelSleepSafetyNativeGateway
    implements SleepSafetyNativeGateway {
  const MethodChannelSleepSafetyNativeGateway();

  static const _control = MethodChannel(
    'com.nanobioai.app/sleep_safety/control',
  );
  static const _events = EventChannel('com.nanobioai.app/sleep_safety/events');

  @override
  Stream<SleepSafetyNativeEvent> get events => _events
      .receiveBroadcastStream()
      .map(SleepSafetyNativeEvent.fromDynamic)
      .asBroadcastStream();

  @override
  Future<bool> ensureMicrophonePermission() async {
    final current = await Permission.microphone.status;
    if (current.isGranted) return true;
    return (await Permission.microphone.request()).isGranted;
  }

  @override
  Future<void> startMonitoring(Map<String, Object?> config) async {
    try {
      await _control.invokeMethod<void>('startMonitoring', config);
    } on PlatformException catch (error) {
      throw SleepSafetyNativeStartException(error.code);
    }
  }

  @override
  Future<void> stopMonitoring(String reason) {
    return _control.invokeMethod<void>('stopMonitoring', {'reason': reason});
  }

  @override
  Future<void> startCalibration() {
    return _control.invokeMethod<void>('startCalibration');
  }

  @override
  Future<void> updateRuntimeConfig(Map<String, Object?> config) {
    return _control.invokeMethod<void>('updateRuntimeConfig', config);
  }

  @override
  Future<void> respondToAlert({
    required String eventId,
    required String response,
  }) {
    return _control.invokeMethod<void>('respondToAlert', {
      'eventId': eventId,
      'response': response,
    });
  }

  @override
  Future<void> dismissAlert({required String eventId}) {
    return _control.invokeMethod<void>('dismissAlert', {'eventId': eventId});
  }

  @override
  Future<Map<String, Object?>> getMonitoringStatus() async {
    return (await _control.invokeMapMethod<String, Object?>(
          'getMonitoringStatus',
        )) ??
        const <String, Object?>{};
  }
}
