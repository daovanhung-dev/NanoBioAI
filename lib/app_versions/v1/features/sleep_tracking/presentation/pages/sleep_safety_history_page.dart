import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/sleep_safety_session.dart';
import '../../providers/sleep_night_analysis_providers.dart';
import '../../providers/sleep_safety_providers.dart';
import 'sleep_night_analysis_page.dart';

class SleepSafetyHistoryPage extends ConsumerWidget {
  const SleepSafetyHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(sleepSafetyControllerProvider).history;
    final sessions = ref.watch(recentSleepSessionsProvider).asData?.value ??
        const <SleepSafetySession>[];
    final completedSessions = sessions
        .where((session) => session.endedAt != null)
        .toList(growable: false);
    final completedSessionIds = completedSessions
        .map((session) => session.id)
        .toSet();

    if (events.isEmpty && completedSessions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lịch sử giám sát')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Chưa có phiên giám sát đã hoàn tất. NanoBio không lưu bản ghi '
              'âm; lịch sử chỉ chứa các thông tin tổng hợp cần thiết.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử giám sát')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (completedSessions.isNotEmpty) ...[
            Text(
              'Các đêm đã giám sát',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            for (final session in completedSessions.take(14)) ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.bedtime_rounded),
                  title: Text('Đêm ${_date(session.startedAt)}'),
                  subtitle: Text(
                    '${_time(session.startedAt)} – ${_time(session.endedAt!)} • '
                    '${_durationMinutes(session.startedAt, session.endedAt!)} phút giám sát',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => SleepNightAnalysisPage(sessionId: session.id),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
          if (events.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Sự kiện cần chú ý',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            for (final event in events) ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.graphic_eq_rounded),
                  title: Text(_label(event.eventType.name)),
                  subtitle: Text(
                    '${_date(event.detectedAt)} ${_time(event.detectedAt)} • '
                    'Mức ${event.severity}\n'
                    'Phản hồi: ${_response(event.response.name)} • '
                    'Liên hệ: ${_escalation(event.escalationStatus.name)}',
                  ),
                  isThreeLine: true,
                  trailing: completedSessionIds.contains(event.sessionId)
                      ? const Icon(Icons.chevron_right)
                      : null,
                  onTap: !completedSessionIds.contains(event.sessionId)
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => SleepNightAnalysisPage(
                                sessionId: event.sessionId,
                              ),
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }

  static String _label(String value) => switch (value) {
        'strongImpact' => 'Va đập mạnh',
        'suddenLoudSound' => 'Âm thanh lớn đột ngột',
        'abnormalShout' => 'Mẫu giống tiếng la cần chú ý',
        'abnormalScream' => 'Mẫu giống tiếng hét cần chú ý',
        'repeatedSuspiciousPattern' => 'Âm thanh bất thường lặp lại',
        _ => 'Âm thanh năng lượng cao cần chú ý',
      };

  static String _response(String value) => switch (value) {
        'ok' => 'Tôi ổn',
        'needHelp' => 'Cần hỗ trợ',
        'noResponse' => 'Không phản hồi',
        _ => 'Chưa có',
      };

  static String _escalation(String value) => switch (value) {
        'accepted' => 'Đã gửi yêu cầu hỗ trợ',
        'dispatching' => 'Đang gửi yêu cầu',
        'failed' => 'Chưa gửi được',
        _ => 'Không cần',
      };

  static String _date(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  static String _time(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static int _durationMinutes(DateTime start, DateTime end) =>
      end.difference(start).inMinutes.clamp(0, 24 * 60).toInt();
}
