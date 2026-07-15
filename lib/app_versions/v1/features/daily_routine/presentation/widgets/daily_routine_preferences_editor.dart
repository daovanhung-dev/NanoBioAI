import 'package:flutter/material.dart';

import '../../domain/entities/daily_routine_preferences.dart';

class DailyRoutinePreferencesEditor extends StatelessWidget {
  final DailyRoutinePreferences value;
  final ValueChanged<DailyRoutinePreferences> onChanged;

  const DailyRoutinePreferencesEditor({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TemplateEditor(
          title: 'Ngày thường · Thứ Hai–Thứ Sáu',
          value: value.weekday,
          onChanged: (template) => onChanged(value.copyWith(weekday: template)),
        ),
        const SizedBox(height: 16),
        _TemplateEditor(
          title: 'Cuối tuần · Thứ Bảy–Chủ Nhật',
          value: value.weekend,
          onChanged: (template) => onChanged(value.copyWith(weekend: template)),
        ),
      ],
    );
  }
}

class _TemplateEditor extends StatelessWidget {
  static const _mealLabels = [
    'Bữa sáng',
    'Bữa phụ sáng',
    'Bữa trưa',
    'Bữa phụ chiều',
    'Bữa tối',
  ];

  final String title;
  final RoutineDayTemplate value;
  final ValueChanged<RoutineDayTemplate> onChanged;

  const _TemplateEditor({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('Thức ${value.wakeTime} · Ngủ ${value.sleepTime}'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _TimeRow(
            label: 'Giờ thức dậy',
            value: value.wakeTime,
            onChanged: (time) => onChanged(value.copyWith(wakeTime: time)),
          ),
          _TimeRow(
            label: 'Giờ ngủ',
            value: value.sleepTime,
            onChanged: (time) => onChanged(value.copyWith(sleepTime: time)),
          ),
          const Divider(),
          for (var index = 0; index < _mealLabels.length; index++)
            _TimeRow(
              label: _mealLabels[index],
              value: value.mealTimes[index],
              onChanged: (time) {
                final meals = [...value.mealTimes]..[index] = time;
                onChanged(value.copyWith(mealTimes: meals));
              },
            ),
          const Divider(),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Có ngủ trưa'),
            value: value.napEnabled,
            onChanged: (enabled) => onChanged(
              value.copyWith(
                napEnabled: enabled,
                napRange: enabled
                    ? value.napRange ??
                          const RoutineTimeRange(start: '12:45', end: '13:15')
                    : value.napRange,
              ),
            ),
          ),
          if (value.napEnabled)
            _RangeEditor(
              label: 'Khung ngủ trưa',
              value:
                  value.napRange ??
                  const RoutineTimeRange(start: '12:45', end: '13:15'),
              onChanged: (range) => onChanged(value.copyWith(napRange: range)),
            ),
          const Divider(),
          for (var index = 0; index < value.workoutRanges.length; index++)
            _RangeEditor(
              label: 'Khung tập ${index + 1}',
              value: value.workoutRanges[index],
              onChanged: (range) {
                final ranges = [...value.workoutRanges]..[index] = range;
                onChanged(value.copyWith(workoutRanges: ranges));
              },
            ),
          const Divider(),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Có khoảng bận học/làm việc'),
            value: value.busyRange != null,
            onChanged: (enabled) => onChanged(
              value.copyWith(
                busyRange: enabled
                    ? value.busyRange ??
                          const RoutineTimeRange(start: '08:30', end: '11:30')
                    : null,
                clearBusyRange: !enabled,
              ),
            ),
          ),
          if (value.busyRange != null)
            _RangeEditor(
              label: 'Khoảng bận',
              value: value.busyRange!,
              onChanged: (range) => onChanged(value.copyWith(busyRange: range)),
            ),
        ],
      ),
    );
  }
}

class _RangeEditor extends StatelessWidget {
  final String label;
  final RoutineTimeRange value;
  final ValueChanged<RoutineTimeRange> onChanged;

  const _RangeEditor({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _TimeRow(
                label: 'Bắt đầu',
                value: value.start,
                onChanged: (time) => onChanged(value.copyWith(start: time)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TimeRow(
                label: 'Kết thúc',
                value: value.end,
                onChanged: (time) => onChanged(value.copyWith(end: time)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _TimeRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: OutlinedButton(
        onPressed: () async {
          final initial = _timeOfDay(value);
          final selected = await showTimePicker(
            context: context,
            initialTime: initial,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(alwaysUse24HourFormat: true),
              child: child!,
            ),
          );
          if (selected != null) onChanged(_format(selected));
        },
        child: Text(value),
      ),
    );
  }
}

TimeOfDay _timeOfDay(String value) {
  final parts = value.split(':');
  return TimeOfDay(
    hour: int.tryParse(parts.firstOrNull ?? '') ?? 0,
    minute: int.tryParse(parts.elementAtOrNull(1) ?? '') ?? 0,
  );
}

String _format(TimeOfDay value) {
  return '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}
