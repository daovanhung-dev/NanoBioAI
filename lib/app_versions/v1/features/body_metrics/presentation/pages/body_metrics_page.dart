import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/shared/widgets/vietnamese_ui_text.dart';

import '../../domain/entities/basic_health_calculator_models.dart';
import '../../domain/entities/body_metrics_personal_context.dart';
import '../../domain/services/basic_health_calculator.dart';
import '../../domain/services/body_metrics_projection_policy.dart';
import '../../providers/body_metrics_providers.dart';

class BodyMetricsPage extends ConsumerStatefulWidget {
  const BodyMetricsPage({super.key});

  @override
  ConsumerState<BodyMetricsPage> createState() => _BodyMetricsPageState();
}

class _BodyMetricsPageState extends ConsumerState<BodyMetricsPage> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  BasicHealthSex? _sex;
  BasicHealthActivityLevel? _activity;
  BasicHealthReport? _report;
  BodyMetricsThirtyDayScenario? _scenario;
  BodyMetricsAiInsight? _aiInsight;
  String? _error;
  bool _didPrefill = false;
  bool _analyzing = false;

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final personalContext = ref.watch(bodyMetricsPersonalContextProvider);
    personalContext.whenData(_queuePrefill);

    return NamiCareScaffold(
      title: 'Cơ thể của bạn',
      subtitle:
          'Nabi dùng hồ sơ, thực đơn và lịch chăm sóc của bạn để tính chỉ số hiện tại và phân tích xu hướng sau một tháng.',
      badge: 'CHỈ SỐ CƠ THỂ',
      icon: Icons.monitor_weight_rounded,
      gradient: AppGradients.primary,
      children: [
        _ProfileDataBanner(personalContext: personalContext),
        const SizedBox(height: AppSpacing.sectionSpacing),
        const NamiCareSectionTitle(
          title: 'Dữ liệu cơ thể hiện tại',
          subtitle:
              'Nabi tự điền từ hồ sơ gần nhất. Bạn vẫn có thể chỉnh lại số đo trước khi phân tích.',
        ),
        const SizedBox(height: AppSpacing.md),
        NamiCareSurfaceCard(
          child: Column(
            children: [
              _NumberField(
                controller: _heightController,
                label: 'Chiều cao (cm)',
                icon: Icons.height_rounded,
              ),
              const SizedBox(height: AppSpacing.sm),
              _NumberField(
                controller: _weightController,
                label: 'Cân nặng (kg)',
                icon: Icons.monitor_weight_rounded,
              ),
              const SizedBox(height: AppSpacing.sm),
              _NumberField(
                controller: _ageController,
                label: 'Tuổi',
                icon: Icons.cake_rounded,
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<BasicHealthSex>(
                key: ValueKey('body-metrics-sex-${_sex?.code ?? 'unset'}'),
                initialValue: _sex,
                decoration: _inputDecoration(
                  'Giới tính sinh học',
                  Icons.person_rounded,
                ),
                items: BasicHealthSex.values
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(vietnameseUiText(item.label)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _sex = value);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<BasicHealthActivityLevel>(
                key: ValueKey(
                  'body-metrics-activity-${_activity?.code ?? 'unset'}',
                ),
                initialValue: _activity,
                decoration: _inputDecoration(
                  'Mức vận động',
                  Icons.directions_walk_rounded,
                ),
                items: BasicHealthActivityLevel.values
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(vietnameseUiText(item.label)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _activity = value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Khi bạn chọn Phân tích cơ thể, Nabi sẽ gửi các chỉ số wellness tổng hợp và bối cảnh kế hoạch tới dịch vụ AI để diễn giải. Không gửi ảnh minh chứng hoặc nhật ký thô.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.semanticColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _analyzing ? null : _calculateAndAnalyze,
                  icon: _analyzing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(
                    _analyzing ? 'Nabi đang phân tích...' : 'Phân tích cơ thể',
                  ),
                ),
              ),
            ],
          ),
        ),
        AppStateSwitcher(
          alignment: Alignment.topCenter,
          child: _error != null
              ? Padding(
                  key: const ValueKey('body-metrics-error'),
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: NamiCareEmptyState(
                    icon: Icons.info_outline_rounded,
                    color: AppColors.warning,
                    title: 'Cần kiểm tra lại số liệu',
                    message: _error!,
                  ),
                )
              : _report != null
                  ? Padding(
                      key: const ValueKey('body-metrics-report'),
                      padding: const EdgeInsets.only(
                        top: AppSpacing.sectionSpacing,
                      ),
                      child: Column(
                        children: [
                          _ReportCard(report: _report!),
                          const SizedBox(height: AppSpacing.sectionSpacing),
                          if (_scenario != null)
                            _ThirtyDayScenarioCard(
                              report: _report!,
                              scenario: _scenario!,
                            ),
                          const SizedBox(height: AppSpacing.sectionSpacing),
                          if (_aiInsight != null)
                            _AiInsightCard(insight: _aiInsight!),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(
                      key: ValueKey('body-metrics-idle'),
                    ),
        ),
        const SizedBox(height: AppSpacing.sectionSpacing),
        const NamiCareEmptyState(
          icon: Icons.medical_information_rounded,
          color: AppColors.primary,
          title: 'Ước tính tham khảo',
          message:
              'Các chỉ số và dự báo chỉ mô tả xu hướng chăm sóc sức khỏe, không phải chẩn đoán, điều trị hay cam kết kết quả sau một tháng.',
        ),
      ],
    );
  }

  void _queuePrefill(BodyMetricsPersonalContext? context) {
    if (_didPrefill || context == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didPrefill) return;
      _didPrefill = true;
      _heightController.text = _formatInput(context.heightCm);
      _weightController.text = _formatInput(context.weightKg);
      _ageController.text = context.ageYears?.toString() ?? '';
      setState(() {
        _sex = context.sex;
        _activity = context.activityLevel;
      });
    });
  }

  Future<void> _calculateAndAnalyze() async {
    AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
    setState(() {
      _analyzing = true;
      _error = null;
      _aiInsight = null;
    });
    try {
      final sex = _sex;
      final activity = _activity;
      if (sex == null) {
        throw const BasicHealthCalculatorException(
          'Vui lòng chọn giới tính sinh học để tính BMR/RMR chính xác hơn.',
        );
      }
      if (activity == null) {
        throw const BasicHealthCalculatorException(
          'Vui lòng chọn mức vận động hiện tại.',
        );
      }
      final input = BasicHealthInput(
        heightCm: _parseDouble(_heightController.text),
        weightKg: _parseDouble(_weightController.text),
        ageYears: _parseInt(_ageController.text),
        sex: sex,
        activityLevel: activity,
      );
      final report = BasicHealthCalculator.calculate(input);
      BodyMetricsPersonalContext? context;
      try {
        context = await ref.read(bodyMetricsPersonalContextProvider.future);
      } catch (_) {
        // Calculator output is still valid when local context cannot be loaded.
      }
      final scenario = BodyMetricsProjectionPolicy.build(
        report: report,
        context: context,
      );
      final insight = await ref.read(bodyMetricsAiServiceProvider).analyze(
            report: report,
            scenario: scenario,
            dataCompleteness: context?.dataCompleteness ?? 0,
          );
      if (!mounted) return;
      setState(() {
        _report = report;
        _scenario = scenario;
        _aiInsight = insight;
        _error = null;
      });
      AppFeedbackService.instance.emit(AppFeedbackType.success);
    } on BasicHealthCalculatorException catch (error) {
      AppFeedbackService.instance.emit(AppFeedbackType.warning);
      if (!mounted) return;
      setState(() {
        _report = null;
        _scenario = null;
        _aiInsight = null;
        _error = vietnameseSystemUiText(
          error.message,
          fallback: 'Nabi chưa thể tính chỉ số lúc này. Bạn thử lại nhé.',
        );
      });
    } catch (_) {
      AppFeedbackService.instance.emit(AppFeedbackType.warning);
      if (!mounted) return;
      setState(() {
        _report = null;
        _scenario = null;
        _aiInsight = null;
        _error = 'Vui lòng kiểm tra chiều cao, cân nặng và tuổi.';
      });
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  double _parseDouble(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '.').trim());
    if (parsed == null) {
      throw const BasicHealthCalculatorException('Vui lòng nhập số hợp lệ.');
    }
    return parsed;
  }

  int _parseInt(String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      throw const BasicHealthCalculatorException('Vui lòng nhập số hợp lệ.');
    }
    return parsed;
  }

  String _formatInput(double? value) {
    if (value == null) return '';
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }
}

