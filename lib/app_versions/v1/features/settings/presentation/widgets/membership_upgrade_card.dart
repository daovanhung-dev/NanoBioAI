import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';

class MembershipUpgradeCard extends StatelessWidget {
  const MembershipUpgradeCard({
    required this.isAuthenticated,
    required this.onPressed,
    super.key,
  });

  final bool isAuthenticated;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final subtitle = isAuthenticated
        ? 'Khám phá Plus & FamilyPlus, nâng cấp hoặc gia hạn gói của bạn.'
        : 'Đăng nhập để khám phá Plus & FamilyPlus và các quyền lợi thành viên.';
    final actionLabel = isAuthenticated ? 'Xem gói' : 'Đăng nhập';

    return SizedBox(
      key: const Key('settings_membership_upgrade_card'),
      width: double.infinity,
      child: Semantics(
        container: true,
        label: isAuthenticated
            ? 'Nâng cấp hoặc gia hạn gói Plus và FamilyPlus'
            : 'Đăng nhập để nâng cấp gói Plus hoặc FamilyPlus',
        child: MedicalSurfaceCard(
          padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
          borderColor: AppColors.primary.withValues(alpha: .24),
          elevated: true,
          radius: AppRadius.xxl,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useHorizontalAction = constraints.maxWidth >= 520;

              final content = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MedicalIconBadge(
                    icon: Icons.workspace_premium_rounded,
                    color: AppColors.primaryDark,
                    backgroundColor: AppColors.primarySoft,
                    size: 52,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nâng cấp VIP',
                          style: AppTextStyles.heading3.copyWith(
                            color: context.semanticColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          subtitle,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: context.semanticColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final actionButton = FilledButton.icon(
                key: const Key('settings_membership_upgrade_button'),
                onPressed: onPressed,
                icon: Icon(
                  isAuthenticated
                      ? Icons.arrow_forward_rounded
                      : Icons.login_rounded,
                ),
                label: Text(actionLabel),
              );

              if (useHorizontalAction) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: content),
                    const SizedBox(width: AppSpacing.lg),
                    actionButton,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  content,
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  SizedBox(width: double.infinity, child: actionButton),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
