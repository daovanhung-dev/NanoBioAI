import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Sleep Safety belongs to the active FeatureHub grid', () {
    final source = File(
      'lib/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart',
    ).readAsStringSync();

    final currentStart = source.indexOf(
      'List<_FeatureAction> _currentFeatures',
    );
    final plannedStart = source.indexOf(
      'List<_FeatureAction> _plannedFeatures',
    );
    final plannedEnd = source.indexOf(
      '\n}\n\nclass _CareJourneyHero',
      plannedStart,
    );

    expect(currentStart, greaterThanOrEqualTo(0));
    expect(plannedStart, greaterThan(currentStart));
    expect(plannedEnd, greaterThan(plannedStart));

    final activeSection = source.substring(currentStart, plannedStart);
    final plannedSection = source.substring(plannedStart, plannedEnd);

    const healthId = "'health-tracking'";
    const sleepId = "'sleep-tracking'";
    const waterId = "'water-tracking'";

    expect(activeSection, contains("_FeatureAction('sleep-tracking'"));
    expect(activeSection, contains("'Giám sát giấc ngủ'"));
    expect(activeSection, contains('V1RoutePaths.sleepTracking'));
    expect(plannedSection, isNot(contains(sleepId)));

    final healthIndex = activeSection.indexOf(healthId);
    final sleepIndex = activeSection.indexOf(sleepId);
    final waterIndex = activeSection.indexOf(waterId);

    expect(healthIndex, greaterThanOrEqualTo(0));
    expect(sleepIndex, greaterThan(healthIndex));
    expect(waterIndex, greaterThan(sleepIndex));

    expect(plannedSection, contains("'stress-tracking'"));
    expect(plannedSection, contains("'community'"));
  });
}
