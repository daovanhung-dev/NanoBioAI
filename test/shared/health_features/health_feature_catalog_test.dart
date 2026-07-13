import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/shared/health_features/health_feature_catalog.dart';

void main() {
  group('advancedHealthFeatureCatalog', () {
    test('contains the ten unique M20-M29 module identifiers', () {
      final moduleIds = advancedHealthFeatureCatalog
          .map((item) => item.moduleId)
          .toList();

      expect(advancedHealthFeatureCatalog, hasLength(10));
      expect(moduleIds.toSet(), hasLength(10));
      expect(moduleIds, [
        'M20',
        'M21',
        'M22',
        'M23',
        'M24',
        'M25',
        'M26',
        'M27',
        'M28',
        'M29',
      ]);
    });

    test('maps three modules to Free and seven modules to Plus', () {
      final freeModuleIds = advancedHealthFeatureCatalog
          .where(
            (item) => item.minimumAccess == HealthFeatureMinimumAccess.free,
          )
          .map((item) => item.moduleId)
          .toList();
      final plusModuleIds = advancedHealthFeatureCatalog
          .where(
            (item) => item.minimumAccess == HealthFeatureMinimumAccess.plus,
          )
          .map((item) => item.moduleId)
          .toList();

      expect(freeModuleIds, ['M20', 'M21', 'M22']);
      expect(plusModuleIds, ['M23', 'M24', 'M25', 'M26', 'M27', 'M28', 'M29']);
    });

    test('provides complete copy and exactly three preview items', () {
      for (final item in advancedHealthFeatureCatalog) {
        expect(item.moduleCode.trim(), isNotEmpty, reason: item.moduleId);
        expect(item.title.trim(), isNotEmpty, reason: item.moduleId);
        expect(item.description.trim(), isNotEmpty, reason: item.moduleId);
        expect(
          item.comingSoonEyebrow.trim(),
          isNotEmpty,
          reason: item.moduleId,
        );
        expect(
          item.comingSoonMessage.trim(),
          isNotEmpty,
          reason: item.moduleId,
        );
        expect(item.previewItems, hasLength(3), reason: item.moduleId);
        expect(
          item.previewItems.every((preview) => preview.trim().isNotEmpty),
          isTrue,
          reason: item.moduleId,
        );
      }
    });

    test('mentions AI only for M24, M27 and M29', () {
      final modulesWithAiCopy = advancedHealthFeatureCatalog
          .where((item) {
            final copy = [
              item.title,
              item.description,
              item.comingSoonMessage,
              ...item.previewItems,
            ].join(' ').toLowerCase();
            return RegExp(r'(^|\s)ai(\s|$)').hasMatch(copy);
          })
          .map((item) => item.moduleId)
          .toList();

      expect(modulesWithAiCopy, ['M24', 'M27', 'M29']);
    });

    test('looks up normalized module IDs and fails closed for unknown IDs', () {
      expect(
        healthFeatureByModuleId(' m20 ')?.moduleCode,
        'BLOOD_PRESSURE_TRACKING',
      );
      expect(healthFeatureByModuleId('m29')?.moduleCode, 'AI_HEALTH_TRENDS');
      expect(healthFeatureByModuleId('M19'), isNull);
      expect(healthFeatureByModuleId('M20/extra'), isNull);
      expect(healthFeatureByModuleId(''), isNull);
    });
  });
}
