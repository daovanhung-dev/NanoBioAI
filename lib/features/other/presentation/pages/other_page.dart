import 'package:flutter/material.dart';

import 'package:nano_app/core/theme/theme.dart';

class HealthInsightsView extends StatelessWidget {
  const HealthInsightsView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildAiSummaryCard(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildTodayOverview(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildHealthScore(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildInsightSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildRecommendationSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildTrackingGrid(size),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xin chào Hùng 👋',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Phân tích sức khỏe AI',
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
            colors: const [
              AppColors.primary,
              AppColors.secondary,
            ],
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

  Widget _buildAiSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecoration.gradient(
        colors: const [
          Color(0xFF2563EB),
          Color(0xFF06B6D4),
        ],
        radius: AppRadius.xl,
        shadows: AppShadows.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.18),
              borderRadius: BorderRadius.circular(AppRadius.circular),
            ),
            child: Text(
              'AI HEALTH REPORT',
              style: AppTextStyles.labelMedium.copyWith(
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Cơ thể của bạn đang có xu hướng phục hồi tốt.',
            style: AppTextStyles.heading2.copyWith(
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'AI phát hiện chất lượng giấc ngủ và lượng nước đã cải thiện đáng kể trong 7 ngày gần đây.',
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.white.withOpacity(.9),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  icon: Icons.favorite_rounded,
                  title: 'Nhịp tim',
                  value: '72 BPM',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildInfoChip(
                  icon: Icons.bolt_rounded,
                  title: 'Năng lượng',
                  value: 'Tốt',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.14),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              icon,
              color: Colors.white,
            ),
          ),
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
                  style: AppTextStyles.heading4.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayOverview() {
    return Row(
      children: [
        Expanded(
          child: _buildOverviewCard(
            title: 'Calories',
            value: '1,840',
            unit: 'kcal',
            icon: Icons.local_fire_department_rounded,
            color: AppColors.warning,
            bg: AppColors.warningSoft,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildOverviewCard(
            title: 'Nước',
            value: '2.4',
            unit: 'L',
            icon: Icons.water_drop_rounded,
            color: AppColors.info,
            bg: AppColors.infoSoft,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecoration.card(
        radius: AppRadius.xl,
        shadows: AppShadows.sm,
      ),
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
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: AppTextStyles.heading2.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScore() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecoration.card(
        radius: AppRadius.xxl,
        shadows: AppShadows.soft,
      ),
      child: Row(
        children: [
          SizedBox(
            height: 120,
            width: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 120,
                  width: 120,
                  child: CircularProgressIndicator(
                    value: 0.86,
                    strokeWidth: 10,
                    backgroundColor: AppColors.borderLight,
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.success,
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '86',
                      style: AppTextStyles.displaySmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Điểm AI',
                      style: AppTextStyles.bodySmall,
                    ),
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
                Text(
                  'Tình trạng sức khỏe',
                  style: AppTextStyles.heading3,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Bạn đang duy trì trạng thái ổn định. Hãy tiếp tục ngủ đúng giờ và tăng vận động nhẹ mỗi ngày.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successSoft,
                    borderRadius: BorderRadius.circular(AppRadius.circular),
                  ),
                  child: Text(
                    'Ổn định & tích cực',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.success,
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

  Widget _buildInsightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Insights',
          style: AppTextStyles.heading3.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildInsightCard(
          icon: Icons.bedtime_rounded,
          color: AppColors.primary,
          bg: AppColors.primarySoft,
          title: 'Giấc ngủ cải thiện',
          description:
              'Thời lượng ngủ trung bình tăng thêm 1.2 giờ trong tuần này.',
        ),
        const SizedBox(height: AppSpacing.md),
        _buildInsightCard(
          icon: Icons.restaurant_rounded,
          color: AppColors.warning,
          bg: AppColors.warningSoft,
          title: 'Dinh dưỡng chưa cân bằng',
          description:
              'AI phát hiện lượng protein đang thấp hơn mức khuyến nghị.',
        ),
      ],
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required Color color,
    required Color bg,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecoration.card(
        radius: AppRadius.xl,
        shadows: AppShadows.sm,
      ),
      child: Row(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.heading4,
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Đề xuất hôm nay',
          style: AppTextStyles.heading3,
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: AppDecoration.gradient(
            colors: const [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
            ],
            radius: AppRadius.xxl,
            shadows: AppShadows.lg,
          ),
          child: Column(
            children: [
              _buildRecommendationItem(
                icon: Icons.water_drop_rounded,
                title: 'Uống thêm nước',
                subtitle: 'Bạn còn thiếu khoảng 600ml hôm nay',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildRecommendationItem(
                icon: Icons.directions_walk_rounded,
                title: 'Đi bộ nhẹ 20 phút',
                subtitle: 'Giúp cải thiện tiêu hóa và giấc ngủ',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildRecommendationItem(
                icon: Icons.self_improvement_rounded,
                title: 'Thiền thư giãn',
                subtitle: 'Giảm stress và cải thiện tập trung',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          height: 54,
          width: 54,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.08),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Icon(
            icon,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingGrid(Size size) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: size.width < 700 ? 2 : 4,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1,
      children: [
        _buildTrackingCard(
          title: 'Stress',
          value: 'Low',
          icon: Icons.psychology_rounded,
          color: AppColors.secondary,
        ),
        _buildTrackingCard(
          title: 'Ngủ',
          value: '7.8h',
          icon: Icons.bedtime_rounded,
          color: AppColors.primary,
        ),
        _buildTrackingCard(
          title: 'Steps',
          value: '8,420',
          icon: Icons.directions_walk_rounded,
          color: AppColors.success,
        ),
        _buildTrackingCard(
          title: 'BMI',
          value: '22.1',
          icon: Icons.monitor_weight_rounded,
          color: AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildTrackingCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecoration.card(
        radius: AppRadius.xl,
        shadows: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppShadows.sm,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: AppIcons.home,
            label: 'Trang chủ',
            active: true,
          ),
          _buildNavItem(
            icon: AppIcons.health,
            label: 'Sức khỏe',
          ),
          _buildNavItem(
            icon: AppIcons.nutrition,
            label: 'Dinh dưỡng',
          ),
          _buildNavItem(
            icon: AppIcons.profile,
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    bool active = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: active ? AppColors.primary : AppColors.textHint,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: active ? AppColors.primary : AppColors.textHint,
          ),
        ),
      ],
    );
  }
}