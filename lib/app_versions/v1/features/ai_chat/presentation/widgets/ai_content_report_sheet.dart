import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../domain/entities/ai_content_report.dart';
import '../controllers/ai_content_report_controller.dart';

class AiContentReportSheet extends ConsumerStatefulWidget {
  final String messageId;
  final String messageSnapshot;

  const AiContentReportSheet({
    super.key,
    required this.messageId,
    required this.messageSnapshot,
  });

  @override
  ConsumerState<AiContentReportSheet> createState() =>
      _AiContentReportSheetState();
}

class _AiContentReportSheetState extends ConsumerState<AiContentReportSheet> {
  final TextEditingController _noteController = TextEditingController();
  AiContentReportReason? _reason;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiContentReportControllerProvider);
    final submitting = state.status == AiContentReportStatus.submitting;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.md,
          AppSpacing.pagePadding,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Báo cáo phản hồi này', style: AppTextStyles.heading3),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Nabi sẽ dùng báo cáo để kiểm tra và cải thiện câu trả lời. Bạn hãy chọn lý do phù hợp nhé.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              RadioGroup<AiContentReportReason>(
                groupValue: _reason,
                onChanged: submitting
                    ? (_) {}
                    : (value) => setState(() => _reason = value),
                child: Column(
                  children: [
                    for (final reason in AiContentReportReason.values)
                      RadioListTile<AiContentReportReason>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(reason.label),
                        value: reason,
                        enabled: !submitting,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _noteController,
                enabled: !submitting,
                maxLength: AiContentReport.maxNoteLength,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú thêm (không bắt buộc)',
                  hintText: 'Điều gì khiến bạn thấy cần báo cáo?',
                ),
              ),
              if (state.message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  state.message!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.semanticColors.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _reason == null || submitting
                      ? null
                      : () async {
                          final sent = await ref
                              .read(aiContentReportControllerProvider.notifier)
                              .submit(
                                messageId: widget.messageId,
                                messageSnapshot: widget.messageSnapshot,
                                reason: _reason!,
                                note: _noteController.text,
                              );
                          if (sent && context.mounted) {
                            Navigator.of(context).pop(true);
                          }
                        },
                  child: submitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Gửi báo cáo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
