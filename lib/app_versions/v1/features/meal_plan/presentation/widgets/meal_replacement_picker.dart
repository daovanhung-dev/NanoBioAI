import 'package:flutter/material.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_replacement_entities.dart';
import 'package:nano_app/core/theme/theme.dart';

Future<MealReplacementResult?> showMealReplacementPicker({
  required BuildContext context,
  required Future<List<MealReplacementCandidateEntity>> candidatesFuture,
  required Future<MealReplacementResult> Function(
    MealReplacementCandidateEntity candidate,
  ) onConfirm,
}) {
  return showModalBottomSheet<MealReplacementResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MealReplacementPickerSheet(
      candidatesFuture: candidatesFuture,
      onConfirm: onConfirm,
    ),
  );
}

class MealReplacementPickerSheet extends StatefulWidget {
  const MealReplacementPickerSheet({
    required this.candidatesFuture,
    required this.onConfirm,
    super.key,
  });

  final Future<List<MealReplacementCandidateEntity>> candidatesFuture;
  final Future<MealReplacementResult> Function(
    MealReplacementCandidateEntity candidate,
  ) onConfirm;

  @override
  State<MealReplacementPickerSheet> createState() =>
      _MealReplacementPickerSheetState();
}

class _MealReplacementPickerSheetState
    extends State<MealReplacementPickerSheet> {
  MealReplacementCandidateEntity? _selected;
  bool _saving = false;
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: .82,
      minChildSize: .55,
      maxChildSize: .95,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: context.semanticColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Đổi món', style: AppTextStyles.heading2),
                        Text(
                          'Các món đã lọc theo hồ sơ và bữa ăn.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.semanticColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<MealReplacementCandidateEntity>>(
                future: widget.candidatesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const _PickerMessage(
                      icon: Icons.error_outline_rounded,
                      title: 'Chưa tải được danh sách món',
                      subtitle: 'Bạn đóng cửa sổ này và thử lại nhé.',
                    );
                  }
                  final candidates = snapshot.data ?? const [];
                  if (candidates.isEmpty) {
                    return const _PickerMessage(
                      icon: Icons.restaurant_menu_rounded,
                      title: 'Chưa có món thay thế phù hợp',
                      subtitle: 'Nabi sẽ giữ món hiện tại cho bạn.',
                    );
                  }
                  return ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pagePaddingLarge,
                    ),
                    itemCount: candidates.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final candidate = candidates[index];
                      final selected = _selected?.code == candidate.code;
                      return InkWell(
                        onTap: _saving
                            ? null
                            : () => setState(() {
                                _selected = candidate;
                                _failed = false;
                              }),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: selected
                                ? context.semanticColors.primarySoft
                                : context.semanticColors.background,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: selected
                                  ? context.semanticColors.primary
                                  : context.semanticColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      candidate.mealName,
                                      style: AppTextStyles.heading4,
                                    ),
                                    if (candidate.healthTopicName.trim().isNotEmpty)
                                      Text(
                                        candidate.healthTopicName,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: context.semanticColors.primary,
                                        ),
                                      ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Wrap(
                                      spacing: AppSpacing.xs,
                                      children: [
                                        if (candidate.calories > 0)
                                          _PickerPill(
                                            '${candidate.calories} kcal',
                                          ),
                                        if (candidate.servingSize.trim().isNotEmpty)
                                          _PickerPill(candidate.servingSize),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                selected
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: selected
                                    ? context.semanticColors.primary
                                    : context.semanticColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_failed) ...[
                    Text(
                      'Chưa thể đổi món này. Bạn thử lại nhé.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.semanticColors.error,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  FilledButton.icon(
                    onPressed: _selected == null || _saving ? null : _confirm,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(
                      _saving
                          ? 'Đang đổi món...'
                          : _selected == null
                          ? 'Chọn một món'
                          : 'Chọn món này',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    final selected = _selected;
    if (selected == null || _saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      final result = await widget.onConfirm(selected);
      if (mounted) Navigator.of(context).pop(result);
    } catch (_) {
      AppFeedbackService.instance.emit(AppFeedbackType.error);
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
    }
  }
}

class _PickerMessage extends StatelessWidget {
  const _PickerMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: context.semanticColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(title, textAlign: TextAlign.center, style: AppTextStyles.heading3),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.semanticColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerPill extends StatelessWidget {
  const _PickerPill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.semanticColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(text, style: AppTextStyles.bodySmall),
    );
  }
}
