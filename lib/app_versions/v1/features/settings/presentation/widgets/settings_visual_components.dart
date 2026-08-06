import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';

/// Presentation-only building blocks for the Settings surface.
///
/// Persistence and account actions remain owned by the existing
/// providers/controllers. These widgets only standardize hierarchy,
/// responsive behavior, accessibility, and interaction affordances.
class SettingsPageHeader extends StatelessWidget {
  const SettingsPageHeader({
    required this.isLoading,
    super.key,
  });

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    final canPop = navigator.canPop();

    return Semantics(
      header: true,
      container: true,
      label: 'Cài đặt và quyền riêng tư',
      child: MedicalSurfaceCard(
        padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
        gradient: AppGradients.hero,
        elevated: true,
        radius: AppRadius.xxl,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 460;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (canPop) ...[
                      Semantics(
                        button: true,
                        label: 'Quay lại',
                        child: IconButton(
                          tooltip: 'Quay lại',
                          onPressed: navigator.maybePop,
                          style: IconButton.styleFrom(
                            backgroundColor:
                                AppColors.surface.withValues(alpha: .16),
                            foregroundColor: AppColors.surface,
                          ),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CÀI ĐẶT & QUYỀN RIÊNG TƯ',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.surface.withValues(alpha: .82),
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Cài đặt',
                            style: AppTextStyles.heading2.copyWith(
                              color: AppColors.surface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            isLoading
                                ? 'Nabi đang mở lại các lựa chọn của bạn...'
                                : 'Quản lý tài khoản, dữ liệu và trải nghiệm ứng dụng tại một nơi.',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.surface.withValues(alpha: .9),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(width: AppSpacing.md),
                      MedicalIconBadge(
                        icon: Icons.tune_rounded,
                        color: AppColors.surface,
                        backgroundColor:
                            AppColors.surface.withValues(alpha: .16),
                        size: 52,
                      ),
                    ],
                  ],
                ),
                if (isLoading) ...[
                  const SizedBox(height: AppSpacing.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.circular),
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      color: AppColors.surface,
                      backgroundColor:
                          AppColors.surface.withValues(alpha: .18),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      container: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MedicalIconBadge(
            icon: icon,
            color: AppColors.primaryDark,
            backgroundColor: AppColors.primarySoft,
            size: 40,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
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

class SettingsMenuCard extends StatelessWidget {
  const SettingsMenuCard({
    required this.children,
    super.key,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return MedicalSurfaceCard(
      padding: EdgeInsets.zero,
      borderColor: AppColors.borderLight,
      elevated: false,
      radius: AppRadius.xxl,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        child: Column(children: children),
      ),
    );
  }
}

class SettingsMenuItem extends StatelessWidget {
  const SettingsMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor = AppColors.primaryDark,
    this.iconBackgroundColor = AppColors.primarySoft,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color iconColor;
  final Color iconBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 78),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            MedicalIconBadge(
              icon: icon,
              color: iconColor,
              backgroundColor: iconBackgroundColor,
              size: 46,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ] else if (onTap != null) ...[
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 17,
                color: AppColors.textHint,
              ),
            ],
          ],
        ),
      ),
    );

    return Semantics(
      container: true,
      button: onTap != null,
      enabled: onTap != null || trailing != null,
      label: '$title. $subtitle',
      child: onTap == null
          ? content
          : Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                child: content,
              ),
            ),
    );
  }
}

class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 76),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppColors.borderLight,
      ),
    );
  }
}

class SettingsStatusBanner extends StatelessWidget {
  const SettingsStatusBanner({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      label: message,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.errorSoft,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: AppColors.error.withValues(alpha: .18),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 430;
            final messageContent = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MedicalIconBadge(
                  icon: Icons.info_outline_rounded,
                  color: AppColors.error,
                  backgroundColor: AppColors.surface.withValues(alpha: .72),
                  size: 42,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    message,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            );

            final retry = TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  messageContent,
                  const SizedBox(height: AppSpacing.sm),
                  Align(alignment: Alignment.centerRight, child: retry),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: messageContent),
                const SizedBox(width: AppSpacing.sm),
                retry,
              ],
            );
          },
        ),
      ),
    );
  }
}
