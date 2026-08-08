import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';

/// Hub chăm sóc chỉ mở các năng lực đã có trong runtime.
///
/// Mẫu Stitch có nội dung premium/chuyên gia, nhưng runtime hiện chưa có
/// contract đặt lịch hoặc chuyên gia. Trang này vì thế chỉ là hub điều
/// hướng tới các công cụ wellness local đã sẵn sàng.
class NamiCarePage extends StatelessWidget {
  const NamiCarePage({super.key});

  static const _availableCare = <_NamiCareDestination>[
    _NamiCareDestination(
      title: 'Uống nước',
      subtitle: 'Ghi lại từng lần uống theo mục tiêu bạn tự chọn.',
      icon: Icons.water_drop_rounded,
      color: AppColors.info,
      route: V1RoutePaths.waterTracking,
      status: 'Lưu trên máy',
    ),
    _NamiCareDestination(
      title: 'Mục tiêu cá nhân',
      subtitle: 'Xem trước một việc nhỏ, vừa sức cho hôm nay.',
      icon: Icons.flag_rounded,
      color: AppColors.success,
      route: V1RoutePaths.personalGoals,
      status: 'Xem trước',
    ),
    _NamiCareDestination(
      title: 'Chăm mình 5 phút',
      subtitle: 'Các bài tự chăm sóc ngắn, không dùng AI.',
      icon: Icons.spa_rounded,
      color: AppColors.secondary,
      route: V1RoutePaths.quickCare,
      status: 'Bài cố định',
    ),
    _NamiCareDestination(
      title: 'Chế độ dịu nhẹ',
      subtitle: 'Giảm nhịp và chọn gợi ý wellness tại chỗ.',
      icon: Icons.nights_stay_rounded,
      color: AppColors.warning,
      route: V1RoutePaths.gentleCare,
      status: 'Bài cố định',
    ),
    _NamiCareDestination(
      title: 'Tổng kết tuần',
      subtitle: 'Chỉ tổng hợp khi đã có đủ ghi nhận thật trong tuần.',
      icon: Icons.insights_rounded,
      color: AppColors.primary,
      route: V1RoutePaths.weeklySummary,
      status: 'Chờ dữ liệu',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return NamiCareScaffold(
      title: 'Nami Care',
      subtitle: 'Một nơi để bạn chọn cách chăm sóc nhỏ, rõ ràng và vừa sức.',
      badge: 'Cùng Nabi chăm mình',
      icon: Icons.health_and_safety_rounded,
      gradient: AppGradients.success,
      children: [
        const NamiCareEmptyState(
          icon: Icons.favorite_rounded,
          color: AppColors.primary,
          title: 'Chọn một bước chăm sóc phù hợp',
          message:
              'Nami Care nói rõ công cụ nào lưu local, công cụ nào chỉ xem trước hoặc đang chờ dữ liệu thật. Không có chuyên gia, đặt lịch hay kết quả mẫu.',
        ),
        const SizedBox(height: AppSpacing.sectionSpacing),
        const NamiCareSectionTitle(
          title: 'Công cụ hiện có',
          subtitle:
              'Các mục dưới đây không tự đưa ra chẩn đoán; xem nhãn trạng thái trước khi bắt đầu.',
        ),
        const SizedBox(height: AppSpacing.md),
        for (final destination in _availableCare)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: NamiCareInfoTile(
              icon: destination.icon,
              color: destination.color,
              title: destination.title,
              subtitle: destination.subtitle,
              trailing: destination.status,
              onTap: () => context.push(destination.route),
            ),
          ),
      ],
    );
  }
}

class _NamiCareDestination {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  final String status;

  const _NamiCareDestination({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    required this.status,
  });
}

class NamiCareScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final LinearGradient gradient;
  final List<Widget> children;

  const NamiCareScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.gradient,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return MedicalPageScaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth >= 720
                ? AppSpacing.xl
                : AppSpacing.md;
            return CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontal,
                    AppSpacing.md,
                    horizontal,
                    128,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _NamiCareHeader(
                              title: title,
                              subtitle: subtitle,
                              badge: badge,
                              icon: icon,
                              gradient: gradient,
                            ),
                            const SizedBox(height: AppSpacing.sectionSpacing),
                            ...children,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class NamiCareSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;

  const NamiCareSurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return MedicalSurfaceCard(
      padding: padding ?? const EdgeInsets.all(AppSpacing.pagePaddingLarge),
      borderColor: borderColor,
      child: child,
    );
  }
}

class NamiCareSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const NamiCareSectionTitle({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return MedicalSectionHeader(title: title, subtitle: subtitle);
  }
}

class NamiCareInfoTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? trailing;
  final bool selected;
  final VoidCallback? onTap;

  const NamiCareInfoTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final tone = _resolveSemanticTone(colors, color);
    final tile = AnimatedContainer(
      duration: AppDuration.fast,
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: selected ? tone.withValues(alpha: .08) : colors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: selected ? tone.withValues(alpha: .32) : colors.borderLight,
        ),
        boxShadow: selected ? AppShadows.sm : AppShadows.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: tone, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: colors.textPrimary,
                    fontWeight: AppTypography.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: tone.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(AppRadius.circular),
              ),
              child: Text(
                trailing!,
                style: AppTextStyles.caption.copyWith(
                  color: tone,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return tile;

    return AppPressScale(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: () {
            AppFeedbackService.instance.emit(AppFeedbackType.selection);
            onTap!();
          },
          child: tile,
        ),
      ),
    );
  }
}

class NamiCareActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool selected;

  const NamiCareActionChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final tone = _resolveSemanticTone(colors, color);
    return AppPressScale(
      enabled: onTap != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.circular),
          onTap: onTap == null
              ? null
              : () {
                  AppFeedbackService.instance.emit(AppFeedbackType.selection);
                  onTap!();
                },
          child: AnimatedContainer(
            duration: AppDuration.fast,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: selected ? tone.withValues(alpha: .14) : colors.card,
              borderRadius: BorderRadius.circular(AppRadius.circular),
              border: Border.all(
                color: selected
                    ? tone.withValues(alpha: .32)
                    : colors.borderLight,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: tone, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: selected ? tone : colors.textPrimary,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _resolveSemanticTone(AppSemanticColors colors, Color legacy) {
  if (legacy == AppColors.primary || legacy == AppColors.primaryDark) {
    return colors.primary;
  }
  if (legacy == AppColors.secondary || legacy == AppColors.secondaryDark) {
    return colors.secondary;
  }
  if (legacy == AppColors.tertiary) return colors.tertiary;
  if (legacy == AppColors.success) return colors.success;
  if (legacy == AppColors.warning) return colors.warning;
  if (legacy == AppColors.error) return colors.error;
  if (legacy == AppColors.info) return colors.info;
  return legacy;
}

class NamiCareEmptyState extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const NamiCareEmptyState({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return MedicalEmptyState(
      icon: icon,
      color: color,
      title: title,
      message: message,
    );
  }
}

class _NamiCareHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final LinearGradient gradient;

  const _NamiCareHeader({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.surface.withValues(alpha: .12)),
        boxShadow: AppShadows.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: AppColors.surface.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const SizedBox(
                    width: 46,
                    height: 46,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.surface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: AppColors.surface.withValues(alpha: .18),
                  ),
                ),
                child: Icon(icon, color: AppColors.surface, size: 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(AppRadius.circular),
                ),
                child: Text(
                  badge,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.surface,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          Text(
            title,
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.surface,
              fontWeight: AppTypography.bold,
              height: 1.22,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.surface.withValues(alpha: .92),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
