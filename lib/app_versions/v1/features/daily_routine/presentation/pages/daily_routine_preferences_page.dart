import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../domain/entities/daily_routine_preferences.dart';
import '../../providers/daily_routine_preferences_provider.dart';
import '../widgets/daily_routine_preferences_editor.dart';

class DailyRoutinePreferencesPage extends ConsumerStatefulWidget {
  const DailyRoutinePreferencesPage({super.key});

  @override
  ConsumerState<DailyRoutinePreferencesPage> createState() =>
      _DailyRoutinePreferencesPageState();
}

class _DailyRoutinePreferencesPageState
    extends ConsumerState<DailyRoutinePreferencesPage> {
  DailyRoutinePreferences? _draft;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final asyncValue = ref.watch(dailyRoutinePreferencesProvider);
    return MedicalPageScaffold(
      appBar: AppBar(title: const Text('Tùy chỉnh lịch cá nhân')),
      body: asyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _EditorBody(
          preferences: _draft ?? DailyRoutinePreferences.defaults(),
          saving: _saving,
          onChanged: (value) => setState(() => _draft = value),
          onSave: _save,
        ),
        data: (saved) {
          final preferences =
              _draft ?? saved ?? DailyRoutinePreferences.defaults();
          return _EditorBody(
            preferences: preferences,
            saving: _saving,
            onChanged: (value) => setState(() => _draft = value),
            onSave: _save,
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    final preferences =
        _draft ??
        ref.read(dailyRoutinePreferencesProvider).value ??
        DailyRoutinePreferences.defaults();
    final errors = preferences.validate();
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errors.first)));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(dailyRoutinePreferencesRepositoryProvider)
          .saveForCurrentUser(preferences);
      ref.invalidate(dailyRoutinePreferencesProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nabi chưa lưu được lịch cá nhân. Bạn thử lại nhé.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _EditorBody extends StatelessWidget {
  final DailyRoutinePreferences preferences;
  final bool saving;
  final ValueChanged<DailyRoutinePreferences> onChanged;
  final VoidCallback onSave;

  const _EditorBody({
    required this.preferences,
    required this.saving,
    required this.onChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Nabi dùng các mốc này cho những ngày được tạo mới. Lịch hiện tại sẽ không bị thay đổi.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        DailyRoutinePreferencesEditor(value: preferences, onChanged: onChanged),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: saving ? null : onSave,
          icon: saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: const Text('Lưu nhịp sinh hoạt'),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
