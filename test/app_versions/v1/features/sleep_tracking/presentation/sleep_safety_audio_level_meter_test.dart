import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/presentation/widgets/sleep_safety_audio_level_meter.dart';

void main() {
  testWidgets('sound meter grows and falls only from supplied live level', (
    tester,
  ) async {
    Future<void> pumpLevel({
      required double signal,
      required double peak,
      bool hasSignal = true,
      bool stale = false,
      String phase = 'monitoring',
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: SleepSafetyAudioLevelMeter(
                signalLevel: signal,
                peakLevel: peak,
                baselineLevel: 0.18,
                relativeEnergy: signal * 8,
                phase: phase,
                sensitivity: 'Cân bằng',
                hasSignal: hasSignal,
                signalStale: stale,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpLevel(signal: 0.12, peak: 0.18);
    final lowWidth = tester
        .getSize(find.byKey(const Key('sleep-safety-live-level-fill')))
        .width;
    expect(find.text('Mic đang nghe'), findsOneWidget);

    await pumpLevel(signal: 0.86, peak: 0.96, phase: 'candidate');
    final highWidth = tester
        .getSize(find.byKey(const Key('sleep-safety-live-level-fill')))
        .width;
    expect(highWidth, greaterThan(lowWidth * 3));
    expect(find.textContaining('Phát hiện âm thanh lớn'), findsOneWidget);

    await pumpLevel(
      signal: 0,
      peak: 0,
      hasSignal: false,
      stale: true,
      phase: 'noSignal',
    );
    final noSignalWidth = tester
        .getSize(find.byKey(const Key('sleep-safety-live-level-fill')))
        .width;
    expect(noSignalWidth, 0);
    expect(find.text('Không nhận được tín hiệu micro'), findsOneWidget);
  });
}
