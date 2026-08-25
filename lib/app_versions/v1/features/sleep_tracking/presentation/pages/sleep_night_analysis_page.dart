import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/sleep_morning_checkin.dart';
import '../../domain/entities/sleep_night_analysis.dart';
import '../../domain/entities/sleep_safety_event.dart';
import '../../providers/sleep_night_analysis_providers.dart';

class SleepNightAnalysisPage extends ConsumerStatefulWidget {
  const SleepNightAnalysisPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<SleepNightAnalysisPage> createState() =>
      _SleepNightAnalysisPageState();
}

class _SleepNightAnalysisPageState
    extends ConsumerState<SleepNightAnalysisPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref
          .read(sleepNightAnalysisControllerProvider.notifier)
          .load(widget.sessionId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sleepNightAnalysisControllerProvider);
    final matchesSession = state.session?.id == widget.sessionId;
    final analysis = matchesSession ? state.analysis : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Phân tích giấc ngủ')),
      body: (state.loading || !matchesSession) && analysis == null
          ? const Center(child: CircularProgressIndicator())
          : analysis == null
          ? _ErrorState(
              message:
                  state.errorMessage ??
                  'Chưa có đủ dữ liệu để phân tích phiên này.',
              onRetry: () => ref
                  .read(sleepNightAnalysisControllerProvider.notifier)
                  .load(widget.sessionId),
            )
          : RefreshIndicator(
              onRefresh: () => ref
                  .read(sleepNightAnalysisControllerProvider.notifier)
                  .load(widget.sessionId),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _HeroCard(analysis: analysis),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(state.errorMessage!),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const _SectionTitle(
                    icon: Icons.query_stats_rounded,
                    title: 'Tổng quan đêm',
                  ),
                  const SizedBox(height: 8),
                  _MetricGrid(analysis: analysis),
                  const SizedBox(height: 20),
                  const _SectionTitle(
                    icon: Icons.timeline_rounded,
                    title: 'Dòng thời gian sự kiện',
                  ),
                  const SizedBox(height: 8),
                  _EventTimeline(events: state.events),
                  const SizedBox(height: 20),
                  const _SectionTitle(
                    icon: Icons.bar_chart_rounded,
                    title: 'Phân bố tín hiệu âm thanh',
                  ),
                  const SizedBox(height: 8),
                  _DistributionCard(analysis: analysis),
                  const SizedBox(height: 20),
                  const _SectionTitle(
                    icon: Icons.insights_rounded,
                    title: 'Xu hướng 7 đêm',
                  ),
                  const SizedBox(height: 8),
                  _TrendCard(analysis: analysis),
                  const SizedBox(height: 20),
                  _MorningCheckinCard(
                    analysis: analysis,
                    onEdit: () => _showMorningCheckin(context, analysis),
                  ),
                  const SizedBox(height: 20),
                  _AiCard(
                    analysis: analysis,
                    configured: state.aiConfigured,
                    busy: state.generatingAi,
                    onGenerate: () => _confirmAiSend(context),
                  ),
                  const SizedBox(height: 20),
                  const _SafetyDisclaimer(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Future<void> _confirmAiSend(BuildContext context) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Phân tích với AI'),
        content: const Text(
          'NanoBio chỉ gửi các chỉ số tổng hợp, phân bố sự kiện và xu hướng. '
          'Không gửi bản ghi âm, bản chép lời, số điện thoại người thân hoặc API key.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Gửi phân tích'),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) {
      await ref
          .read(sleepNightAnalysisControllerProvider.notifier)
          .generateAiAnalysis();
    }
  }

  Future<void> _showMorningCheckin(
    BuildContext context,
    SleepNightAnalysis analysis,
  ) async {
    var timeInBed = analysis.morningCheckin?.timeInBedMinutes ?? 480;
    var latency = analysis.morningCheckin?.sleepLatencyMinutes ?? 15;
    var awakenings = analysis.morningCheckin?.rememberedAwakenings ?? 0;
    var awakeMinutes = analysis.morningCheckin?.awakeDuringNightMinutes ?? 0;
    var restfulness = analysis.morningCheckin?.restfulness ?? 3;

    final result = await showDialog<SleepMorningCheckin>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text('Cảm nhận buổi sáng'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NumberField(
                  label: 'Thời gian nằm nghỉ (phút)',
                  initialValue: timeInBed,
                  onChanged: (value) => timeInBed = value,
                ),
                _NumberField(
                  label: 'Ước lượng thời gian để ngủ (phút)',
                  initialValue: latency,
                  onChanged: (value) => latency = value,
                ),
                _NumberField(
                  label: 'Số lần nhớ mình thức giấc',
                  initialValue: awakenings,
                  onChanged: (value) => awakenings = value,
                ),
                _NumberField(
                  label: 'Tổng phút thức giữa đêm',
                  initialValue: awakeMinutes,
                  onChanged: (value) => awakeMinutes = value,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(child: Text('Mức nghỉ ngơi khi thức dậy')),
                    DropdownButton<int>(
                      value: restfulness,
                      items: [1, 2, 3, 4, 5]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text('$value/5'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setLocalState(() => restfulness = value);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                SleepMorningCheckin(
                  timeInBedMinutes: timeInBed.clamp(1, 1440).toInt(),
                  sleepLatencyMinutes: latency.clamp(0, 720).toInt(),
                  rememberedAwakenings: awakenings.clamp(0, 100).toInt(),
                  awakeDuringNightMinutes: awakeMinutes.clamp(0, 720).toInt(),
                  restfulness: restfulness.clamp(1, 5).toInt(),
                ),
              ),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) {
      await ref
          .read(sleepNightAnalysisControllerProvider.notifier)
          .saveMorningCheckin(result);
    }
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.analysis});
  final SleepNightAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final score = analysis.sleepWellnessScore.round();
    final quality = (analysis.dataQualityScore * 100).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phân tích đêm ${_date(analysis.startedAt)}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$score',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('/100  Nabi Sleep Wellness'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Độ đầy đủ dữ liệu: $quality%'),
            const SizedBox(height: 8),
            const Text(
              'Điểm này là chỉ số tham khảo từ thời gian giám sát và thông tin '
              'âm thanh tổng hợp, không phải điểm chẩn đoán chất lượng giấc ngủ.',
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.analysis});
  final SleepNightAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final m = analysis.metrics;
    final items = <(String, String, IconData)>[
      (
        'Thời gian giám sát',
        '${_n(m['monitoringDurationMinutes'], 0)} phút',
        Icons.schedule_rounded,
      ),
      ('Sự kiện', _n(m['eventCount'], 0), Icons.graphic_eq_rounded),
      ('Sự kiện / giờ', _n(m['eventsPerHour'], 2), Icons.speed_rounded),
      (
        'Khoảng yên tĩnh dài nhất',
        '${_n(m['longestAlertFreeMinutes'], 0)} phút',
        Icons.nightlight_round,
      ),
      (
        'Tỷ lệ phản hồi',
        '${_pct(m['responseRate'])}%',
        Icons.touch_app_rounded,
      ),
      (
        'Mức xáo trộn tương đối',
        _n(m['weightedDisturbanceIndex'], 2),
        Icons.waves_rounded,
      ),
      (
        'Tín hiệu mức cao',
        _n(m['highSeverityCount'], 0),
        Icons.warning_amber_rounded,
      ),
      (
        'Tỷ lệ không phản hồi',
        '${_pct(m['noResponseRate'])}%',
        Icons.notifications_active_rounded,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 600
            ? (constraints.maxWidth - 12) / 2
            : (constraints.maxWidth - 36) / 4;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(item.$3),
                        const SizedBox(height: 10),
                        Text(
                          item.$2,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(item.$1),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EventTimeline extends StatelessWidget {
  const _EventTimeline({required this.events});
  final List<SleepSafetyEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Không có sự kiện âm thanh cần chú ý trong phiên này.'),
        ),
      );
    }
    return Card(
      child: Column(
        children: [
          for (final event in events.take(20))
            ListTile(
              leading: const Icon(Icons.circle, size: 12),
              title: Text(_eventLabel(event.eventType.name)),
              subtitle: Text(
                '${_time(event.detectedAt)} • ${event.severity} • '
                'năng lượng tương đối ${event.relativeEnergy.toStringAsFixed(2)}\n'
                'Phản hồi: ${_responseLabel(event.response.name)}',
              ),
              isThreeLine: true,
            ),
        ],
      ),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  const _DistributionCard({required this.analysis});
  final SleepNightAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final total = analysis.eventDistribution.values.fold<int>(
      0,
      (a, b) => a + b,
    );
    if (total == 0) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Chưa có sự kiện để tạo phân bố.'),
        ),
      );
    }
    final entries = analysis.eventDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final entry in entries) ...[
              Row(
                children: [
                  Expanded(child: Text(_eventLabel(entry.key))),
                  Text('${entry.value}'),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: entry.value / total),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.analysis});
  final SleepNightAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final t = analysis.trend;
    final nightCount = (t['nightCount'] ?? 1).round();
    if (nightCount < 3) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Nabi đang cần thêm vài đêm để hiểu đường cơ sở của bạn. '
            'Các chỉ số một đêm vẫn được tính bình thường.',
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _TrendRow('Số đêm dùng cho xu hướng', '$nightCount'),
            _TrendRow('Xu hướng sự kiện/đêm', _signed(t['eventRateTrend'])),
            _TrendRow('Xu hướng xáo trộn', _signed(t['disturbanceTrend'])),
            _TrendRow(
              'Độ ổn định thời lượng',
              '${_pct(t['monitoringDurationConsistency'])}%',
            ),
            _TrendRow(
              'Độ ổn định giờ bắt đầu',
              '${_pct(t['startTimeConsistency'])}%',
            ),
            _TrendRow(
              'Lệch so với đường cơ sở cá nhân',
              _signed(t['personalBaselineDeviation']),
            ),
            _TrendRow('Độ tin cậy xu hướng', '${_pct(t['trendConfidence'])}%'),
          ],
        ),
      ),
    );
  }
}

