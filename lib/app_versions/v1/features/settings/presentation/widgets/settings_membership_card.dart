import 'package:flutter/material.dart';

import 'package:nano_app/core/theme/theme.dart';

enum SettingsMembershipCardState {
  loading,
  error,
  free,
  plus,
  familyPlus,
  unknown,
}

class SettingsMembershipCard extends StatelessWidget {
  final SettingsMembershipCardState state;
  final VoidCallback? onUpgrade;

  const SettingsMembershipCard({
    super.key,
    required this.state,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final content = _contentFor(state);
    final canUpgrade = content.actionLabel != null && onUpgrade != null;

    return MedicalSurfaceCard(
      key: const Key('settings_membership_card'),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MedicalIconBadge(
                icon: content.icon,
                color: AppColors.primaryDark,
                backgroundColor: AppColors.primarySoft,
                size: 48,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(content.title, style: AppTextStyles.labelLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      content.subtitle,
                      style: AppTextStyles.bodySmall.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (state == SettingsMembershipCardState.loading)
                const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  content.trailingIcon,
                  color: context.semanticColors.textHint,
                  size: 22,
                ),
            ],
          ),
          if (content.actionLabel != null) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                key: const Key('settings_membership_upgrade_button'),
                onPressed: canUpgrade
                    ? () {
                        AppFeedbackService.instance.emit(
                          AppFeedbackType.selection,
                        );
                        onUpgrade!();
                      }
                    : null,
                icon: const Icon(Icons.workspace_premium_rounded),
                label: Text(content.actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

_SettingsMembershipContent _contentFor(SettingsMembershipCardState state) {
  return switch (state) {
    SettingsMembershipCardState.loading => const _SettingsMembershipContent(
      title: 'Đang kiểm tra gói',
      subtitle: 'Nabi đang kiểm tra gói thành viên của bạn...',
      icon: Icons.workspace_premium_rounded,
      trailingIcon: Icons.hourglass_top_rounded,
    ),
    SettingsMembershipCardState.error => const _SettingsMembershipContent(
      title: 'Chưa kiểm tra được gói',
      subtitle: 'Kéo xuống để Nabi thử cập nhật trạng thái gói một lần nữa.',
      icon: Icons.workspace_premium_rounded,
      trailingIcon: Icons.info_outline_rounded,
    ),
    SettingsMembershipCardState.free => const _SettingsMembershipContent(
      title: 'Gói Miễn phí',
      subtitle: 'Nâng cấp Plus để mở thêm quyền lợi khi bạn cần.',
      icon: Icons.verified_user_rounded,
      trailingIcon: Icons.arrow_upward_rounded,
      actionLabel: 'Nâng cấp Plus',
    ),
    SettingsMembershipCardState.plus => const _SettingsMembershipContent(
      title: 'Gói Plus',
      subtitle:
          'Plus đang hoạt động. Bạn có thể nâng cấp FamilyPlus cho nhu cầu gia đình.',
      icon: Icons.workspace_premium_rounded,
      trailingIcon: Icons.arrow_upward_rounded,
      actionLabel: 'Nâng cấp FamilyPlus',
    ),
    SettingsMembershipCardState.familyPlus =>
      const _SettingsMembershipContent(
        title: 'Gói FamilyPlus',
        subtitle: 'Gói cao nhất hiện đang hoạt động trên tài khoản này.',
        icon: Icons.family_restroom_rounded,
        trailingIcon: Icons.check_circle_rounded,
      ),
    SettingsMembershipCardState.unknown => const _SettingsMembershipContent(
      title: 'Gói thành viên',
      subtitle:
          'Nabi chưa xác định được gói hiện tại. Kéo xuống để cập nhật lại.',
      icon: Icons.workspace_premium_rounded,
      trailingIcon: Icons.help_outline_rounded,
    ),
  };
}

class _SettingsMembershipContent {
  final String title;
  final String subtitle;
  final IconData icon;
  final IconData trailingIcon;
  final String? actionLabel;

  const _SettingsMembershipContent({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.trailingIcon,
    this.actionLabel,
  });
}
