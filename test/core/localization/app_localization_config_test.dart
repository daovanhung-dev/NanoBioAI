import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/localization/app_localization_config.dart';
import 'package:nano_app/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'forces Vietnamese Material labels even when the host locale is English',
    (tester) async {
      tester.binding.platformDispatcher.localeTestValue = const Locale(
        'en',
        'US',
      );
      addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);

      late Locale locale;
      late String title;
      late String cancelLabel;
      late String backTooltip;

      await tester.pumpWidget(
        MaterialApp(
          locale: AppLocalizationConfig.locale,
          supportedLocales: AppLocalizationConfig.supportedLocales,
          localizationsDelegates: AppLocalizationConfig.localizationsDelegates,
          home: Builder(
            builder: (context) {
              locale = Localizations.localeOf(context);
              title = AppLocalizations.of(context).appTitle;
              final material = MaterialLocalizations.of(context);
              cancelLabel = material.cancelButtonLabel;
              backTooltip = material.backButtonTooltip;
              return const Scaffold(body: Text('Nội dung tiếng Việt'));
            },
          ),
        ),
      );

      expect(locale, const Locale('vi', 'VN'));
      expect(title, 'NanoBio');
      expect(
        cancelLabel.toLowerCase(),
        anyOf(contains('hủy'), contains('huỷ')),
      );
      expect(backTooltip.toLowerCase(), contains('quay lại'));
    },
  );

  test('all production app roots use the shared Vietnamese config', () {
    const roots = <String>[
      'lib/app_versions/v1/app/bio_ai_v1_app.dart',
      'lib/app_versions/v2/app/bio_ai_v2_app.dart',
      'lib/app_versions/v3/app/bio_ai_v3_app.dart',
      'lib/app_versions/admin/app/bio_ai_admin_app.dart',
    ];

    for (final path in roots) {
      final source = File(path).readAsStringSync();
      expect(
        source,
        contains('locale: AppLocalizationConfig.locale'),
        reason: '$path must force vi_VN',
      );
      expect(
        source,
        contains(
          'localizationsDelegates: AppLocalizationConfig.localizationsDelegates',
        ),
        reason: '$path must install Vietnamese framework delegates',
      );
      expect(
        source,
        contains('supportedLocales: AppLocalizationConfig.supportedLocales'),
        reason: '$path must advertise only supported Vietnamese locales',
      );
    }
  });
}
