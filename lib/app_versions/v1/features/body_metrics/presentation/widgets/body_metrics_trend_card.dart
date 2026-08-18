import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../domain/entities/body_metrics_health_snapshot.dart';

class BodyMetricsTrendCard extends StatefulWidget {
  final BodyMetricsHealthSnapshot snapshot;

  const BodyMetricsTrendCard({super.key, required this.snapshot});

  @override
  State<BodyMetricsTrendCard> createState() => _BodyMetricsTrendCardState();
}

class _BodyMetricsTrendCardState extends State<BodyMetricsTrendCard> {
  int days = 7;

  @override
  Widget build(BuildContext context) {
    final rows = widget.snapshot.trackingWithinDays(days).reversed.toList(growable: false);
    return NamiCareSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: NamiCareSectionTitle(
                  title: 'Xu hướng sức khỏe',
                  subtitle: 'Chỉ vẽ các ngày có dữ liệu thật, không nội suy.',
                ),
              ),
              ChoiceChip(label: const Text('7 ngày'), selected: days == 7, onSelected: (_) => setState(() => days = 7)),
              const SizedBox(width: 6),
              ChoiceChip(label: const Text('30 ngày'), selected: days == 30, onSelected: (_) => setState(() => days = 30)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _Series(title: 'Cân nặng', unit: 'kg', values: rows.map((row) => row.weightKg).whereType<double>().toList()),
          _Series(title: 'Giấc ngủ', unit: 'giờ', values: rows.map((row) => row.sleepHours).whereType<double>().toList()),
          _Series(title: 'Nước', unit: 'ml', values: rows.map((row) => row.waterMl).whereType<double>().toList()),
          _Series(title: 'Bước chân', unit: 'bước', values: rows.map((row) => row.steps).whereType<double>().toList()),
        ],
      ),
    );
  }
}

class _Series extends StatelessWidget {
  final String title;
  final String unit;
  final List<double> values;

  const _Series({required this.title, required this.unit, required this.values});

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: NamiCareInfoTile(
          icon: Icons.show_chart_rounded,
          color: AppColors.info,
          title: title,
          subtitle: 'Chưa đủ dữ liệu để vẽ xu hướng.',
        ),
      );
    }
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final span = math.max(maxValue - minValue, 0.0001);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('$title • ${values.last.toStringAsFixed(1)} $unit', style: AppTextStyles.bodySmall.copyWith(fontWeight: AppTypography.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 54,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final value in values.take(30))
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: FractionallySizedBox(
                        heightFactor: .18 + .82 * ((value - minValue) / span),
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: .60),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
