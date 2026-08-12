import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/nabi_onboarding_experience.dart';
import 'package:nano_app/features/nabi/nabi.dart';

void main() {
  test('every onboarding mood resolves through the selected Nabi catalog', () {
    for (final mood in NabiOnboardingMood.values) {
      expect(mood.assetPath, startsWith('${NabiAssetCatalog.staticRoot}/'));
      expect(mood.assetPath, mood.assetPath.toLowerCase());
      expect(mood.assetPath, endsWith('.png'));
    }
  });
}
