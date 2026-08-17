import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/design_system.dart';

import '../../domain/entities/daily_health_snapshot_entity.dart';
import '../../domain/entities/schedule_health_action_type.dart';
import '../../providers/lifestyle_schedule_provider.dart';

Future<bool> showDailyHealthQuickCheckInSheet({
  required BuildContext context,
  required WidgetRef ref,
  required DateTime date,
  required ScheduleHealthActionType action,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => DailyHealthQuickCheckInSheet(date: date, action: action),
  );
  return result == true;
}

class DailyHealthQuickCheckInSheet extends ConsumerStatefulWidget {
  final DateTime date;
  final ScheduleHealthActionType action;

  const DailyHealthQuickCheckInSheet({
    super.key,
    required this.date,
    required this.action,
  });

  @override
  ConsumerState<DailyHealthQuickCheckInSheet> createState() =>
      _DailyHealthQuickCheckInSheetState();
}

class _DailyHealthQuickCheckInSheetState
    extends ConsumerState<DailyHealthQuickCheckInSheet> {
  final _valueController = TextEditingController();
  String _mood = 'neutral';
  double _stress = 3;
  bool _saving = false;

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacingTokens.pagePadding,
        AppSpacingTokens.sectionSpacing,
        AppSpacingTokens.pagePadding,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacingTokens.sectionSpacing,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.action.label, style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacingTokens.itemSpacing),
            Text(
              'Ghi nhận này cập nhật nhật ký sức khỏe. Đây không phải chẩn đoán hay chỉ định y tế.',
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacingTokens.sectionSpacing),
            _inputForAction(),
            const SizedBox(height: AppSpacingTokens.sectionSpacing),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Lưu ghi nhận'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputForAction() {
    switch (widget.action) {
      case ScheduleHealthActionType.hydration:
        return Wrap(
          spacing: AppSpacingTokens.itemSpacing,
          runSpacing: AppSpacingTokens.itemSpacing,
          children: [
            _AmountButton(label: '+250 ml', onTap: () => _saveWater(250)),
            _AmountButton(label: '+500 ml', onTap: () => _saveWater(500)),
          ],
        );
      case ScheduleHealthActionType.moodStress:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _mood,
              decoration: const InputDecoration(labelText: 'Cảm xúc hiện tại'),
              items: const [
                DropdownMenuItem(value: 'very_good', child: Text('Rất tốt')),
                DropdownMenuItem(value: 'good', child: Text('Tốt')),
                DropdownMenuItem(value: 'neutral', child: Text('Bình thường')),
                DropdownMenuItem(value: 'tired', child: Text('Hơi mệt')),
                DropdownMenuItem(value: 'stressed', child: Text('Căng thẳng')),
              ],
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value != null) setState(() => _mood = value);
                    },
            ),
            const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
            Text('Mức căng thẳng: ${_stress.round()}/5'),
            Slider(
              value: _stress,
              min: 1,
              max: 5,
              divisions: 4,
              label: _stress.round().toString(),
              onChanged: _saving ? null : (value) => setState(() => _stress = value),
            ),
          ],
        );
      case ScheduleHealthActionType.sleepCheckIn:
        return TextField(
          controller: _valueController,
          enabled: !_saving,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          decoration: const InputDecoration(
            labelText: 'Thời lượng ngủ',
            suffixText: 'giờ',
          ),
        );
      case ScheduleHealthActionType.weightCheckIn:
        return TextField(
          controller: _valueController,
          enabled: !_saving,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          decoration: const InputDecoration(
            labelText: 'Cân nặng',
            suffixText: 'kg',
          ),
        );
      case ScheduleHealthActionType.quickComplete:
      case ScheduleHealthActionType.photoProof:
        return const Text('Không cần nhập thêm dữ liệu.');
    }
  }

  Future<void> _saveWater(int amount) async {
    if (_saving) return;
    setState(() => _saving = true);
    final result = await ref.read(dailyHealthHubControllerProvider).recordStandaloneCheckIn(
          date: widget.date,
          input: DailyHealthCheckInInput(waterDeltaMl: amount),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
    if (result.succeeded) Navigator.of(context).pop(true);
  }

  Future<void> _save() async {
    if (_saving) return;
    final input = switch (widget.action) {
      ScheduleHealthActionType.moodStress => DailyHealthCheckInInput(
          mood: _mood,
          stressLevel: _stress.round(),
        ),
      ScheduleHealthActionType.sleepCheckIn => DailyHealthCheckInInput(
          sleepHours: double.tryParse(_valueController.text.trim()),
        ),
      ScheduleHealthActionType.weightCheckIn => DailyHealthCheckInInput(
          weightKg: double.tryParse(_valueController.text.trim()),
        ),
      _ => const DailyHealthCheckInInput(),
    };
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn chưa nhập dữ liệu cần ghi nhận.')),
      );
      return;
    }
    setState(() => _saving = true);
    final result = await ref.read(dailyHealthHubControllerProvider).recordStandaloneCheckIn(
          date: widget.date,
          input: input,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
    if (result.succeeded) Navigator.of(context).pop(true);
  }
}

class _AmountButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AmountButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(onPressed: onTap, child: Text(label));
  }
}
