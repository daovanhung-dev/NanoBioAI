import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart';

class WaterTrackingPage extends StatefulWidget {
  const WaterTrackingPage({super.key});

  @override
  State<WaterTrackingPage> createState() => _WaterTrackingPageState();
}

class _WaterTrackingPageState extends State<WaterTrackingPage> {
  static const int _goalMl = 2000;
  int _currentMl = 0;

  void _addWater(int amount) {
    setState(() {
      _currentMl = (_currentMl + amount).clamp(0, _goalMl);
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentMl / _goalMl).clamp(0.0, 1.0);

    return NamiCareScaffold(
      title: 'Uống nước hôm nay',
      subtitle: 'Từng ngụm nhỏ cũng là cách bạn chăm cơ thể rồi.',
      badge: 'Nhẹ nhàng từng chút',
      icon: Icons.water_drop_rounded,
      gradient: AppGradients.info,
      children: [
        NamiCareSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hôm nay mình đã uống',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '$_currentMl ml',
                style: AppTextStyles.displaySmall.copyWith(
                  color: AppColors.info,
                  fontWeight: AppTypography.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.circular),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: AppColors.info.withValues(alpha: .1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.info,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Mục tiêu dịu nhẹ: $_goalMl ml',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: AppTypography.medium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const NamiCareSectionTitle(
          title: 'Thêm một ly nhỏ',
          subtitle:
              'Chọn nhanh lượng nước vừa uống, Nabi sẽ ghi lại giúp bạn trong phiên này.',
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            NamiCareActionChip(
              label: '+100 ml',
              icon: Icons.add_rounded,
              color: AppColors.info,
              onTap: () => _addWater(100),
            ),
            NamiCareActionChip(
              label: '+250 ml',
              icon: Icons.add_rounded,
              color: AppColors.info,
              onTap: () => _addWater(250),
            ),
            NamiCareActionChip(
              label: '+500 ml',
              icon: Icons.add_rounded,
              color: AppColors.info,
              onTap: () => _addWater(500),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        NamiCareEmptyState(
          icon: Icons.notifications_active_rounded,
          color: AppColors.info,
          title: 'Nabi nhắc mình uống nước',
          message: _currentMl == 0
              ? 'Nabi chưa ghi nhận ly nước nào hôm nay. Mình bắt đầu bằng một ngụm nhỏ nhé.'
              : 'Từng ngụm nhỏ đang giúp cơ thể dễ chịu hơn rồi. Nabi sẽ tiếp tục nhắc bạn thật nhẹ nhàng.',
        ),
      ],
    );
  }
}
