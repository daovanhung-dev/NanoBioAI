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
}
