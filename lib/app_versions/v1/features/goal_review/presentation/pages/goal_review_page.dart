import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/notification_care/providers/notification_care_providers.dart';
import 'package:nano_app/core/constants/onboarding_constants.dart';
import 'package:nano_app/core/theme/theme.dart';

class GoalReviewPage extends ConsumerStatefulWidget {
  const GoalReviewPage({super.key});

  @override
  ConsumerState<GoalReviewPage> createState() => _GoalReviewPageState();
}

class _GoalReviewPageState extends ConsumerState<GoalReviewPage> {
  final Set<String> _selected = {};
  String? _initializedActor;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(goalReviewControllerProvider);
    return MedicalPageScaffold(
      backgroundColor: context.semanticColors.background,
      appBar: AppBar(title: const Text('Xem lại mục tiêu')),
      body: SafeArea(
        top: false,
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: OutlinedButton.icon(
              onPressed: () => ref.invalidate(goalReviewControllerProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ),
          data: (data) {
            if (_initializedActor != data.actorKey) {
              _initializedActor = data.actorKey;
              _selected
                ..clear()
                ..addAll(data.selectedGoalCodes);
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.md,
                AppSpacing.pagePadding,
                AppSpacing.xxxl,
              ),
              children: [
                Text('Mục tiêu hiện tại còn phù hợp không?',
                    style: AppTextStyles.heading2),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Bạn có thể chọn lại các mục tiêu từ hồ sơ ban đầu. Các mục tiêu nâng cao khác vẫn được giữ nguyên.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.semanticColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final option in OnboardingCatalog.goals)
                      FilterChip(
                        label: Text('${option.emoji} ${option.label}'),
                        selected: _selected.contains(option.code),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selected.add(option.code);
                            } else {
                              _selected.remove(option.code);
                            }
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: _selected.isEmpty ? null : _submit,
                  icon: const Icon(Icons.flag_rounded),
                  label: Text('Lưu ${_selected.length} mục tiêu'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _submit() async {
    await ref
        .read(goalReviewControllerProvider.notifier)
        .submit(Set.unmodifiable(_selected));
    if (!mounted) return;
    final result = ref.read(goalReviewControllerProvider);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result.hasError
                ? 'Nabi chưa cập nhật được mục tiêu. Bạn thử lại nhé.'
                : 'Mục tiêu sức khỏe của bạn đã được cập nhật.',
          ),
        ),
      );
  }
}
