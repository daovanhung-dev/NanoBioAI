import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/admin/app/bio_ai_admin_app.dart';
import 'package:nano_app/app_versions/v2/app/bio_ai_v2_app.dart';

Future<void> pumpV2Harness(
  WidgetTester tester, {
  List<Override> overrides = const <Override>[],
}) async {
  await tester.pumpWidget(
    ProviderScope(overrides: overrides, child: const BioAIV2App()),
  );
  await pumpBootFrames(tester);
}

Future<void> pumpAdminHarness(
  WidgetTester tester, {
  List<Override> overrides = const <Override>[],
}) async {
  await tester.pumpWidget(
    ProviderScope(overrides: overrides, child: const BioAIAdminApp()),
  );
  await pumpBootFrames(tester);
}

Future<void> pumpBootFrames(WidgetTester tester) async {
  for (var index = 0; index < 4; index++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}
