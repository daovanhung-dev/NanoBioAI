import 'package:flutter/material.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart';
import 'package:nano_app/core/theme/theme.dart';

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
      title: 'Co the cua ban',
      subtitle:
          'Nabi giup ban uoc tinh nhanh cac chi so co ban, nhe nhang va ro rang.',
      badge: 'M04 v1',
      icon: Icons.monitor_weight_rounded,
      gradient: AppGradients.primary,
      children: [
        const NamiCareSectionTitle(
          title: 'Tinh BMI, BMR/RMR va TDEE',
          subtitle:
              'Nhap so do hien tai de xem goi y tham khao cho ngay hom nay.',
        ),
        const SizedBox(height: AppSpacing.md),
        NamiCareSurfaceCard(
          child: Column(
            children: [
              _NumberField(
                controller: _heightController,
                label: 'Chieu cao (cm)',
                icon: Icons.height_rounded,
              ),
              const SizedBox(height: AppSpacing.sm),
              _NumberField(
                controller: _weightController,
                label: 'Can nang (kg)',
                icon: Icons.monitor_weight_rounded,
              ),
              const SizedBox(height: AppSpacing.sm),
              _NumberField(
                controller: _ageController,
                label: 'Tuoi',
                icon: Icons.cake_rounded,
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<BasicHealthSex>(
                initialValue: _sex,
                decoration: _inputDecoration(
                  'Gioi tinh sinh hoc',
                  Icons.person_rounded,
                ),
                items: BasicHealthSex.values
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item.label),
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
                  'Muc van dong',
                  Icons.directions_walk_rounded,
                ),
                items: BasicHealthActivityLevel.values
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item.label),
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
                  label: const Text('Tinh chi so'),
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
            title: 'Can kiem tra lai so lieu',
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
          title: 'Thong tin tham khao',
          message:
              'Cac chi so nay chi ho tro theo doi suc khoe ca nhan va khong thay the chan doan, tu van hay dieu tri y khoa.',
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
        _error = error.message;
      });
    } catch (_) {
      setState(() {
        _report = null;
        _error = 'Vui long nhap day du chieu cao, can nang va tuoi.';
      });
    }
  }

  double _parseDouble(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '.').trim());
    if (parsed == null) {
      throw const BasicHealthCalculatorException('Vui long nhap so hop le.');
    }
    return parsed;
  }

  int _parseInt(String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      throw const BasicHealthCalculatorException('Vui long nhap so hop le.');
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
            value: '${report.bmi} - ${report.bmiCategory}',
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
            value: '${report.tdeeKcal} kcal/ngay',
          ),
          const SizedBox(height: AppSpacing.sm),
          _MetricRow(
            icon: Icons.water_drop_rounded,
            color: AppColors.info,
            title: 'Nuoc goi y',
            value: '${report.hydrationMl} ml/ngay',
          ),
          const SizedBox(height: AppSpacing.sm),
          NamiCareInfoTile(
            icon: Icons.bedtime_rounded,
            color: AppColors.primary,
            title: 'Giac ngu va van dong',
            subtitle: '${report.sleepGuidance} ${report.activityGuidance}',
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
      subtitle: 'Nabi dung chi so nay de goi y xu huong cham soc phu hop hon.',
      trailing: value,
    );
  }
}
