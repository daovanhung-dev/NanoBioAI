import 'package:flutter/material.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart';
import 'package:nano_app/core/theme/theme.dart';

class HealthDataGapCard extends StatelessWidget {
  final List<String> gaps;

  const HealthDataGapCard({super.key, required this.gaps});

  @override
  Widget build(BuildContext context) {
    if (gaps.isEmpty) return const SizedBox.shrink();
    return NamiCareSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NamiCareSectionTitle(
            title: 'Dữ liệu cần bổ sung',
            subtitle: 'Nabi không tự tạo số cho phần dữ liệu còn thiếu.',
          ),
          const SizedBox(height: AppSpacing.md),
          NamiCareInfoTile(
            icon: Icons.data_usage_rounded,
            color: AppColors.warning,
            title: '${gaps.length} khoảng trống dữ liệu',
            subtitle: gaps.take(6).map((item) => '• $item').join('\n'),
          ),
        ],
      ),
    );
  }
}