class _ProfileDataBanner extends StatelessWidget {
  final AsyncValue<BodyMetricsPersonalContext?> personalContext;

  const _ProfileDataBanner({required this.personalContext});

  @override
  Widget build(BuildContext context) {
    return personalContext.when(
      loading: () => const NamiCareInfoTile(
        icon: Icons.sync_rounded,
        color: AppColors.info,
        title: 'Đang đọc hồ sơ của bạn',
        subtitle: 'Nabi đang lấy số đo và kế hoạch gần nhất trên thiết bị.',
      ),
      error: (_, __) => const NamiCareInfoTile(
        icon: Icons.edit_note_rounded,
        color: AppColors.warning,
        title: 'Bạn có thể nhập số đo thủ công',
        subtitle: 'Nabi chưa đọc được hồ sơ lúc này.',
      ),
      data: (data) {
        if (data == null || !data.hasProfileMetrics) {
          return const NamiCareInfoTile(
            icon: Icons.person_add_alt_1_rounded,
            color: AppColors.warning,
            title: 'Hồ sơ cơ thể chưa đầy đủ',
            subtitle:
                'Bạn nhập số đo bên dưới; Nabi sẽ không tự tạo dữ liệu còn thiếu.',
          );
        }
        final source = data.weightFromRecentTracking
            ? 'Cân nặng được ưu tiên từ lần theo dõi gần nhất.'
            : 'Số đo được lấy từ hồ sơ sức khỏe gần nhất.';
        return NamiCareInfoTile(
          icon: Icons.verified_user_rounded,
          color: AppColors.success,
          title: 'Đã dùng dữ liệu cá nhân của bạn',
          subtitle: source,
        );
      },
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final BasicHealthReport report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return NamiCareSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NamiCareSectionTitle(
            title: 'Cơ thể hiện tại',
            subtitle: 'Các chỉ số được tính bằng công thức wellness đã version hóa.',
          ),
          const SizedBox(height: AppSpacing.md),
          _MetricRow(
            icon: Icons.favorite_rounded,
            color: AppColors.success,
            title: 'BMI',
            value: '${report.bmi} - ${vietnameseUiText(report.bmiCategory)}',
          ),
          const SizedBox(height: AppSpacing.sm),
          _MetricRow(
            icon: Icons.local_fire_department_rounded,
            color: AppColors.warning,
            title: 'BMR/RMR',
            value: '${report.bmrKcal}/${report.rmrKcal} kcal',
          ),
          const SizedBox(height: AppSpacing.sm),
          _MetricRow(
            icon: Icons.bolt_rounded,
            color: AppColors.secondary,
            title: 'TDEE',
            value: '${report.tdeeKcal} kcal/ngày',
          ),
          const SizedBox(height: AppSpacing.sm),
          _MetricRow(
            icon: Icons.water_drop_rounded,
            color: AppColors.info,
            title: 'Nước gợi ý',
            value: '${report.hydrationMl} ml/ngày',
          ),
          const SizedBox(height: AppSpacing.sm),
          NamiCareInfoTile(
            icon: Icons.bedtime_rounded,
            color: AppColors.primary,
            title: 'Giấc ngủ và vận động',
            subtitle:
                '${vietnameseUiText(report.sleepGuidance)} ${vietnameseUiText(report.activityGuidance)}',
          ),
        ],
      ),
    );
  }
}