class _MorningCheckinCard extends StatelessWidget {
  const _MorningCheckinCard({required this.analysis, required this.onEdit});
  final SleepNightAnalysis analysis;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final checkin = analysis.morningCheckin;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              icon: Icons.wb_sunny_outlined,
              title: 'Cảm nhận buổi sáng',
            ),
            const SizedBox(height: 8),
            Text(
              checkin == null
                  ? 'Bổ sung vài thông tin bạn tự nhớ để Nabi không phải đoán thời gian ngủ từ micro.'
                  : 'Ước lượng ngủ ${checkin.estimatedSleepMinutes} phút • '
                        'nghỉ ngơi ${checkin.restfulness}/5 • '
                        '${checkin.rememberedAwakenings} lần thức nhớ được.',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded),
              label: Text(checkin == null ? 'Bổ sung cảm nhận' : 'Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiCard extends StatelessWidget {
  const _AiCard({
    required this.analysis,
    required this.configured,
    required this.busy,
    required this.onGenerate,
  });

  final SleepNightAnalysis analysis;
  final bool configured;
  final bool busy;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final sections = _readAiSections(analysis.aiAnalysisJson);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              icon: Icons.auto_awesome_rounded,
              title: 'Phân tích của AI',
            ),
            const SizedBox(height: 8),
            Text(
              configured
                  ? 'AI chỉ nhận dữ liệu tổng hợp của phiên này.'
                  : 'Chưa cấu hình GEMINI_API_KEY. Các công thức cục bộ phía trên vẫn hoạt động.',
            ),
            if (sections.isNotEmpty) ...[
              const SizedBox(height: 16),
              for (final section in sections) ...[
                Text(
                  section.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(section.summary),
                if (section.evidence.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  for (final value in section.evidence) Text('• $value'),
                ],
                if (section.recommendations.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  for (final value in section.recommendations) Text('→ $value'),
                ],
                const SizedBox(height: 16),
              ],
            ],
            FilledButton.icon(
              onPressed: configured && !busy ? onGenerate : null,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(
                sections.isEmpty ? 'Phân tích với AI' : 'Phân tích lại',
              ),
            ),
            if (analysis.aiGeneratedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Lần gần nhất: ${_time(analysis.aiGeneratedAt!)} • ${analysis.aiModel ?? 'AI'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SafetyDisclaimer extends StatelessWidget {
  const _SafetyDisclaimer();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.health_and_safety_outlined),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Phân tích này hỗ trợ theo dõi sức khỏe và thói quen. NanoBio '
                'không thay thế bác sĩ, thiết bị chẩn đoán giấc ngủ hoặc hệ '
                'thống cấp cứu chuyên dụng.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
  });
  final String label;
  final int initialValue;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        initialValue: '$initialValue',
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        onChanged: (value) => onChanged(int.tryParse(value) ?? 0),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.nights_stay_outlined, size: 42),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

