import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/features/nabi/nabi.dart';

void main() {
  testWidgets('NabiAnimationPlayer falls back when sprite asset is missing', (
    tester,
  ) async {
    const missingSpec = NabiAnimationSpec(
      type: NabiAnimationType.idle,
      id: 'missing_animation',
      module: 'missing_module',
      staticFallbackAsset: 'assets/missing/nabi_static.png',
      root: 'assets/missing',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NabiAnimationPlayer(
            spec: missingSpec,
            fallbackIcon: Icon(Icons.auto_awesome_rounded),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion holds the selected bundle on its first frame', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: NabiAnimationPlayer(animationType: NabiAnimationType.idle),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1200));

    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image as AssetImage;
    expect(provider.assetName, NabiAssets.idle.firstFramePath);
    expect(tester.takeException(), isNull);
  });
}