class _ThirtyDayScenarioCard extends StatelessWidget {
  final BasicHealthReport report;
  final BodyMetricsThirtyDayScenario scenario;

  const _ThirtyDayScenarioCard({required this.report, required this.scenario});

  @override
  Widget build(BuildContext context) {
    final energyLabel = switch (scenario.energyDirection) {
      BodyMetricsEnergyDirection.belowMaintenance =>
        'Thực đơn đang thấp hơn mức năng lượng duy trì ước tính',
      BodyMetricsEnergyDirection.nearMaintenance =>
        'Thực đơn đang gần mức năng lượng duy trì ước tính',
      BodyMetricsEnergyDirection.aboveMaintenance =>
        'Thực đơn đang cao hơn mức năng lượng duy trì ước tính',
      BodyMetricsEnergyDirection.unknown =>
        'Chưa đủ ngày thực đơn để so với mức năng lượng duy trì',
    };
    return NamiCareSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NamiCareSectionTitle(
            title: 'Kịch bản sau 30 ngày',
            subtitle:
                'Giả định bạn duy trì thực đơn và lịch chăm sóc đang có trong NanoBio.',
          ),
          const SizedBox(height: AppSpacing.md),
          NamiCareInfoTile(
            icon: Icons.restaurant_menu_rounded,
            color: AppColors.secondary,
            title: energyLabel,
            subtitle: scenario.averagePlannedCalories == null
                ? 'Nabi chưa có đủ dữ liệu năng lượng từ thực đơn.'
                : '${scenario.plannedMealDays} ngày thực đơn, trung bình ${scenario.averagePlannedCalories!.round()} kcal/ngày; TDEE hiện tại ${report.tdeeKcal} kcal/ngày.',
          ),
          const SizedBox(height: AppSpacing.sm),
          NamiCareInfoTile(
            icon: Icons.event_available_rounded,
            color: AppColors.primary,
            title: '${scenario.plannedScheduleItems} nhiệm vụ chăm sóc trong dữ liệu 30 ngày',
            subtitle:
                'Trong đó có ${scenario.plannedExerciseItems} nhiệm vụ vận động được Nabi dùng làm bối cảnh xu hướng.',
          ),
        ],
      ),
    );
  }
}

