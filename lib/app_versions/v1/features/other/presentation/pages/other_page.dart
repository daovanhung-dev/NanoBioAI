import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_dynamic_entity.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/dashboard_dynamic_provider.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/dashboard_provider.dart';
import 'package:nano_app/core/theme/theme.dart';

part '../widgets/health_insights_widgets.dart';

class HealthInsightsView extends ConsumerWidget {
  const HealthInsightsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final dynamicAsync = ref.watch(dashboardDynamicProvider);

    return MedicalPageScaffold(
      backgroundColor: context.semanticColors.background,
      body: SafeArea(
        child: dashboardAsync.when(
          loading: () => const _HealthInsightsLoadingState(),
          error: (_, __) =>
              _HealthInsightsErrorState(onRetry: () => _retryAll(ref)),
          data: (dashboard) {
            final dynamicData =
                dynamicAsync.value ?? DashboardDynamicEntity.empty();
            final dynamicStatus = dynamicAsync.when<Widget?>(
              data: (_) => null,
              loading: () => const _HealthInsightsStatusStrip(
                icon: Icons.sync_rounded,
                message: 'Đang cập nhật chỉ số mới nhất…',
                showProgress: true,
              ),
              error: (_, __) => _HealthInsightsStatusStrip(
                icon: Icons.cloud_off_outlined,
                message: 'Một vài chỉ số chưa được cập nhật.',
                actionLabel: 'Thử lại',
                onAction: () => ref.invalidate(dashboardDynamicProvider),
              ),
            );

            return RefreshIndicator(
              onRefresh: () => _refreshAll(ref),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.compactPagePadding,
                      AppSpacing.compactPagePadding,
                      AppSpacing.compactPagePadding,
                      AppSpacing.xxxxl + MediaQuery.paddingOf(context).bottom,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _HealthInsightsHeader(dashboard: dashboard),
                        if (dynamicStatus != null) ...[
                          const SizedBox(
                            height: AppSpacing.compactSectionSpacing,
                          ),
                          dynamicStatus,
                        ],
                        const SizedBox(
                          height: AppSpacing.compactSectionSpacing,
                        ),
                        _HealthSnapshotCard(metrics: dynamicData.metrics),
                        const SizedBox(
                          height: AppSpacing.compactSectionSpacing,
                        ),
                        _TodayMetricStrip(metrics: dynamicData.metrics),
                        const SizedBox(
                          height: AppSpacing.compactSectionSpacing,
                        ),
                        _PrimaryInsightSection(insights: dynamicData.insights),
                        const SizedBox(
                          height: AppSpacing.compactSectionSpacing,
                        ),
                        _PrimaryRecommendationSection(
                          recommendations: dynamicData.recommendations,
                        ),
                        const SizedBox(
                          height: AppSpacing.compactSectionSpacing,
                        ),
                        _AdditionalHealthDetails(
                          dashboard: dashboard,
                          metrics: dynamicData.metrics,
                          insightCount: dynamicData.insights.length,
                          recommendationCount:
                              dynamicData.recommendations.length,
                        ),
                      ]),
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
