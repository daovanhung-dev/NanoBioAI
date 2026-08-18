import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';

import '../../domain/entities/body_metrics_health_metric.dart';
import '../../domain/entities/body_metrics_health_snapshot.dart';
import '../../providers/body_metrics_providers.dart';
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
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(bodyMetricsControllerProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bodyMetricsControllerProvider);
    return NamiCareScaffold(
      title: 'Sức khỏe của bạn',
      subtitle:
          'Theo dõi cơ thể, dinh dưỡng, giấc ngủ, vận động và xu hướng từ chính dữ liệu của bạn.',
      badge: 'CHỈ SỐ SỨC KHỎE',
      icon: Icons.health_and_safety_rounded,
      gradient: AppGradients.primary,
      children: [
        if (state.status == BodyMetricsStatus.loadingData ||
            state.status == BodyMetricsStatus.calculating)
          const _LoadingCard()
        else if (state.snapshot == null || state.report == null)
          _ErrorCard(
            message: state.error ?? 'Nabi chưa có đủ dữ liệu để mở bảng sức khỏe.',
            onRetry: () => ref.read(bodyMetricsControllerProvider.notifier).load(),
          )
        else
          ..._dashboard(context, state),
      ],
    );
  }

  List<Widget> _dashboard(BuildContext context, BodyMetricsState state) {
    final snapshot = state.snapshot!;
    final report = state.report!;
    final aiStages = state.totalAiStages > 0 ? state.totalAiStages : 5;
    final synthesis = state.aiBundle?.synthesis;
    return [
      BodyMetricsHero(snapshot: snapshot, report: report, aiStageCount: aiStages),
      const SizedBox(height: AppSpacing.sectionSpacing),
      _ReadOnlyProfileCard(snapshot: snapshot),
      const SizedBox(height: AppSpacing.sectionSpacing),
      HealthMetricSection(
        title: 'Tổng quan cơ thể',
        subtitle: 'Dữ liệu đo và chỉ số tính toán được hiển thị tách biệt với nhận định AI.',
        icon: Icons.monitor_weight_rounded,
        metrics: report.category(BodyMetricsMetricCategory.body),
      ),
      const SizedBox(height: AppSpacing.sectionSpacing),
      HealthMetricSection(
        title: 'Năng lượng',
        subtitle: 'Ước tính deterministic từ hồ sơ, mức vận động và dữ liệu thực đơn.',
        icon: Icons.local_fire_department_rounded,
        metrics: report.category(BodyMetricsMetricCategory.energy),
      ),
      const SizedBox(height: AppSpacing.sectionSpacing),
      HealthMetricSection(
        title: 'Dinh dưỡng',
        subtitle: 'Macro, chất xơ và vi chất từ các ngày thực đơn có dữ liệu.',
        icon: Icons.restaurant_rounded,
        metrics: report.category(BodyMetricsMetricCategory.nutrition),
      ),
      const SizedBox(height: AppSpacing.sectionSpacing),
      HealthMetricSection(
        title: 'Nước',
        subtitle: 'Trung bình và xu hướng ghi nhận, không nội suy ngày thiếu.',
        icon: Icons.water_drop_rounded,
        metrics: report.category(BodyMetricsMetricCategory.hydration),
      ),
      const SizedBox(height: AppSpacing.sectionSpacing),
      HealthMetricSection(
        title: 'Ngủ & phục hồi',
        subtitle: 'Dựa trên thời lượng ngủ, stress và mood đã ghi nhận.',
        icon: Icons.bedtime_rounded,
        metrics: report.category(BodyMetricsMetricCategory.recovery),
      ),
      const SizedBox(height: AppSpacing.sectionSpacing),
      HealthMetricSection(
        title: 'Vận động',
        subtitle: 'Bước chân và vùng HR chỉ là ước tính wellness.',
        icon: Icons.directions_walk_rounded,
        metrics: report.category(BodyMetricsMetricCategory.activity),
      ),
      const SizedBox(height: AppSpacing.sectionSpacing),
      HealthMetricSection(
        title: 'Dữ liệu đo chuyên sâu',
        subtitle: 'HR, SpO₂, huyết áp và đường huyết chỉ hiển thị observation; Nabi không phân loại bệnh từ đây.',
        icon: Icons.monitor_heart_outlined,
        metrics: report.category(BodyMetricsMetricCategory.observation),
      ),
      const SizedBox(height: AppSpacing.sectionSpacing),
      HealthMetricSection(
        title: 'Mức thực hiện kế hoạch',
        subtitle: 'Theo dõi completion, không dùng làm điểm sức khỏe.',
        icon: Icons.fact_check_outlined,
        metrics: report.category(BodyMetricsMetricCategory.adherence),
      ),
      const SizedBox(height: AppSpacing.sectionSpacing),
      HealthMetricSection(
        title: 'Chất lượng dữ liệu',
        subtitle: 'Đây là độ đầy đủ/freshness dữ liệu, không phải điểm sức khỏe.',
        icon: Icons.data_usage_rounded,
        metrics: report.category(BodyMetricsMetricCategory.dataQuality),
      ),
      const SizedBox(height: AppSpacing.sectionSpacing),
      BodyMetricsTrendCard(snapshot: snapshot),
      const SizedBox(height: AppSpacing.sectionSpacing),
      _ContextCard(snapshot: snapshot),
      const SizedBox(height: AppSpacing.sectionSpacing),
      NabiHealthAnalysisCard(
        analyzing: state.status == BodyMetricsStatus.analyzing,
        currentStage: state.currentAiStage,
        totalStages: state.totalAiStages,
        stageId: state.currentStageId,
        bundle: state.aiBundle,
        onAnalyze: () => ref.read(bodyMetricsControllerProvider.notifier).analyze(),
      ),
      if (synthesis != null) ...[
        const SizedBox(height: AppSpacing.sectionSpacing),
        HealthActionPlanCard(synthesis: synthesis),
      ],
      const SizedBox(height: AppSpacing.sectionSpacing),
      HealthDataGapCard(gaps: report.dataGaps),
      const SizedBox(height: AppSpacing.sectionSpacing),
      const NamiCareEmptyState(
        icon: Icons.medical_information_outlined,
        color: AppColors.primary,
        title: 'Lưu ý an toàn',
        message:
            'Các chỉ số là công cụ wellness tham khảo. Nabi không chẩn đoán, không kê thuốc, không đổi liều và không thay thế đánh giá của chuyên gia y tế.',
      ),
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
      title: 'Nabi đang tổng hợp dữ liệu',
      subtitle: 'Đang đọc hồ sơ hiện tại và dữ liệu sức khỏe gần đây.',
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

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

class _ReadOnlyProfileCard extends StatelessWidget {
  final BodyMetricsHealthSnapshot snapshot;

  const _ReadOnlyProfileCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    String value(Object? value, String unit) => value == null ? 'Chưa có dữ liệu' : '$value $unit'.trim();
    return NamiCareSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NamiCareSectionTitle(
            title: 'Dữ liệu sức khỏe của bạn',
            subtitle: 'Read-only tại màn này. Muốn thay đổi, hãy cập nhật tại feature sở hữu dữ liệu.',
          ),
          const SizedBox(height: AppSpacing.md),
          NamiCareInfoTile(icon: Icons.height_rounded, color: AppColors.info, title: 'Chiều cao', subtitle: value(snapshot.heightCm, 'cm')),
          const SizedBox(height: AppSpacing.sm),
          NamiCareInfoTile(icon: Icons.monitor_weight_rounded, color: AppColors.info, title: 'Cân nặng hiện tại', subtitle: value(snapshot.currentWeightKg, 'kg')),
          const SizedBox(height: AppSpacing.sm),
          NamiCareInfoTile(icon: Icons.cake_outlined, color: AppColors.info, title: 'Tuổi', subtitle: value(snapshot.ageYears, '')),
          const SizedBox(height: AppSpacing.sm),
          NamiCareInfoTile(icon: Icons.directions_walk_rounded, color: AppColors.info, title: 'Mức vận động', subtitle: snapshot.activityLevel?.label ?? 'Chưa có dữ liệu'),
          if (snapshot.heightCm == null || snapshot.currentWeightKg == null || snapshot.ageYears == null || snapshot.activityLevel == null) ...[
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
  final BodyMetricsHealthSnapshot snapshot;

  const _ContextCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final conditions = snapshot.declaredConditions.map((item) => item.name).toList();
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
            subtitle: 'Chỉ dùng những tình trạng/mục tiêu mà người dùng đã khai báo.',
          ),
          const SizedBox(height: AppSpacing.md),
          _ContextRow(title: 'Tình trạng đã khai báo', items: conditions),
          _ContextRow(title: 'Mục tiêu đang hoạt động', items: goals),
          _ContextRow(title: 'Dị ứng đã khai báo', items: snapshot.allergies),
          _ContextRow(title: 'Điều trị/thuốc đã khai báo', items: treatments),
          _ContextRow(title: 'Thói quen đang ghi nhận', items: snapshot.lifestyle?.activeFlags ?? const []),
        ],
      ),
    );
  }
}

class _ContextRow extends StatelessWidget {
  final String title;
  final List<String> items;

  const _ContextRow({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: NamiCareInfoTile(
        icon: Icons.label_outline_rounded,
        color: AppColors.secondary,
        title: title,
        subtitle: items.isEmpty ? 'Không có mục nào được khai báo.' : items.join(' • '),
      ),
    );
  }
}
