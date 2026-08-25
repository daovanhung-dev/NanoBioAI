import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../domain/entities/body_metrics_health_metric.dart';
import '../../domain/entities/body_metrics_health_report.dart';
import '../../domain/entities/body_metrics_health_snapshot.dart';
import '../../providers/body_metrics_providers.dart';
import '../widgets/body_metrics_health_highlights.dart';
import '../widgets/body_metrics_hero.dart';
import '../widgets/body_metrics_trend_card.dart';
import '../widgets/health_action_plan_card.dart';
import '../widgets/health_data_gap_card.dart';
import '../widgets/health_metric_section.dart';
import '../widgets/nabi_health_analysis_card.dart';

class BodyMetricsPage extends ConsumerStatefulWidget {
  const BodyMetricsPage({super.key});

  @override
  ConsumerState<BodyMetricsPage> createState() => _BodyMetricsPageState();
}

class _BodyMetricsPageState extends ConsumerState<BodyMetricsPage> {
  bool _showAllMetrics = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(bodyMetricsControllerProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bodyMetricsControllerProvider);
    return NamiCareScaffold(
      title: 'Sức khỏe của bạn',
      subtitle:
          'Xem nhanh cơ thể đang ổn ở đâu, điều gì cần chú ý và những thay đổi nhỏ nên ưu tiên.',
      badge: 'CHỈ SỐ SỨC KHỎE',
      icon: Icons.health_and_safety_rounded,
      gradient: AppGradients.primary,
      children: [
        if (state.status == BodyMetricsStatus.loadingData ||
            state.status == BodyMetricsStatus.calculating)
          const _LoadingCard()
        else if (state.snapshot == null ||
            state.report == null ||
            state.assessment == null)
          _ErrorCard(
            message:
                state.error ?? 'Nabi chưa có đủ dữ liệu để mở bảng sức khỏe.',
            onRetry: () =>
                ref.read(bodyMetricsControllerProvider.notifier).load(),
          )
        else
          ..._dashboard(context, state),
      ],
    );
  }

  List<Widget> _dashboard(BuildContext context, BodyMetricsState state) {
    final snapshot = state.snapshot!;
    final report = state.report!;
    final assessment = state.assessment!;
    final synthesis = state.aiBundle?.synthesis;

    return [
      BodyMetricsHero(
        report: report,
        assessment: assessment,
      ),
      const SizedBox(height: AppSpacing.sectionSpacing),
      BodyMetricsHealthHighlights(assessment: assessment),
      const SizedBox(height: AppSpacing.sectionSpacing),
      BodyMetricsKeyMetricsCard(
        report: report,
        assessment: assessment,
      ),
      const SizedBox(height: AppSpacing.sectionSpacing),
      BodyMetricsTrendCard(snapshot: snapshot),
      const SizedBox(height: AppSpacing.sectionSpacing),
      NabiHealthAnalysisCard(
        analyzing: state.status == BodyMetricsStatus.analyzing,
        currentStage: state.currentAiStage,
        totalStages: state.totalAiStages,
        stageId: state.currentStageId,
        bundle: state.aiBundle,
        onAnalyze: () =>
            ref.read(bodyMetricsControllerProvider.notifier).analyze(),
      ),
      if (synthesis != null) ...[
        const SizedBox(height: AppSpacing.sectionSpacing),
        HealthActionPlanCard(synthesis: synthesis),
      ],
      const SizedBox(height: AppSpacing.sectionSpacing),
      _AllMetricsToggleCard(
        expanded: _showAllMetrics,
        onPressed: () => setState(() => _showAllMetrics = !_showAllMetrics),
      ),
      if (_showAllMetrics) ...[
        const SizedBox(height: AppSpacing.sectionSpacing),
        ..._allMetricSections(report),
      ],
      const SizedBox(height: AppSpacing.sectionSpacing),
      _ProfileSnapshotCard(snapshot: snapshot),
      const SizedBox(height: AppSpacing.sectionSpacing),
      _ContextCard(snapshot: snapshot),
      const SizedBox(height: AppSpacing.sectionSpacing),
      HealthDataGapCard(gaps: report.dataGaps),
      const SizedBox(height: AppSpacing.sectionSpacing),
      const NamiCareEmptyState(
        icon: Icons.medical_information_outlined,
        color: AppColors.primary,
        title: 'Thông tin tham khảo',
        message:
            'Các chỉ số giúp bạn theo dõi sức khỏe và thói quen, không dùng để chẩn đoán bệnh. Nếu có triệu chứng bất thường hoặc lo lắng kéo dài, hãy trao đổi với chuyên gia y tế.',
      ),
    ];
  }

  List<Widget> _allMetricSections(BodyMetricsHealthReport report) {
    final sections = <Widget>[
      HealthMetricSection(
        title: 'Cơ thể',
        subtitle:
            'Cân nặng, chiều cao và xu hướng thay đổi theo thời gian.',
        icon: Icons.monitor_weight_rounded,
        metrics: report.category(BodyMetricsMetricCategory.body),
      ),
      HealthMetricSection(
        title: 'Ăn uống & năng lượng',
        subtitle:
            'Nhu cầu năng lượng và mức ăn uống được ước tính từ dữ liệu hiện có.',
        icon: Icons.local_fire_department_rounded,
        metrics: [
          ...report.category(BodyMetricsMetricCategory.energy),
          ...report.category(BodyMetricsMetricCategory.nutrition),
        ],
      ),
      HealthMetricSection(
        title: 'Nước',
        subtitle: 'Lượng nước bạn đã ghi nhận trong những ngày gần đây.',
        icon: Icons.water_drop_rounded,
        metrics: report.category(BodyMetricsMetricCategory.hydration),
      ),
      HealthMetricSection(
        title: 'Ngủ & tinh thần',
        subtitle:
            'Thời gian ngủ, mức căng thẳng và cảm xúc đã được ghi nhận.',
        icon: Icons.bedtime_rounded,
        metrics: report.category(BodyMetricsMetricCategory.recovery),
      ),
      HealthMetricSection(
        title: 'Vận động',
        subtitle:
            'Bước chân và các mức vận động tham khảo từ dữ liệu hiện có.',
        icon: Icons.directions_walk_rounded,
        metrics: report.category(BodyMetricsMetricCategory.activity),
      ),
      HealthMetricSection(
        title: 'Chỉ số đo thêm',
        subtitle:
            'Nhịp tim, SpO₂, huyết áp và đường huyết chỉ được hiển thị như số đo theo dõi, không tự chẩn đoán.',
        icon: Icons.monitor_heart_outlined,
        metrics: report.category(BodyMetricsMetricCategory.observation),
      ),
      HealthMetricSection(
        title: 'Dữ liệu & thói quen theo dõi',
        subtitle:
            'Mức duy trì kế hoạch và độ đầy đủ dữ liệu không được dùng như điểm sức khỏe.',
        icon: Icons.data_usage_rounded,
        metrics: [
          ...report.category(BodyMetricsMetricCategory.adherence),
          ...report.category(BodyMetricsMetricCategory.dataQuality),
        ],
      ),
    ];

    return [
      for (var index = 0; index < sections.length; index++) ...[
        sections[index],
        if (index != sections.length - 1)
          const SizedBox(height: AppSpacing.sectionSpacing),
      ],
    ];
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const NamiCareInfoTile(
      icon: Icons.sync_rounded,
      color: AppColors.info,
      title: 'Nabi đang xem dữ liệu gần đây',
      subtitle: 'Đang tổng hợp các thông tin sức khỏe và thói quen của bạn.',
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return NamiCareSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NamiCareEmptyState(
            icon: Icons.info_outline_rounded,
            color: AppColors.warning,
            title: 'Chưa thể mở dữ liệu sức khỏe',
            message: message,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

class _AllMetricsToggleCard extends StatelessWidget {
  final bool expanded;
  final VoidCallback onPressed;

  const _AllMetricsToggleCard({
    required this.expanded,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return NamiCareSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NamiCareSectionTitle(
            title: expanded ? 'Toàn bộ chỉ số' : 'Muốn xem chi tiết hơn?',
            subtitle: expanded
                ? 'Các chỉ số bên dưới vẫn giữ đầy đủ số liệu và phần giải thích chuyên môn khi bạn mở từng mục.'
                : 'Mặt chính chỉ giữ những thông tin dễ hiểu nhất. Bạn vẫn có thể mở toàn bộ dữ liệu khi cần.',
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(
              expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            ),
            label: Text(expanded ? 'Thu gọn chỉ số' : 'Xem toàn bộ chỉ số'),
          ),
        ],
      ),
    );
  }
}

class _ProfileSnapshotCard extends StatelessWidget {
  const _ProfileSnapshotCard({required this.snapshot});

  final BodyMetricsHealthSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    String value(Object? value, String unit) =>
        value == null ? 'Chưa có dữ liệu' : '$value $unit'.trim();
    return NamiCareSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NamiCareSectionTitle(
            title: 'Thông tin cơ bản của bạn',
            subtitle:
                'Nabi dùng các thông tin này để tính những chỉ số phù hợp hơn.',
          ),
          const SizedBox(height: AppSpacing.md),
          NamiCareInfoTile(
            icon: Icons.height_rounded,
            color: AppColors.info,
            title: 'Chiều cao',
            subtitle: value(snapshot.heightCm, 'cm'),
          ),
          const SizedBox(height: AppSpacing.sm),
          NamiCareInfoTile(
            icon: Icons.monitor_weight_rounded,
            color: AppColors.info,
            title: 'Cân nặng hiện tại',
            subtitle: value(snapshot.currentWeightKg, 'kg'),
          ),
          const SizedBox(height: AppSpacing.sm),
          NamiCareInfoTile(
            icon: Icons.cake_outlined,
            color: AppColors.info,
            title: 'Tuổi',
            subtitle: value(snapshot.ageYears, ''),
          ),
          const SizedBox(height: AppSpacing.sm),
          NamiCareInfoTile(
            icon: Icons.directions_walk_rounded,
            color: AppColors.info,
            title: 'Mức vận động',
            subtitle: snapshot.activityLevel?.label ?? 'Chưa có dữ liệu',
          ),
          if (snapshot.heightCm == null ||
              snapshot.currentWeightKg == null ||
              snapshot.ageYears == null ||
              snapshot.activityLevel == null) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => context.push(V1RoutePaths.profile),
              icon: const Icon(Icons.manage_accounts_outlined),
              label: const Text('Cập nhật hồ sơ'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContextCard extends StatelessWidget {
  const _ContextCard({required this.snapshot});

  final BodyMetricsHealthSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final conditions =
        snapshot.declaredConditions.map((item) => item.name).toList();
    final goals = snapshot.activeGoals.map((item) => item.name).toList();
    final treatments = snapshot.treatments
        .expand((item) => [item.treatmentName, item.medicationName])
        .whereType<String>()
        .toList();
    return NamiCareSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NamiCareSectionTitle(
            title: 'Bối cảnh cá nhân',
            subtitle:
                'Các tình trạng, mục tiêu và thói quen bạn đã cung cấp giúp Nabi hiểu đúng bối cảnh hơn.',
          ),
          const SizedBox(height: AppSpacing.md),
          _ContextRow(title: 'Tình trạng đã khai báo', items: conditions),
          _ContextRow(title: 'Mục tiêu đang hoạt động', items: goals),
          _ContextRow(title: 'Dị ứng đã khai báo', items: snapshot.allergies),
          _ContextRow(
            title: 'Điều trị/thuốc đã khai báo',
            items: treatments,
          ),
          _ContextRow(
            title: 'Thói quen đang ghi nhận',
            items: snapshot.lifestyle?.activeFlags ?? const [],
          ),
        ],
      ),
    );
  }
}

class _ContextRow extends StatelessWidget {
  const _ContextRow({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: NamiCareInfoTile(
        icon: Icons.label_outline_rounded,
        color: AppColors.secondary,
        title: title,
        subtitle: items.isEmpty
            ? 'Không có mục nào được khai báo.'
            : items.join(' • '),
      ),
    );
  }
}