class _AiSectionView {
  const _AiSectionView({
    required this.title,
    required this.summary,
    required this.evidence,
    required this.recommendations,
  });
  final String title;
  final String summary;
  final List<String> evidence;
  final List<String> recommendations;
}

List<_AiSectionView> _readAiSections(Map<String, Object?>? json) {
  final raw = json?['sections'];
  if (raw is! List) return const [];
  final result = <_AiSectionView>[];
  for (final item in raw) {
    if (item is! Map) continue;
    List<String> list(String key) {
      final value = item[key];
      return value is List
          ? value.map((e) => e.toString()).toList(growable: false)
          : const [];
    }

    result.add(
      _AiSectionView(
        title: item['title']?.toString() ?? 'Nhận xét',
        summary: item['summary']?.toString() ?? '',
        evidence: list('evidence'),
        recommendations: list('recommendations'),
      ),
    );
  }
  return result;
}

String _eventLabel(String value) => switch (value) {
  'strongImpact' => 'Va đập mạnh',
  'suddenLoudSound' => 'Âm thanh lớn đột ngột',
  'abnormalShout' => 'Mẫu giống tiếng la cần chú ý',
  'abnormalScream' => 'Mẫu giống tiếng hét cần chú ý',
  'repeatedSuspiciousPattern' => 'Âm thanh bất thường lặp lại',
  _ => 'Âm thanh năng lượng cao cần chú ý',
};

String _responseLabel(String value) => switch (value) {
  'ok' => 'Tôi ổn',
  'needHelp' => 'Cần hỗ trợ',
  'noResponse' => 'Không phản hồi',
  _ => 'Chưa có',
};

String _date(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String _time(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _n(double? value, [int digits = 1]) =>
    (value ?? 0).toStringAsFixed(digits);

int _pct(double? value) => (((value ?? 0).clamp(0.0, 1.0)) * 100).round();

String _signed(double? value) {
  final v = value ?? 0;
  final prefix = v > 0 ? '+' : '';
  return '$prefix${v.toStringAsFixed(2)}';
}
