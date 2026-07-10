import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/features/nabi/nabi.dart';

void main() {
  group('NabiAssets', () {
    test('contains specs for required animation types', () {
      const requiredTypes = [
        NabiAnimationType.idle,
        NabiAnimationType.happy,
        NabiAnimationType.sad,
        NabiAnimationType.angry,
        NabiAnimationType.sulk,
        NabiAnimationType.crying,
        NabiAnimationType.listening,
        NabiAnimationType.talking,
        NabiAnimationType.thinking,
        NabiAnimationType.greeting,
        NabiAnimationType.loading,
        NabiAnimationType.error,
      ];

      for (final type in requiredTypes) {
        final spec = NabiAssets.specFor(type);

        expect(spec.type, type);
        expect(spec.fps, 30);
        expect(spec.frameCount, 30);
        expect(spec.framesDirectory, contains('assets/nabi'));
        expect(spec.staticFallbackAsset, startsWith('assets/nabi/'));
      }
    });

    test('builds 30fps frame paths from F0001 through F0030', () {
      const spec = NabiAssets.idle;

      expect(
        spec.framePath(1),
        endsWith('NABI_ANIM_001_happy_idle_breathing_F0001.png'),
      );
      expect(
        spec.framePath(30),
        endsWith('NABI_ANIM_001_happy_idle_breathing_F0030.png'),
      );
      expect(spec.framePath(0), spec.framePath(1));
      expect(spec.framePath(31), spec.framePath(30));
    });
  });
}
