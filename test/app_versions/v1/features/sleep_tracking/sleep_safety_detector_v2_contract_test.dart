import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android detector v2 has one decision layer and live metrics', () {
    final detector = File(
      'android/app/src/main/kotlin/com/example/nano_app/sleep_safety/SleepSafetyDetector.kt',
    ).readAsStringSync();
    final service = File(
      'android/app/src/main/kotlin/com/example/nano_app/sleep_safety/SleepSafetyForegroundService.kt',
    ).readAsStringSync();
    final channel = File(
      'android/app/src/main/kotlin/com/example/nano_app/sleep_safety/SleepSafetyChannelHandler.kt',
    ).readAsStringSync();

    expect(detector, contains('calibrationSafetyBypass'));
    expect(detector, contains('robustNoiseFloor'));
    expect(detector, contains('AudioMetrics'));
    expect(detector, contains('sustainedHighEnergyFrames'));
    expect(detector, contains('amplitudeToLevel'));
    expect(service, contains('"audioMetrics"'));
    expect(service, contains('output.confirmedEvent?.let(::beginAlert)'));
    expect(service, isNot(contains('confidenceFloor')));
    expect(service, isNot(contains('energyFloor')));
    expect(channel, contains('mainHandler.post { sink?.success(event) }'));
  });

  test('iOS detector mirrors calibration bypass and live metrics', () {
    final appDelegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();

    expect(appDelegate, contains('calibrationSafetyBypass'));
    expect(appDelegate, contains('robustNoiseFloor'));
    expect(appDelegate, contains('"audioMetrics"'));
    expect(appDelegate, contains('let output = detector?.process(buffer: buffer)'));
    expect(appDelegate, isNot(contains('confidenceFloor')));
    expect(appDelegate, isNot(contains('energyFloor')));
  });
}
