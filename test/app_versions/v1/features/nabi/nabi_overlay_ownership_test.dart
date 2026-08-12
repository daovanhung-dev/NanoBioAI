import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/features/nabi/nabi.dart';

void main() {
  test('main navigation owns exactly one Nabi overlay for its dashboard', () {
    final navigation = File(
      'lib/app_versions/v1/features/dashboard/presentation/pages/menu_page.dart',
    ).readAsStringSync();
    final dashboard = File(
      'lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart',
    ).readAsStringSync();

    expect(
      navigation,
      contains('DashboardPage(showStandaloneChatButton: false)'),
    );
    expect('NabiFloatingOverlay('.allMatches(navigation).length, 1);
    expect(dashboard, contains('if (widget.showStandaloneChatButton)'));
  });

  test('AI Voice reaches the selected shared Nabi asset bundle', () {
    final voicePage = File(
      'lib/app_versions/v1/features/ai_voice/presentation/pages/ai_voice_page.dart',
    ).readAsStringSync();

    expect(voicePage, contains('NabiAnimationPlayer('));
    expect(voicePage, isNot(contains("assets/nabi/")));
    expect(
      NabiAssets.specFor(NabiAnimationType.listening).firstFramePath,
      startsWith('${NabiAssetCatalog.spriteRoot}/'),
    );
  });
}
