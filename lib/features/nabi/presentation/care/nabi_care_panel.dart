import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/care/nabi_care_controller.dart';
import '../../domain/care/nabi_care_models.dart';

Future<void> showNabiCarePanel(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const NabiCarePanel(),
  );
}

class NabiCarePanel extends ConsumerWidget {
  const NabiCarePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nabiCareControllerProvider);
    final result = state.result;
    if (result == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('NaBi đang chuẩn bị dữ liệu chăm sóc cho bạn.'),
      );
    }

    final analysis = result.analysis;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.48,
      maxChildSize: 0.94,
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colors.primaryContainer,
                  child: Icon(
                    Icons.favorite_rounded,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NaBi Care hôm nay', style: theme.textTheme.titleLarge),
                      Text(
                        _statusLabel(analysis.overallStatus),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (result.fromCache)
                  Tooltip(
                    message: 'Dữ liệu chưa thay đổi nên NaBi dùng lại phân tích gần nhất.',
                    child: Icon(Icons.bolt_rounded, color: colors.primary),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              analysis.summary,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
            ),
            if (analysis.observations.isNotEmpty) ...[
              const SizedBox(height: 22),
              Text('NaBi đang để ý', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              for (final item in analysis.observations)
                _ObservationCard(observation: item),
            ],
            if (analysis.actions.isNotEmpty) ...[
              const SizedBox(height: 22),
              Text('Việc nhỏ nên ưu tiên', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              for (final action in analysis.actions)
                _ActionCard(action: action),
            ],
            if (analysis.questions.isNotEmpty) ...[
              const SizedBox(height: 22),
              Text('NaBi muốn biết thêm', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final question in analysis.questions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.chat_bubble_outline_rounded),
                  title: Text(question.text),
                  subtitle:
                      question.reason.isEmpty ? null : Text(question.reason),
                ),
            ],
            if (analysis.missingData.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Dữ liệu còn thiếu: ${analysis.missingData.join(', ')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 22),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => ref
                      .read(nabiCareControllerProvider.notifier)
                      .sendFeedback(NabiCareFeedbackType.helpful),
                  icon: const Icon(Icons.thumb_up_alt_outlined),
                  label: const Text('Hữu ích'),
                ),
                OutlinedButton.icon(
                  onPressed: () => ref
                      .read(nabiCareControllerProvider.notifier)
                      .sendFeedback(NabiCareFeedbackType.doLater),
                  icon: const Icon(Icons.schedule_rounded),
                  label: const Text('Để sau'),
                ),
                TextButton(
                  onPressed: () => ref
                      .read(nabiCareControllerProvider.notifier)
                      .sendFeedback(NabiCareFeedbackType.notRelevant),
                  child: const Text('Chưa phù hợp'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'NaBi Care dùng dữ liệu bạn đã ghi nhận để hỗ trợ theo dõi và xây thói quen. Nội dung này không thay thế chẩn đoán hoặc tư vấn trực tiếp từ chuyên gia y tế.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        );
      },
    );
  }

  String _statusLabel(NabiCareOverallStatus status) {
    return switch (status) {
      NabiCareOverallStatus.stable => 'Nhịp hiện tại khá ổn định',
      NabiCareOverallStatus.needsAttention => 'Có vài điểm nên theo dõi thêm',
      NabiCareOverallStatus.improving => 'Đang có tín hiệu tích cực',
      NabiCareOverallStatus.insufficientData =>
        'Cần thêm dữ liệu để hiểu bạn chính xác hơn',
    };
  }
}

class _ObservationCard extends StatelessWidget {
  final NabiCareObservation observation;

  const _ObservationCard({required this.observation});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              observation.severity.index >= NabiCareSeverity.medium.index
                  ? Icons.visibility_rounded
                  : Icons.auto_awesome_rounded,
              color: colors.primary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    observation.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (observation.detail.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(observation.detail),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends ConsumerWidget {
  final NabiCareAction action;

  const _ActionCard({required this.action});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: colors.primaryContainer,
                  child: Text(
                    '${action.priority}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(action.title, style: theme.textTheme.titleSmall),
                ),
              ],
            ),
            if (action.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(action.description),
            ],
            if (action.suggestedTime != null) ...[
              const SizedBox(height: 8),
              Text(
                action.suggestedTime!,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.primary,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => ref
                    .read(nabiCareControllerProvider.notifier)
                    .sendFeedback(
                      NabiCareFeedbackType.completed,
                      actionId: action.id,
                    ),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Đã thực hiện'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
