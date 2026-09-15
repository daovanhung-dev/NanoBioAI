import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/sleep_safety_session.dart';
import '../../domain/entities/sleep_safety_event.dart';
import '../../domain/services/sleep_safety_state_machine.dart';
import '../../providers/sleep_night_analysis_providers.dart';
import '../../providers/sleep_safety_providers.dart';
import '../widgets/sleep_safety_alert_overlay.dart';
import '../widgets/sleep_safety_audio_level_meter.dart';
import '../widgets/sleep_safety_disclaimer.dart';
import '../widgets/sleep_safety_status_card.dart';
import 'sleep_night_analysis_page.dart';
import 'sleep_safety_contacts_page.dart';
import 'sleep_safety_history_page.dart';
import 'sleep_safety_schedule_page.dart';

class SleepTrackingPage extends ConsumerWidget {
  const SleepTrackingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(sleepSafetyControllerProvider, (previous, next) {
      final previousEndedAt = previous?.session?.endedAt;
      final nextEndedAt = next.session?.endedAt;
      if (previousEndedAt == null && nextEndedAt != null) {
        ref.invalidate(recentSleepSessionsProvider);
      }
    });
    final state = ref.watch(sleepSafetyControllerProvider);
    final controller = ref.read(sleepSafetyControllerProvider.notifier);
    final pref = state.preference;
    final metrics = state.audioMetrics;
    final recentSessions =
        ref.watch(recentSleepSessionsProvider).asData?.value ??
        const <SleepSafetySession>[];
    final completedSessions = recentSessions
        .where((session) => session.endedAt != null)
        .toList(growable: false);
    final latestSessionId = completedSessions.isNotEmpty
        ? completedSessions.first.id
        : (!state.monitoringActive && state.session?.endedAt != null
              ? state.session?.id
              : null);
    final startSource =
        GoRouterState.of(context).uri.queryParameters['source'] ==
            'scheduled_reminder'
        ? 'scheduled_reminder'
        : 'manual';
    final dispatchFailed =
        state.currentEvent?.escalationStatus ==
        SleepSafetyEscalationStatus.failed;
    final dispatchAccepted =
        state.currentEvent?.escalationStatus ==
        SleepSafetyEscalationStatus.accepted;
    final alert =
        state.machine.phase == SleepSafetyPhase.awaitingResponse ||
        state.machine.phase == SleepSafetyPhase.reminder ||
        (state.machine.phase == SleepSafetyPhase.escalating &&
            !dispatchAccepted);

