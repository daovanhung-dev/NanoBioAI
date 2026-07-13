import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('medical design system is wired into every app surface', () {
    const appFiles = [
      'lib/app_versions/v1/app/bio_ai_v1_app.dart',
      'lib/app_versions/v2/app/bio_ai_v2_app.dart',
      'lib/app_versions/v3/app/bio_ai_v3_app.dart',
      'lib/app_versions/admin/app/bio_ai_admin_app.dart',
    ];

    for (final path in appFiles) {
      final source = File(path).readAsStringSync();
      expect(
        source,
        contains('builder: AppExperience.builder'),
        reason: '$path must use the shared application experience wrapper.',
      );
    }
  });

  test('theme exposes the healthcare shell and Material 3 component system', () {
    final themeBarrel = File('lib/core/theme/theme.dart').readAsStringSync();
    final appTheme = File('lib/core/theme/app_theme.dart').readAsStringSync();
    final medicalUi = File('lib/core/theme/medical_ui.dart').readAsStringSync();

    expect(themeBarrel, contains("export 'app_experience.dart';"));
    expect(themeBarrel, contains("export 'medical_ui.dart';"));
    expect(appTheme, contains('useMaterial3: true'));
    expect(appTheme, contains('navigationBarTheme:'));
    expect(appTheme, contains('inputDecorationTheme:'));
    expect(appTheme, contains('datePickerTheme:'));
    expect(medicalUi, contains('class MedicalPageScaffold'));
    expect(medicalUi, contains('class MedicalPageHero'));
    expect(medicalUi, contains('class MedicalSurfaceCard'));
    expect(medicalUi, contains('class MedicalEmptyState'));
  });

  test('application pages use the medical shell instead of raw Scaffold', () {
    final rawScaffoldFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) {
          final normalized = file.path.replaceAll('\\', '/');
          return !normalized.endsWith('/core/theme/medical_ui.dart') &&
              !normalized.endsWith('/core/theme/design_system_demo_page.dart');
        })
        .where((file) => RegExp(r'\bScaffold\s*\(')
            .hasMatch(file.readAsStringSync()))
        .map((file) => file.path)
        .toList();

    expect(
      rawScaffoldFiles,
      isEmpty,
      reason: 'Feature pages should use MedicalPageScaffold consistently.',
    );
  });
}
