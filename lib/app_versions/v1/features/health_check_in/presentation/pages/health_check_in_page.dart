import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/notification_care/providers/notification_care_providers.dart';
import 'package:nano_app/core/theme/theme.dart';

class HealthCheckInPage extends ConsumerStatefulWidget {
  const HealthCheckInPage({super.key});

  @override
  ConsumerState<HealthCheckInPage> createState() => _HealthCheckInPageState();
}

class _HealthCheckInPageState extends ConsumerState<HealthCheckInPage> {
  String _overallFeeling = 'okay';
  final Map<String, String> _statusById = {};
  final TextEditingController _noteController = TextEditingController();
  String? _initializedActor;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(healthCheckInControllerProvider);
    return MedicalPageScaffold(
      backgroundColor: context.semanticColors.background,
      appBar: AppBar(title: const Text('Nabi hỏi thăm bạn')),
      body: SafeArea(
        top: false,
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _LoadError(
            onRetry: () => ref.invalidate(healthCheckInControllerProvider),
          ),
          data: (data) {
            if (_initializedActor != data.actorKey) {
              _initializedActor = data.actorKey;
              _statusById
                ..clear()
                ..addEntries(
                  data.conditions.map((item) => MapEntry(item.id, 'same')),
                );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.md,
                AppSpacing.pagePadding,
                AppSpacing.xxxl,
              ),
              children: [
                Text('Hiện tại bạn thấy sao?', style: AppTextStyles.heading2),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Chọn cảm nhận gần nhất. Nabi chỉ ghi nhận thông tin bạn xác nhận, không tự chẩn đoán bệnh.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.semanticColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: const [
                    ('good', 'Khá ổn 😊'),
                    ('okay', 'Bình thường 🙂'),
                    ('tired', 'Hơi mệt 😮‍💨'),
                    ('bad', 'Không ổn lắm 😟'),
                  ].map((item) {
                    return const SizedBox.shrink();
                  }).toList(),
                ),
                _FeelingSelector(
                  value: _overallFeeling,
                  onChanged: (value) => setState(() => _overallFeeling = value),
                ),
                const SizedBox(height: AppSpacing.sectionSpacing),
                Text('Tình trạng đang theo dõi', style: AppTextStyles.heading3),
                const SizedBox(height: AppSpacing.sm),
                if (data.conditions.isEmpty)
                  _InfoCard(
                    icon: Icons.health_and_safety_rounded,
                    text: 'Hiện Nabi chưa thấy tình trạng bệnh lý nào đang được lưu.',
                  )
                else
                  for (final item in data.conditions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.cardPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: AppTextStyles.labelLarge),
                              const SizedBox(height: AppSpacing.sm),
                              SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(
                                    value: 'better',
                                    label: Text('Đỡ hơn'),
                                  ),
                                  ButtonSegment(
                                    value: 'same',
                                    label: Text('Như cũ'),
                                  ),
                                  ButtonSegment(
                                    value: 'worse',
                                    label: Text('Nặng hơn'),
                                  ),
                                  ButtonSegment(
                                    value: 'resolved',
                                    label: Text('Đã ổn'),
                                  ),
                                ],
                                selected: {_statusById[item.id] ?? 'same'},
                                onSelectionChanged: (selection) {
                                  setState(() {
                                    _statusById[item.id] = selection.first;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú thêm (không bắt buộc)',
                    hintText: 'Ví dụ: hôm nay ngủ kém, đau nhiều hơn...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _InfoCard(
                  icon: Icons.info_outline_rounded,
                  text:
                      'Chỉ khi bạn chọn “Đã ổn”, Nabi mới bỏ tình trạng đó khỏi hồ sơ đang theo dõi. Nếu triệu chứng nặng, đột ngột hoặc đáng lo, hãy ưu tiên liên hệ cơ sở y tế phù hợp.',
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: () => _submit(data.actorKey),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Lưu cập nhật'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _submit(String actorKey) async {
    await ref.read(healthCheckInControllerProvider.notifier).submit(
          overallFeeling: _overallFeeling,
          conditionStatusById: Map.unmodifiable(_statusById),
          note: _noteController.text,
        );
    if (!mounted) return;
    final result = ref.read(healthCheckInControllerProvider);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result.hasError
                ? 'Nabi chưa lưu được cập nhật. Bạn thử lại nhé.'
                : 'Nabi đã ghi nhận tình trạng hiện tại của bạn.',
          ),
        ),
      );
    if (!result.hasError) _noteController.clear();
  }
}

class _FeelingSelector extends StatelessWidget {
  const _FeelingSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      ('good', 'Khá ổn 😊'),
      ('okay', 'Bình thường 🙂'),
      ('tired', 'Hơi mệt 😮‍💨'),
      ('bad', 'Không ổn lắm 😟'),
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final option in options)
          ChoiceChip(
            label: Text(option.$2),
            selected: value == option.$1,
            onSelected: (_) => onChanged(option.$1),
          ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: context.semanticColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 44),
            const SizedBox(height: AppSpacing.md),
            const Text('Nabi chưa mở được phần hỏi thăm lúc này.'),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