    return Scaffold(
      appBar: AppBar(title: const Text('Giám sát giấc ngủ')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Nabi đồng hành cùng bạn trong đêm',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Theo dõi các tín hiệu âm thanh bất thường trên thiết bị và cảnh báo sớm khi cần chú ý.',
              ),
              const SizedBox(height: 18),
              if (state.errorMessage != null)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(state.errorMessage!),
                  ),
                ),
              if (state.notice != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(state.notice!),
                  ),
                ),
              SleepSafetyStatusCard(
                phase: state.machine.phase,
                sensitivity: _sensitivity(pref?.sensitivity),
                verifiedContacts: state.contacts
                    .where((contact) => contact.isVerified)
                    .length,
                busy: state.isBusy,
                onStart: () => controller.startMonitoring(source: startSource),
                onStop: controller.stopMonitoring,
              ),
              if (state.monitoringActive) ...[
                const SizedBox(height: 12),
                SleepSafetyAudioLevelMeter(
                  signalLevel: metrics?.signalLevel ?? 0,
                  peakLevel: metrics?.peakLevel ?? 0,
                  baselineLevel: metrics?.baselineLevel ?? 0,
                  relativeEnergy: metrics?.relativeEnergy ?? 0,
                  phase: state.detectorCandidateType != null
                      ? 'candidate'
                      : metrics?.phase ??
                            (state.machine.phase == SleepSafetyPhase.calibrating
                                ? 'calibrating'
                                : 'waiting'),
                  sensitivity: _sensitivity(pref?.sensitivity),
                  hasSignal: metrics != null,
                  signalStale: state.audioSignalStale,
                ),
              ],
              if (state.machine.phase == SleepSafetyPhase.calibrating) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(value: state.calibrationProgress),
                const SizedBox(height: 8),
                const Text(
                  'Nabi đang làm quen với âm thanh trong phòng. Giữ điện thoại ở vị trí bạn thường đặt khi ngủ nhé. Âm thanh cực lớn vẫn được kiểm tra trong lúc hiệu chỉnh.',
                ),
              ],
              const SizedBox(height: 12),
              if (pref != null)
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.tune_rounded),
                        title: const Text('Độ nhạy'),
                        subtitle: Text(_sensitivity(pref.sensitivity)),
                        trailing: DropdownButton<SleepSafetySensitivity>(
                          value: pref.sensitivity,
                          items: SleepSafetySensitivity.values
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(_sensitivity(value)),
                                ),
                              )
                              .toList(),
                          onChanged: state.monitoringActive
                              ? null
                              : (value) {
                                  if (value != null) {
                                    controller.savePreference(
                                      pref.copyWith(sensitivity: value),
                                    );
                                  }
                                },
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.schedule_rounded),
                        title: const Text('Lịch giám sát'),
                        subtitle: Text(
                          pref.scheduleEnabled
                              ? 'Đã bật nhắc theo lịch'
                              : 'Chưa bật',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const SleepSafetySchedulePage(),
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.contacts_rounded),
                        title: const Text('Người liên hệ an toàn'),
                        subtitle: Text('${state.contacts.length}/3 người'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const SleepSafetyContactsPage(),
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.history_rounded),
                        title: const Text('Lịch sử cảnh báo'),
                        subtitle: const Text(
                          'Chỉ lưu thông tin sự kiện, không lưu bản ghi âm',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const SleepSafetyHistoryPage(),
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.bedtime_rounded),
                        title: const Text('Phân tích giấc ngủ'),
                        subtitle: Text(
                          latestSessionId == null
                              ? 'Cần ít nhất một phiên giám sát đã kết thúc'
                              : 'Chỉ số cục bộ, xu hướng 7 đêm và phân tích AI',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        enabled: latestSessionId != null,
                        onTap: latestSessionId == null
                            ? null
                            : () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => SleepNightAnalysisPage(
                                    sessionId: latestSessionId,
                                  ),
                                ),
                              ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.hearing_rounded),
                        title: const Text('Hiệu chỉnh lại âm thanh phòng'),
                        subtitle: Text(
                          pref.calibrationUpdatedAt == null
                              ? 'Chưa hiệu chỉnh'
                              : 'Lần gần nhất: ${pref.calibrationUpdatedAt}',
                        ),
                        onTap: state.monitoringActive
                            ? controller.recalibrate
                            : null,
                      ),
                    ],
                  ),
                ),
              const SleepSafetyDisclaimer(),
              const SizedBox(height: 32),
            ],
          ),
          if (alert &&
              state.currentEvent != null &&
              state.machine.alertStartedAt != null)
            Positioned.fill(
              child: SleepSafetyAlertOverlay(
                startedAt: state.machine.alertStartedAt!,
                dispatching:
                    state.machine.phase == SleepSafetyPhase.escalating &&
                    !dispatchFailed,
                dispatchFailed: dispatchFailed,
                dispatchError: state.errorMessage,
                onOk: controller.respondOk,
                onNeedHelp: controller.requestHelp,
                onRetry: controller.retryEmergencyDispatch,
              ),
            ),
        ],
      ),
    );
  }

  static String _sensitivity(SleepSafetySensitivity? value) => switch (value) {
    SleepSafetySensitivity.low => 'Thấp',
    SleepSafetySensitivity.high => 'Cao',
    _ => 'Cân bằng',
  };
}
