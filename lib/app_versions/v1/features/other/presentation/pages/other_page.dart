import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/dashboard_dynamic_provider.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/dashboard_provider.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../domain/entities/health_insights_entity.dart';
import '../../providers/health_insights_provider.dart';

part '../widgets/health_insights_widgets.dart';

class HealthInsightsView extends ConsumerWidget {
  const HealthInsightsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(healthInsightsProvider);

    return MedicalPageScaffold(
      backgroundColor: context.semanticColors.background,
      body: SafeArea(
        child: insightsAsync.when(
          loading: () => const _HealthInsightsLoadingState(),
          error: (_, __) => _HealthInsightsErrorState(
            onRetry: () => _retryHealthInsights(ref),
          ),
          data: (insights) {
            return RefreshIndicator(
              onRefresh: () => _refreshHealthInsights(ref),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: _HealthInsightsContentShell(
                      child: _HealthInsightsContent(
                        insights: insights,
                        onRefresh: () => _refreshHealthInsights(ref),
                        onRangeChanged: (range) {
                          ref
                              .read(healthInsightsRangeProvider.notifier)
                              .setRange(range);
                        },
                        onOpenTarget: (target) =>
                            _openHealthInsightsTarget(context, target),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

Future<void> _refreshHealthInsights(WidgetRef ref) async {
  ref.invalidate(dashboardProvider);
  ref.invalidate(dashboardDynamicProvider);
  ref.invalidate(healthInsightsProvider);
  try {
    await ref.read(healthInsightsProvider.future);
  } catch (_) {
    // The provider owns the visible safe error state.
  }
}

void _retryHealthInsights(WidgetRef ref) {
  ref.invalidate(dashboardProvider);
  ref.invalidate(dashboardDynamicProvider);
  ref.invalidate(healthInsightsProvider);
}

void _openHealthInsightsTarget(
  BuildContext context,
  HealthActionTarget target,
) {
  final path = switch (target) {
    HealthActionTarget.healthTracking => V1RoutePaths.healthTracking,
    HealthActionTarget.weeklySummary => V1RoutePaths.weeklySummary,
    HealthActionTarget.bodyMetrics => V1RoutePaths.bodyMetrics,
    HealthActionTarget.waterTracking => V1RoutePaths.waterTracking,
    HealthActionTarget.sleepTracking => V1RoutePaths.sleepTracking,
    HealthActionTarget.stressTracking => V1RoutePaths.stressTracking,
    HealthActionTarget.mealPlan => V1RoutePaths.mealPlan,
    HealthActionTarget.lifestyleSchedule => V1RoutePaths.lifestyleSchedule,
    HealthActionTarget.none => null,
  };

  if (path == null) return;
  context.push(path);
}
