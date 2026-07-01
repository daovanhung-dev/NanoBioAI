import 'package:flutter/material.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/shared/widgets/vietnamese_ui_text.dart';

import '../../domain/entities/basic_health_calculator_models.dart';
import '../../domain/services/basic_health_calculator.dart';

class BodyMetricsPage extends StatefulWidget {
  const BodyMetricsPage({super.key});

  @override
  State<BodyMetricsPage> createState() => _BodyMetricsPageState();
}

class _BodyMetricsPageState extends State<BodyMetricsPage> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  BasicHealthSex _sex = BasicHealthSex.female;
  BasicHealthActivityLevel _activity = BasicHealthActivityLevel.light;
  BasicHealthReport? _report;
  String? _error;

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NamiCareScaffold(
      title: 'Cơ thể của bạn',
      subtitle:
          'Nabi giúp bạn ước tính nhanh các chỉ số cơ bản, nhẹ nhàng và rõ ràng.',
      badge: 'M04 v1',
      icon: Icons.monitor_weight_rounded,
      gradient: AppGradients.primary,
      children: [
        const NamiCareSectionTitle(
          title: 'Tính BMI, BMR/RMR và TDEE',
          subtitle:
              'Nhập số đo hiện tại để xem gợi ý tham khảo cho ngày hôm nay.',
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
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _calculate,
                  icon: const Icon(Icons.calculate_rounded),
                  label: const Text('Tính chỉ số'),
                ),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          NamiCareEmptyState(
            icon: Icons.info_outline_rounded,
            color: AppColors.warning,
            title: 'Cần kiểm tra lại số liệu',
            message: _error!,
          ),
        ],
        if (_report != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _ReportCard(report: _report!),
        ],
        const SizedBox(height: AppSpacing.lg),
        const NamiCareEmptyState(
          icon: Icons.medical_information_rounded,
          color: AppColors.primary,
          title: 'Thông tin tham khảo',
          message:
              'Các chỉ số này chỉ hỗ trợ theo dõi sức khỏe cá nhân và không thay thế chẩn đoán, tư vấn hay điều trị y khoa.',
        ),
      ],
    );
  }

  void _calculate() {
    try {
      final input = BasicHealthInput(
        heightCm: _parseDouble(_heightController.text),
        weightKg: _parseDouble(_weightController.text),
        ageYears: _parseInt(_ageController.text),
        sex: _sex,
        activityLevel: _activity,
      );
      final report = BasicHealthCalculator.calculate(input);
      setState(() {
        _report = report;
        _error = null;
      });
    } on BasicHealthCalculatorException catch (error) {
      setState(() {
        _report = null;
        _error = vietnameseUiText(error.message);
      });
    } catch (_) {
      setState(() {
        _report = null;
        _error = 'Vui lòng nhập đầy đủ chiều cao, cân nặng và tuổi.';
      });
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
        children: [
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
            subtitle: '${vietnameseUiText(report.sleepGuidance)} ${vietnameseUiText(report.activityGuidance)}',
            trailing: report.formulaVersion,
          ),
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
