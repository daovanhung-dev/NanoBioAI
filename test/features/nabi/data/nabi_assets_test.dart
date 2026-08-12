import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/features/nabi/nabi.dart';

void main() {
  group('NabiAssets', () {
    test('contains specs for required animation types', () {
      const expectedStaticRoot =
          bool.fromEnvironment('NABI_V2_ASSETS_ENABLED', defaultValue: true)
          ? 'assets/images/nabi_v2'
          : 'assets/images/nabi';
      const expectedSpriteRoot =
          bool.fromEnvironment('NABI_V2_ASSETS_ENABLED', defaultValue: true)
          ? 'assets/nabi_v2'
          : 'assets/nabi';
      for (final type in NabiAnimationType.values) {
        final spec = NabiAssets.specFor(type);

        expect(spec.type, type);
        expect(spec.fps, 30);
        expect(spec.frameCount, 30);
        expect(spec.framesDirectory, startsWith('$expectedSpriteRoot/'));
        expect(spec.staticFallbackAsset, startsWith('$expectedStaticRoot/'));
      }
    });

    test('selects matching static and sprite roots at compile time', () {
      const expectedV2 = bool.fromEnvironment(
        'NABI_V2_ASSETS_ENABLED',
        defaultValue: true,
      );

      expect(NabiAssetCatalog.v2AssetsEnabled, expectedV2);
      expect(
        NabiAssetCatalog.staticAssetPath('core/nabi_idle_happy.png'),
        '${NabiAssetCatalog.staticRoot}/core/nabi_idle_happy.png',
      );
      expect(
        NabiAssetCatalog.spriteAssetPath('01_character/frame.png'),
        '${NabiAssetCatalog.spriteRoot}/01_character/frame.png',
      );
      expect(NabiAssets.root, NabiAssetCatalog.spriteRoot);
      expect(NabiAssets.staticRoot, NabiAssetCatalog.staticRoot);
    });

    test('builds the selected bundle frame paths from 0001 through 0030', () {
      const v2AssetsEnabled = bool.fromEnvironment(
        'NABI_V2_ASSETS_ENABLED',
        defaultValue: true,
      );
      const spec = NabiAssets.idle;

      if (v2AssetsEnabled) {
        expect(
          spec.framePath(1),
          'assets/nabi_v2/01_character/02_30fps_frames/01_core/'
          'nabi_anim_001_happy_idle_breathing/frame_0001.png',
        );
        expect(spec.framePath(30), endsWith('/frame_0030.png'));
      } else {
        expect(
          spec.framePath(1),
          'assets/nabi/01_character/02_30fps_frames/01_core/'
          'NABI_ANIM_001_happy_idle_breathing/'
          'NABI_ANIM_001_happy_idle_breathing_F0001.png',
        );
        expect(
          spec.framePath(30),
          endsWith('NABI_ANIM_001_happy_idle_breathing_F0030.png'),
        );
      }

      expect(spec.framePath(0), spec.framePath(1));
      expect(spec.framePath(31), spec.framePath(30));
    });

    test(
      'resolves every animation spec to the selected physical frame layout',
      () {
        const v2AssetsEnabled = bool.fromEnvironment(
          'NABI_V2_ASSETS_ENABLED',
          defaultValue: true,
        );

        for (final type in NabiAnimationType.values) {
          final spec = NabiAssets.specFor(type);
          final expectedPath = v2AssetsEnabled
              ? 'assets/nabi_v2/01_character/02_30fps_frames/'
                    '${spec.module.toLowerCase()}/${spec.id.toLowerCase()}/'
                    'frame_0001.png'
              : 'assets/nabi/01_character/02_30fps_frames/'
                    '${spec.module}/${spec.id}/${spec.id}_F0001.png';

          expect(spec.firstFramePath, expectedPath);
        }
      },
    );
  });
}
