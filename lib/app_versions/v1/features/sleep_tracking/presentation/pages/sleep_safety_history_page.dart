import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/sleep_safety_providers.dart';

class SleepSafetyHistoryPage extends ConsumerWidget {
  const SleepSafetyHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(sleepSafetyControllerProvider).history;

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử cảnh báo')),
      body: events.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Chưa có sự kiện âm thanh cần chú ý. NanoBio không lưu bản '
                  'ghi âm; lịch sử chỉ chứa metadata tối thiểu.',
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final event = events[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.graphic_eq_rounded),
                    title: Text(_label(event.eventType.name)),
                    subtitle: Text(
                      '${_time(event.detectedAt)} • Mức ${event.severity}\n'
                      'Phản hồi: ${event.response.name} • '
                      'Liên hệ: ${event.escalationStatus.name}',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }

  String _label(String value) => switch (value) {
    'strongImpact' => 'Va đập mạnh',
    'suddenLoudSound' => 'Âm thanh lớn đột ngột',
    'abnormalShout' => 'Tiếng kêu bất thường',
    'abnormalScream' => 'Tiếng hét bất thường',
    'repeatedSuspiciousPattern' => 'Âm thanh bất thường lặp lại',
    _ => 'Âm thanh năng lượng cao cần chú ý',
  };

  String _time(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}
