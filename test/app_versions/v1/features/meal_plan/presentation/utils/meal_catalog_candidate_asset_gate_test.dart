import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'unreviewed wellness catalog is bundled for explicit schedule use',
    () async {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final bundledAssets = manifest.listAssets().toSet();
      const candidatePath = 'assets/data/nabi_3000_mon_viet_moi.json';

      expect(File(candidatePath).existsSync(), isTrue);
      expect(bundledAssets, contains('assets/data/meal_catalog_v1.json'));
      expect(bundledAssets, contains(candidatePath));
      expect(
        File(
          'pubspec.yaml',
        ).readAsStringSync().split('\n').map((line) => line.trim()),
        contains('- $candidatePath'),
      );
    },
  );
}
