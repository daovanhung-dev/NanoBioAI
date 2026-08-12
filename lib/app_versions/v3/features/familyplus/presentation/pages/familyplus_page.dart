import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v2/router/v2_route_paths.dart';
import 'package:nano_app/core/membership/membership_upgrade_route.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/shared/membership/presentation/membership_upgrade_navigation.dart';
import 'package:nano_app/shared/widgets/vietnamese_ui_text.dart';

import '../../domain/entities/familyplus_models.dart';
import '../../providers/familyplus_providers.dart';

class FamilyPlusPage extends ConsumerWidget {
  const FamilyPlusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(familyPlusContextProvider);
    final colors = context.semanticColors;
    return MedicalPageScaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('FamilyPlus'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: () async {
              AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
              try {
                final refreshed = await ref.refresh(
                  familyPlusContextProvider.future,
                );
                AppFeedbackService.instance.emit(
                  refreshed.status == FamilyPlusViewStatus.failure
                      ? AppFeedbackType.error
                      : AppFeedbackType.success,
                );
              } catch (_) {
                AppFeedbackService.instance.emit(AppFeedbackType.error);
              }
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: AppStateSwitcher(
          child: state.when(
            loading: () => const Center(
              key: ValueKey<String>('familyplus-loading'),
              child: CircularProgressIndicator(),
            ),
            error: (_, __) => const _SupportState(
              key: ValueKey<String>('familyplus-error'),
              icon: Icons.cloud_off_rounded,
              title: 'Chưa tải được FamilyPlus',
              message: 'Hãy thử lại sau ít phút.',
            ),
            data: (model) => _FamilyPlusBody(
              key: ValueKey<String>('familyplus-${model.status.name}'),
              model: model,
            ),
          ),
        ),
      ),
    );
  }
}

class _FamilyPlusBody extends ConsumerWidget {
  final FamilyPlusViewModel model;

  const _FamilyPlusBody({super.key, required this.model});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppStateSwitcher(
      child: switch (model.status) {
        FamilyPlusViewStatus.authRequired => _SupportState(
          key: const ValueKey<String>('familyplus-auth-required'),
          icon: Icons.lock_outline_rounded,
          title: 'Cần đăng nhập',
          message: vietnameseSystemUiText(
            model.message,
            fallback: 'Bạn thử lại sau ít phút.',
          ),
          actionLabel: 'Đăng nhập',
          onAction: () => context.push(V2RoutePaths.login),
        ),
        FamilyPlusViewStatus.locked => _SupportState(
          key: const ValueKey<String>('familyplus-locked'),
          icon: Icons.workspace_premium_outlined,
          title: 'Dành cho FamilyPlus',
          message: vietnameseSystemUiText(
            model.message,
            fallback: 'Bạn thử lại sau ít phút.',
          ),
          actionLabel: membershipUpgradeActionLabel(
            MembershipUpgradePlan.familyPlus,
          ),
          onAction: () {
            AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
            openMembershipUpgrade(
              context,
              planCode: MembershipUpgradePlan.familyPlus,
            );
          },
        ),
        FamilyPlusViewStatus.empty => _EmptyFamilyState(
          key: const ValueKey<String>('familyplus-empty'),
          contextModel: model.context!,
        ),
        FamilyPlusViewStatus.ready => _ReadyFamilyState(
          key: const ValueKey<String>('familyplus-ready'),
          contextModel: model.context!,
        ),
        FamilyPlusViewStatus.failure => _SupportState(
          key: const ValueKey<String>('familyplus-failure'),
          icon: Icons.error_outline_rounded,
          title: 'Chưa sẵn sàng',
          message: vietnameseSystemUiText(
            model.message,
            fallback: 'Bạn thử lại sau ít phút.',
          ),
        ),
      },
    );
  }
}

class _EmptyFamilyState extends ConsumerWidget {
  final FamilyPlusContext contextModel;

  const _EmptyFamilyState({super.key, required this.contextModel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.semanticColors;
    return _PagePadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quản lý gia đình', style: AppTextStyles.heading1),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tạo nhóm FamilyPlus đầu tiên để thêm thành viên và chọn hồ sơ cần xem.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.textSecondary,
              height: 1.45,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: contextModel.canManage
                  ? () async {
                      AppFeedbackService.instance.emit(
                        AppFeedbackType.primaryAction,
                      );
                      try {
                        await ref.read(familyPlusCreateDefaultGroupProvider)();
                        if (context.mounted) {
                          AppFeedbackService.instance.emit(
                            AppFeedbackType.success,
                          );
                        }
                      } catch (_) {
                        if (!context.mounted) return;
                        AppFeedbackService.instance.emit(AppFeedbackType.error);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Chưa tạo được nhóm FamilyPlus. Bạn thử lại sau.',
                            ),
                          ),
                        );
                      }
                    }
                  : null,
              icon: const Icon(Icons.group_add_rounded),
              label: const Text('Tạo nhóm FamilyPlus'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyFamilyState extends ConsumerWidget {
  final FamilyPlusContext contextModel;

  const _ReadyFamilyState({super.key, required this.contextModel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = contextModel.activeMembers;
    final colors = context.semanticColors;
    return _PagePadding(
      child: ListView(
        children: [
          Text(
            vietnameseUiText(
              contextModel.group?.displayName,
              fallback: 'FamilyPlus',
            ),
            style: AppTextStyles.heading1,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${members.length}/$familyPlusMaxMembers thành viên đang hoạt động',
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          for (final member in members)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _MemberTile(contextModel: contextModel, member: member),
            ),
        ],
      ),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  final FamilyPlusContext contextModel;
  final FamilyPlusMember member;

  const _MemberTile({required this.contextModel, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = contextModel.selectedSubjectId == member.subjectId;
    final colors = context.semanticColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: selected ? colors.primary : colors.border),
      ),
      child: ListTile(
        leading: Icon(
          selected ? Icons.check_circle_rounded : Icons.person_outline_rounded,
          color: selected ? colors.primary : colors.textSecondary,
        ),
        title: Text(
          vietnameseUiText(member.displayName, fallback: 'Thành viên'),
          style: AppTextStyles.labelLarge,
        ),
        subtitle: Text(
          '${_familyRoleLabel(member.role)} - ${member.canEdit ? 'xem/sửa' : 'chỉ xem'}',
        ),
        trailing: IconButton(
          tooltip: 'Chọn hồ sơ',
          onPressed: member.canView
              ? () {
                  try {
                    ref.read(familyPlusSwitchSubjectProvider)(
                      contextModel,
                      member.subjectId,
                    );
                    AppFeedbackService.instance.emit(AppFeedbackType.selection);
                  } catch (_) {
                    AppFeedbackService.instance.emit(AppFeedbackType.error);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Chưa chuyển được hồ sơ. Bạn vui lòng thử lại.',
                        ),
                      ),
                    );
                  }
                }
              : null,
          icon: const Icon(Icons.switch_account_rounded),
        ),
      ),
    );
  }
}

String _familyRoleLabel(String role) {
  switch (role.trim().toLowerCase()) {
    case 'owner':
    case 'admin':
      return 'Người quản lý';
    case 'member':
      return 'Thành viên';
    case 'dependent':
      return 'Người được chăm sóc';
    default:
      return 'Thành viên gia đình';
  }
}

class _SupportState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SupportState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return _PagePadding(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: colors.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.textSecondary,
              height: 1.45,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.sectionSpacing),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _PagePadding extends StatelessWidget {
  final Widget child;

  const _PagePadding({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: child,
    );
  }
}
