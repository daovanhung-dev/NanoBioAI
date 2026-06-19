import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/features/dashboard/domain/entities/dashboard_dynamic_entity.dart';
import 'package:nano_app/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:nano_app/features/dashboard/providers/dashboard_dynamic_provider.dart';
import 'package:nano_app/features/dashboard/providers/dashboard_provider.dart';

class HealthInsightsView extends ConsumerWidget {
  const HealthInsightsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final dynamicAsync = ref.watch(dashboardDynamicProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: dashboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _StateMessage(
            icon: Icons.error_outline_rounded,
            title: 'Chưa có dữ liệu hồ sơ',
            message:
                'Nami chưa thể mở góc sức khỏe của bạn lúc này. Mình thử lại sau một chút nhé.',
            onRetry: () => ref.invalidate(dashboardProvider),
          ),
          data: (dashboard) {
            final dynamicData =
                dynamicAsync.value ?? DashboardDynamicEntity.empty();
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(dashboardProvider);
                ref.invalidate(dashboardDynamicProvider);
                await Future.wait<Object?>([
                  ref.read(dashboardProvider.future),
                  ref.read(dashboardDynamicProvider.future),
                ]);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pagePadding,
                      AppSpacing.pagePadding,
                      AppSpacing.pagePadding,
                      128,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _Header(dashboard: dashboard),
                        const SizedBox(height: AppSpacing.lg),
                        if (dynamicAsync.isLoading) const _SyncBanner(),
                        _SummaryCard(
                          dashboard: dashboard,
                          metrics: dynamicData.metrics,
                          insights: dynamicData.insights,
                          recommendations: dynamicData.recommendations,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _TodayOverview(metrics: dynamicData.metrics),
                        const SizedBox(height: AppSpacing.lg),
                        _HealthScoreCard(metrics: dynamicData.metrics),
                        const SizedBox(height: AppSpacing.lg),
                        _InsightSection(insights: dynamicData.insights),
                        const SizedBox(height: AppSpacing.lg),
                        _RecommendationSection(
                          recommendations: dynamicData.recommendations,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _TrackingGrid(
                          dashboard: dashboard,
                          metrics: dynamicData.metrics,
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

class _Header extends StatelessWidget {
  final DashboardEntity dashboard;

  const _Header({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final name = _shortName(dashboard.fullName);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? 'Xin chào' : 'Xin chào $name',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Góc sức khỏe của bạn',
                style: AppTextStyles.heading1.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 56,
          width: 56,
          decoration: AppDecoration.gradient(
            colors: const [AppColors.primary, AppColors.secondary],
            radius: AppRadius.circular,
            shadows: AppShadows.primary,
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final DashboardEntity dashboard;
  final DashboardDailyMetrics metrics;
  final List<DashboardInsightItem> insights;
  final List<DashboardRecommendationItem> recommendations;

  const _SummaryCard({
    required this.dashboard,
    required this.metrics,
    required this.insights,
    required this.recommendations,
  });

  @override
  Widget build(BuildContext context) {
    final message = insights.isNotEmpty
        ? insights.first.content
        : recommendations.isNotEmpty
        ? recommendations.first.description
        : 'Nami chưa có nhận xét mới cho hôm nay. Khi bạn chăm sóc thêm vài nhịp nhỏ, mình sẽ tổng hợp lại dịu dàng hơn.';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecoration.gradient(
        colors: const [Color(0xFF2563EB), Color(0xFF06B6D4)],
        radius: AppRadius.xl,
        shadows: AppShadows.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Báo cáo Nami vừa tổng hợp',
            style: AppTextStyles.labelMedium.copyWith(
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _scoreTitle(metrics.dailyScore),
            style: AppTextStyles.heading2.copyWith(
              color: Colors.white,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.white.withValues(alpha: .9),
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                  icon: Icons.favorite_rounded,
                  title: 'Nhịp tim',
                  value: metrics.heartRateBpm == null
                      ? '--'
                      : '${metrics.heartRateBpm} bpm',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _InfoChip(
                  icon: Icons.bloodtype_rounded,
                  title: 'SpO2',
                  value: metrics.oxygenSaturation == null
                      ? '--'
                      : '${metrics.oxygenSaturation!.toStringAsFixed(1)}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heading4.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayOverview extends StatelessWidget {
  final DashboardDailyMetrics metrics;

  const _TodayOverview({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _OverviewCard(
            title: 'Năng lượng',
            value: metrics.caloriesLogged > 0
                ? _formatInt(metrics.caloriesLogged)
                : metrics.caloriesPlanned > 0
                ? _formatInt(metrics.caloriesPlanned)
                : '--',
            unit: metrics.caloriesLogged > 0 ? 'kcal' : 'kcal dự kiến',
            icon: Icons.local_fire_department_rounded,
            color: AppColors.warning,
            bg: AppColors.warningSoft,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _OverviewCard(
            title: 'Nước',
            value: metrics.waterMl > 0
                ? (metrics.waterMl / 1000).toStringAsFixed(1)
                : '--',
            unit: 'L',
            icon: Icons.water_drop_rounded,
            color: AppColors.info,
            bg: AppColors.infoSoft,
          ),
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final Color bg;

  const _OverviewCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 4),
          Text(
            '$value $unit',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _HealthScoreCard extends StatelessWidget {
  final DashboardDailyMetrics metrics;

  const _HealthScoreCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final score = metrics.dailyScore;
    final progress = score <= 0 ? 0.0 : score / 100;
    return _SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          SizedBox(
            height: 112,
            width: 112,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: AppColors.borderLight,
                  valueColor: const AlwaysStoppedAnimation(AppColors.success),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      score <= 0 ? '--' : '$score',
                      style: AppTextStyles.displaySmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text('điểm', style: AppTextStyles.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tình trạng hôm nay', style: AppTextStyles.heading3),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _scoreMessage(score),
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.55),
                ),
                const SizedBox(height: AppSpacing.md),
                _StatusPill(label: _scoreLabel(score)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightSection extends StatelessWidget {
  final List<DashboardInsightItem> insights;

  const _InsightSection({required this.insights});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Mình nhận thấy',
      emptyTitle: 'Nami chưa có nhận xét mới',
      emptyMessage:
          'Khi có thêm tín hiệu từ ngày của bạn, Nami sẽ đặt những điều đáng chú ý ở đây.',
      children: insights.map((item) {
        return _SurfaceCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _riskIcon(item.riskLevel),
                color: _riskColor(item.riskLevel),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: AppTextStyles.heading4),
                    const SizedBox(height: 6),
                    Text(
                      item.content,
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _RecommendationSection extends StatelessWidget {
  final List<DashboardRecommendationItem> recommendations;

  const _RecommendationSection({required this.recommendations});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Đề xuất hôm nay',
      emptyTitle: 'Nami chưa có gợi ý mới',
      emptyMessage:
          'Bạn cứ tiếp tục chăm mình theo nhịp hiện tại. Khi có điều phù hợp, Nami sẽ nhẹ nhàng gợi ý.',
      children: recommendations.map((item) {
        return _SurfaceCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                item.isRead
                    ? Icons.lightbulb_outline_rounded
                    : Icons.lightbulb_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: AppTextStyles.heading4),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.45),
                    ),
                    if (item.actionText.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        item.actionText,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TrackingGrid extends StatelessWidget {
  final DashboardEntity dashboard;
  final DashboardDailyMetrics metrics;

  const _TrackingGrid({required this.dashboard, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final items = [
      _TrackingItem(
        title: 'Stress',
        value: metrics.stressLevel > 0
            ? _stressLabel(metrics.stressLevel)
            : '--',
        icon: Icons.psychology_rounded,
        color: AppColors.secondary,
      ),
      _TrackingItem(
        title: 'Ngủ',
        value: metrics.sleepHours > 0
            ? '${metrics.sleepHours.toStringAsFixed(1)}h'
            : '--',
        icon: Icons.bedtime_rounded,
        color: AppColors.primary,
      ),
      _TrackingItem(
        title: 'Bước',
        value: metrics.stepsCount > 0 ? _formatInt(metrics.stepsCount) : '--',
        icon: Icons.directions_walk_rounded,
        color: AppColors.success,
      ),
      _TrackingItem(
        title: 'BMI',
        value: dashboard.bmi > 0 ? dashboard.bmi.toStringAsFixed(1) : '--',
        icon: Icons.monitor_weight_rounded,
        color: AppColors.warning,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 700 ? 2 : 4;
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) => _TrackingCard(item: items[index]),
        );
      },
    );
  }
}

class _TrackingItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _TrackingItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _TrackingCard extends StatelessWidget {
  final _TrackingItem item;

  const _TrackingCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(item.icon, color: item.color),
          ),
          const Spacer(),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(item.title, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String emptyTitle;
  final String emptyMessage;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),
        if (children.isEmpty)
          _StateMessage(
            icon: Icons.auto_awesome_outlined,
            title: emptyTitle,
            message: emptyMessage,
          )
        else
          ...children.expand(
            (child) => [child, const SizedBox(height: AppSpacing.md)],
          ),
      ],
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: AppDecoration.card(
        radius: AppRadius.xl,
        shadows: AppShadows.sm,
      ),
      child: child,
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(AppRadius.circular),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelLarge.copyWith(color: AppColors.success),
      ),
    );
  }
}

class _SyncBanner extends StatelessWidget {
  const _SyncBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: _SurfaceCard(
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Nami đang cập nhật những tín hiệu mới nhất...',
                style: AppTextStyles.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.heading4),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.45),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử lại'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _shortName(String value) {
  final text = value.trim();
  if (text.isEmpty) return '';
  return text.split(RegExp(r'\s+')).last;
}

String _formatInt(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final fromEnd = text.length - i;
    buffer.write(text[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write(',');
  }
  return buffer.toString();
}

String _scoreTitle(int score) {
  if (score <= 0) return 'Chưa đủ dữ liệu để tổng hợp hôm nay';
  if (score >= 85) return 'Hôm nay của bạn rất ổn';
  if (score >= 65) return 'Bạn đang đi đúng hướng';
  if (score >= 40) return 'Mình cùng cải thiện nhẹ nhé';
  return 'Hôm nay cần thêm chút chăm sóc';
}

String _scoreMessage(int score) {
  if (score <= 0) {
    return 'Nami sẽ cập nhật điểm khi có thêm ghi nhận sức khỏe, nhiệm vụ, bữa ăn, nước uống hoặc giấc ngủ.';
  }
  return 'Điểm này được Nami tổng hợp từ những ghi nhận sức khỏe, nhiệm vụ hằng ngày, bữa ăn, nước uống và giấc ngủ.';
}

String _scoreLabel(int score) {
  if (score <= 0) return 'Chưa có dữ liệu';
  if (score >= 85) return 'Rất tốt';
  if (score >= 65) return 'Ổn định';
  if (score >= 40) return 'Cần chú ý';
  return 'Ưu tiên chăm sóc';
}

String _stressLabel(int value) {
  if (value <= 33) return 'Thấp';
  if (value <= 66) return 'Vừa';
  return 'Cao';
}

IconData _riskIcon(String riskLevel) {
  switch (riskLevel.toLowerCase()) {
    case 'high':
    case 'danger':
      return Icons.warning_rounded;
    case 'medium':
    case 'warning':
      return Icons.info_rounded;
    default:
      return Icons.check_circle_rounded;
  }
}

Color _riskColor(String riskLevel) {
  switch (riskLevel.toLowerCase()) {
    case 'high':
    case 'danger':
      return AppColors.error;
    case 'medium':
    case 'warning':
      return AppColors.warning;
    default:
      return AppColors.success;
  }
}
