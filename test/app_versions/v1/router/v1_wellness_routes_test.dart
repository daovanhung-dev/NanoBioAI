import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/features/daily_health_tracking/presentation/pages/daily_health_tracking_page.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart';
import 'package:nano_app/app_versions/v1/features/gentle_care_mode/presentation/pages/gentle_care_mode_page.dart';
import 'package:nano_app/app_versions/v1/features/personal_goals/presentation/pages/personal_goals_page.dart';
import 'package:nano_app/app_versions/v1/features/quick_care/presentation/pages/quick_care_page.dart';
import 'package:nano_app/app_versions/v1/features/water_tracking/presentation/pages/water_tracking_page.dart';
import 'package:nano_app/app_versions/v1/features/weekly_summary/presentation/pages/weekly_summary_page.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/app_versions/v1/router/v1_router.dart';

void main() {
  group('V1 wellness routes', () {
    final expectedPages = <String, Type>{
      V1RoutePaths.waterTracking: WaterTrackingPage,
      V1RoutePaths.weeklySummary: WeeklySummaryPage,
      V1RoutePaths.personalGoals: PersonalGoalsPage,
      V1RoutePaths.quickCare: QuickCarePage,
      V1RoutePaths.gentleCare: GentleCareModePage,
      V1RoutePaths.namiCare: NamiCarePage,
    };

    for (final entry in expectedPages.entries) {
      testWidgets('${entry.key} opens ${entry.value}', (tester) async {
        final router = GoRouter(initialLocation: entry.key, routes: v1Routes);
        addTearDown(router.dispose);

        await tester.pumpWidget(
          ProviderScope(child: MaterialApp.router(routerConfig: router)),
        );
        await tester.pump();

        expect(find.byType(entry.value), findsOneWidget);
      });
    }

    testWidgets('/health-tracking keeps the approved alias page', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: V1RoutePaths.healthTracking,
        routes: v1Routes,
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pump();

      expect(find.byType(DailyHealthTrackingPage), findsOneWidget);
    });
  });
}