class _AiInsightCard extends StatelessWidget {
  final BodyMetricsAiInsight insight;

  const _AiInsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return NamiCareSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NamiCareSectionTitle(
            title: 'Nabi phân tích',
            subtitle: insight.generatedByAi
                ? 'AI diễn giải dữ liệu đã được app tính và tổng hợp; AI không tự tạo số đo.'
                : 'Phần tính toán vẫn hoạt động dù AI tạm thời chưa sẵn sàng.',
          ),
          const SizedBox(height: AppSpacing.md),
          NamiCareInfoTile(
            icon: Icons.person_search_rounded,
            color: AppColors.info,
            title: 'Hiện tại',
            subtitle: insight.currentStatus,
          ),
          const SizedBox(height: AppSpacing.sm),
          NamiCareInfoTile(
            icon: Icons.trending_up_rounded,
            color: AppColors.success,
            title: 'Nếu duy trì trong 30 ngày',
            subtitle: insight.afterThirtyDays,
          ),
          const SizedBox(height: AppSpacing.sm),
          NamiCareInfoTile(
            icon: Icons.analytics_outlined,
            color: AppColors.tertiary,
            title: 'Độ tin cậy: ${insight.confidence}',
            subtitle: insight.factors.isEmpty
                ? 'Nabi sẽ phân tích sâu hơn khi dữ liệu thực đơn và lịch chăm sóc đầy đủ hơn.'
                : insight.factors.join(' • '),
          ),
          if (insight.assumptions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            NamiCareInfoTile(
              icon: Icons.rule_rounded,
              color: AppColors.warning,
              title: 'Giả định',
              subtitle: insight.assumptions.join(' • '),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;

  const _MetricRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return NamiCareInfoTile(
      icon: icon,
      color: color,
      title: title,
      subtitle: 'Nabi dùng chỉ số này để gợi ý xu hướng chăm sóc phù hợp hơn.',
      trailing: value,
    );
  }
}
