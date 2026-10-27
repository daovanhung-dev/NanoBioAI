import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/nabi_esp_assistant/data/services/nabi_esp_audio_frames.dart';

void main() {
  group('NabiEspAudioFrames', () {
    test('encodes and decodes a XiaoZhi v3 Opus packet', () {
      final packet = Uint8List.fromList([1, 2, 3, 4, 5]);

      final frame = NabiEspAudioFrames.encode(packet);

      expect(frame.sublist(0, 4), [0, 0, 0, 5]);
      expect(NabiEspAudioFrames.decode(frame), packet);
    });

    test('rejects invalid type, truncated header, and mismatched length', () {
      expect(
        () => NabiEspAudioFrames.decode(Uint8List(3)),
        throwsFormatException,
      );
      expect(
        () => NabiEspAudioFrames.decode(Uint8List.fromList([1, 0, 0, 1, 7])),
        throwsFormatException,
      );
      expect(
        () => NabiEspAudioFrames.decode(Uint8List.fromList([0, 0, 0, 2, 7])),
        throwsFormatException,
      );
      expect(
        () => NabiEspAudioFrames.encode(Uint8List(0)),
        throwsFormatException,
      );
    });
  });

  test('compares session tokens and resamples PCM bounds safely', () {
    expect(nabiEspTokensMatch('session-token', 'session-token'), isTrue);
    expect(nabiEspTokensMatch('session-token', 'session-tokenn'), isFalse);
    expect(nabiEspTokensMatch('short', 'longer'), isFalse);

    final input = Int16List.fromList([0, 1000, 2000, 3000]);
    final output = nabiEspResample(input, 4, 8);

    expect(output.length, 8);
    expect(output.first, 0);
    expect(output.last, 3000);
  });
}
