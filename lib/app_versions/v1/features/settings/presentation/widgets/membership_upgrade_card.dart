import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/providers/membership_entitlement_providers.dart';
import 'package:nano_app/core/membership/membership_upgrade_route.dart';
import 'package:nano_app/core/theme/theme.dart';

class MembershipUpgradeCard extends ConsumerWidget {
  const MembershipUpgradeCard({
    required this.isAuthenticated,
    required this.onPressed,
    super.key,
  });

  final bool isAuthenticated;

  /// Legacy fallback for callers mounted outside a GoRouter tree.
  /// Normal membership navigation uses the canonical membership route helper.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isAuthenticated) {
      return const SizedBox.shrink();
    }

    final accessAsync = ref.watch(effectiveAccessProvider);
    return accessAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (access) {
        if (access == null || access.isGuest) {
          return const SizedBox.shrink();
        }

        if (access.isFree) {
          return _UpgradePlusCard(
            onPressed: () => _openPlan(
              context,
              MembershipUpgradePlan.plus,
            ),
          );
        }

        if (access.isPlus) {
          return _MembershipRenewalAction(
            title: 'Gia hạn gói Plus',
            onPressed: () => _openPlan(
              context,
              MembershipUpgradePlan.plus,
            ),
          );
        }

        if (access.isFamilyPlus) {
          return _MembershipRenewalAction(
            title: 'Gia hạn gói FamilyPlus',
            onPressed: () => _openPlan(
              context,
              MembershipUpgradePlan.familyPlus,
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _openPlan(BuildContext context, String planCode) {
    try {
      context.push(buildMembershipUpgradeRoute(planCode));
    } catch (_) {
      onPressed();
    }
  }
}

class _UpgradePlusCard extends StatelessWidget {
  const _UpgradePlusCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('settings_membership_upgrade_card'),
      width: double.infinity,
      child: Semantics(
        container: true,
        label: 'Nâng cấp gói Plus',
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
                          'Mở thêm quyền lợi với gói Plus khi bạn cần.',
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
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Nâng cấp Plus'),
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

class _MembershipRenewalAction extends StatelessWidget {
  const _MembershipRenewalAction({
    required this.title,
    required this.onPressed,
  });

  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('settings_membership_renew_button'),
      width: double.infinity,
      child: MedicalSurfaceCard(
        padding: EdgeInsets.zero,
        elevated: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: () {
            AppFeedbackService.instance.emit(AppFeedbackType.selection);
            onPressed();
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Row(
              children: [
                MedicalIconBadge(
                  icon: Icons.autorenew_rounded,
                  color: AppColors.primaryDark,
                  backgroundColor: AppColors.primarySoft,
                  size: 48,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.labelLarge),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Gia hạn thêm thời gian sử dụng gói hiện tại',
                        style: AppTextStyles.bodySmall.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: context.semanticColors.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
