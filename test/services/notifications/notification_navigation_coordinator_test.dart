import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_navigation_coordinator.dart';

void main() {
  tearDown(NotificationNavigationCoordinator.resetForTest);

  test('opens the schedule route with the exact task deep link', () {
    final navigatedUris = <Uri>[];
    NotificationNavigationCoordinator.register(navigatedUris.add);

    NotificationNavigationCoordinator.openScheduleItem('  task / 01  ');

    expect(navigatedUris, hasLength(1));
    expect(navigatedUris.single.path, V1RoutePaths.lifestyleSchedule);
    expect(navigatedUris.single.queryParameters, {'item': 'task / 01'});
  });

  test('delivers a pending deep link once after the navigator registers', () {
    NotificationNavigationCoordinator.openScheduleItem('schedule-pending');
    final firstNavigatorUris = <Uri>[];
    final secondNavigatorUris = <Uri>[];

    NotificationNavigationCoordinator.register(firstNavigatorUris.add);
    NotificationNavigationCoordinator.register(secondNavigatorUris.add);

    expect(firstNavigatorUris, hasLength(1));
    expect(
      firstNavigatorUris.single.queryParameters['item'],
      'schedule-pending',
    );
    expect(secondNavigatorUris, isEmpty);
  });

  test('uses a schedule-only URI when the source identifier is blank', () {
    final navigatedUris = <Uri>[];
    NotificationNavigationCoordinator.register(navigatedUris.add);

    NotificationNavigationCoordinator.openScheduleItem('   ');

    expect(navigatedUris.single.path, V1RoutePaths.lifestyleSchedule);
    expect(navigatedUris.single.queryParameters, isEmpty);
  });

  test('stops navigating after the registered callback is removed', () {
    final navigatedUris = <Uri>[];
    void navigator(Uri uri) => navigatedUris.add(uri);
    NotificationNavigationCoordinator.register(navigator);
    NotificationNavigationCoordinator.unregister(navigator);

    NotificationNavigationCoordinator.openScheduleItem('schedule-later');

    expect(navigatedUris, isEmpty);
    final replacementUris = <Uri>[];
    NotificationNavigationCoordinator.register(replacementUris.add);
    expect(replacementUris.single.queryParameters['item'], 'schedule-later');
  });

  test('all user app roots register navigation and unified router exposes V3 routes', () {
    for (final path in const [
      'lib/app_versions/v1/app/bio_ai_v1_app.dart',
      'lib/app_versions/v2/app/bio_ai_v2_app.dart',
      'lib/app_versions/v3/app/bio_ai_v3_app.dart',
    ]) {
      expect(
        File(path).readAsStringSync(),
        contains('NotificationNavigationCoordinator.register'),
        reason: path,
      );
    }
    final unifiedRouter = File(
      'lib/app_versions/v2/router/v2_router.dart',
    ).readAsStringSync();
    expect(unifiedRouter, contains('...v3Routes'));
    expect(unifiedRouter, contains('V3RoutePaths.advancedTracking'));
  });
}
