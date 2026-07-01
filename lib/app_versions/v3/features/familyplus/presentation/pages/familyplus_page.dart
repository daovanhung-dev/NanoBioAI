import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v2/router/v2_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../domain/entities/familyplus_models.dart';
import '../../providers/familyplus_providers.dart';

class FamilyPlusPage extends ConsumerWidget {
  const FamilyPlusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(familyPlusContextProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('FamilyPlus'),
        actions: [
          IconButton(
            tooltip: 'Tai lai',
            onPressed: () => ref.invalidate(familyPlusContextProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const _SupportState(
            icon: Icons.cloud_off_rounded,
            title: 'Chua tai duoc FamilyPlus',
            message: 'Hay thu lai sau it phut.',
          ),
          data: (model) => _FamilyPlusBody(model: model),
        ),
      ),
    );
  }
}

class _FamilyPlusBody extends ConsumerWidget {
  final FamilyPlusViewModel model;

  const _FamilyPlusBody({required this.model});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (model.status) {
      case FamilyPlusViewStatus.authRequired:
        return _SupportState(
          icon: Icons.lock_outline_rounded,
          title: 'Can dang nhap',
          message: model.message,
          actionLabel: 'Dang nhap',
          onAction: () => context.go(V2RoutePaths.login),
        );
      case FamilyPlusViewStatus.locked:
        return _SupportState(
          icon: Icons.workspace_premium_outlined,
          title: 'Danh cho FamilyPlus',
          message: model.message,
        );
      case FamilyPlusViewStatus.empty:
        return _EmptyFamilyState(contextModel: model.context!);
      case FamilyPlusViewStatus.ready:
        return _ReadyFamilyState(contextModel: model.context!);
      case FamilyPlusViewStatus.failure:
        return _SupportState(
          icon: Icons.error_outline_rounded,
          title: 'Chua san sang',
          message: model.message,
        );
    }
  }
}

class _EmptyFamilyState extends ConsumerWidget {
  final FamilyPlusContext contextModel;

  const _EmptyFamilyState({required this.contextModel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _PagePadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quan ly gia dinh', style: AppTextStyles.heading1),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tao nhom FamilyPlus dau tien de them thanh vien va chon ho so can xem.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: contextModel.canManage
                  ? () => ref.read(familyPlusCreateDefaultGroupProvider)()
                  : null,
              icon: const Icon(Icons.group_add_rounded),
              label: const Text('Tao nhom FamilyPlus'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyFamilyState extends ConsumerWidget {
  final FamilyPlusContext contextModel;

  const _ReadyFamilyState({required this.contextModel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = contextModel.activeMembers;
    return _PagePadding(
      child: ListView(
        children: [
          Text(
            contextModel.group?.displayName ?? 'FamilyPlus',
            style: AppTextStyles.heading1,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${members.length}/$familyPlusMaxMembers thanh vien dang hoat dong',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      child: ListTile(
        leading: Icon(
          selected ? Icons.check_circle_rounded : Icons.person_outline_rounded,
          color: selected ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Text(member.displayName, style: AppTextStyles.labelLarge),
        subtitle: Text(
          '${member.role} - ${member.canEdit ? 'xem/sua' : 'chi xem'}',
        ),
        trailing: IconButton(
          tooltip: 'Chon ho so',
          onPressed: member.canView
              ? () => ref.read(familyPlusSwitchSubjectProvider)(
                  contextModel,
                  member.subjectId,
                )
              : null,
          icon: const Icon(Icons.switch_account_rounded),
        ),
      ),
    );
  }
}

class _SupportState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SupportState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return _PagePadding(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.primary),
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
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
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
