import 'dart:convert';

import '../../domain/care/nabi_care_models.dart';
import '../../domain/care/nabi_care_repository.dart';

class NabiCareAiAnalyzer {
  static const systemInstruction = '''
Bạn là NaBi Care, tầng phân tích dữ liệu chăm sóc sức khỏe trong ứng dụng NanoBio.

NGUYÊN TẮC BẮT BUỘC:
1. Chỉ sử dụng dữ liệu có trong snapshot và các evidence_key được cung cấp.
2. Không bịa dữ liệu, không suy đoán một dữ kiện chưa có.
3. Không chẩn đoán bệnh, không khẳng định người dùng mắc bệnh.
4. Không kê đơn, không yêu cầu bắt đầu/ngừng/đổi/tăng/giảm liều thuốc.
5. Khi dữ liệu thiếu, ghi rõ vào missing_data hoặc questions.
6. Ưu tiên so sánh với baseline cá nhân thay vì kết luận từ một giá trị đơn lẻ.
7. Văn phong tiếng Việt: ngắn, ấm áp, không phán xét, có hành động nhỏ cụ thể.
8. Mỗi observation/action có evidence_keys phải tồn tại trong snapshot.
9. Chỉ tạo tối đa 5 observations, 3 care_actions, 3 questions, 3 attention_flags.
10. attention_flags chỉ là lý do cần theo dõi/trao đổi với chuyên gia, không phải chẩn đoán.

Trả về ĐÚNG một JSON object:
{
  "overall_status": "stable|needs_attention|improving|insufficient_data",
  "summary": "string",
  "observations": [
    {
      "title": "string",
      "detail": "string",
      "severity": "info|low|medium|high",
      "confidence": 0.0,
      "evidence_keys": ["key"]
    }
  ],
  "care_actions": [
    {
      "id": "string",
      "title": "string",
      "description": "string",
      "priority": 1,
      "suggested_time": "string|null",
      "channel_hint": "in_app|conversation",
      "evidence_keys": ["key"]
    }
  ],
  "questions": [
    {"id": "string", "text": "string", "reason": "string"}
  ],
  "attention_flags": [
    {
      "code": "string",
      "message": "string",
      "severity": "info|low|medium|high",
      "evidence_keys": ["key"]
    }
  ],
  "missing_data": ["string"],
  "next_review_at": "ISO-8601"
}
''';

  final NabiCareAiGateway gateway;
  final DateTime Function() now;

  NabiCareAiAnalyzer({
    required this.gateway,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  Future<NabiCareAnalysis> analyze(NabiCareSnapshot snapshot) async {
    if (snapshot.dataQuality.completeness < 0.2 && snapshot.signals.isEmpty) {
      return fallback(snapshot, reason: 'insufficient_data');
    }

    try {
      final raw = await gateway.generateAnalysis(
        payload: snapshot.toAiPayload(),
        systemInstruction: systemInstruction,
      );
      final decoded = _decodeObject(raw);
      final analysis = NabiCareAnalysis.fromJson({
        ...decoded,
        'source': 'ai',
      });
      return _validate(analysis, snapshot);
    } catch (_) {
      return fallback(snapshot, reason: 'ai_unavailable');
    }
  }

  NabiCareAnalysis fallback(
    NabiCareSnapshot snapshot, {
    required String reason,
  }) {
    final topSignals = snapshot.signals.take(4).toList(growable: false);
    final observations = <NabiCareObservation>[
      for (final signal in topSignals)
        NabiCareObservation(
          title: signal.title,
          detail: signal.description,
          severity: signal.severity,
          confidence: signal.confidence,
          evidenceKeys: signal.evidenceKeys
              .where(snapshot.evidence.containsKey)
              .toList(growable: false),
        ),
    ];

    final actions = <NabiCareAction>[];
    for (final signal in topSignals.where((item) => !item.positive).take(3)) {
      actions.add(_fallbackAction(signal, actions.length));
    }

    final missing = snapshot.dataQuality.missingGroups;
    final questions = <NabiCareQuestion>[
      for (var index = 0;
          index < missing.length && index < 2;
          index++)
        NabiCareQuestion(
          id: 'missing_${missing[index]}',
          text: _questionForMissingGroup(missing[index]),
          reason: 'Bổ sung dữ liệu để NaBi chăm sóc sát tình trạng hiện tại hơn.',
        ),
    ];

    final hasAttention = topSignals.any(
      (item) =>
          item.severity == NabiCareSeverity.medium ||
          item.severity == NabiCareSeverity.high,
    );
    final hasPositive = topSignals.any((item) => item.positive);
    final status = snapshot.dataQuality.completeness < 0.35
        ? NabiCareOverallStatus.insufficientData
        : hasAttention
            ? NabiCareOverallStatus.needsAttention
            : hasPositive
                ? NabiCareOverallStatus.improving
                : NabiCareOverallStatus.stable;

    final summary = topSignals.isEmpty
        ? 'NaBi chưa thấy thay đổi nổi bật từ dữ liệu hiện có. Mình tiếp tục ghi nhận đều nhé.'
        : topSignals.first.positive
            ? 'Dữ liệu gần đây có tín hiệu tích cực. NaBi sẽ tiếp tục theo dõi cùng bạn.'
            : 'NaBi thấy một vài thay đổi từ dữ liệu gần đây và đã chọn những việc nhỏ cần ưu tiên.';

    return NabiCareAnalysis(
      overallStatus: status,
      summary: summary,
      observations: observations,
      actions: actions,
      questions: questions,
      attentionFlags: const [],
      missingData: missing,
      nextReviewAt: now().add(const Duration(hours: 12)),
      source: 'deterministic_fallback:$reason',
    );
  }

  NabiCareAnalysis _validate(
    NabiCareAnalysis input,
    NabiCareSnapshot snapshot,
  ) {
    final allowedEvidence = snapshot.evidence.keys.toSet();

    List<String> validEvidence(Iterable<String> keys) =>
        keys.where(allowedEvidence.contains).toSet().toList(growable: false);

    final observations = <NabiCareObservation>[];
    for (final item in input.observations.take(5)) {
      final evidence = validEvidence(item.evidenceKeys);
      if (evidence.isEmpty) continue;
      observations.add(
        NabiCareObservation(
          title: item.title,
          detail: item.detail,
          severity: item.severity,
          confidence: item.confidence.clamp(0.0, 1.0).toDouble(),
          evidenceKeys: evidence,
        ),
      );
    }

    final actions = <NabiCareAction>[];
    for (final item in input.actions.take(3)) {
      final evidence = validEvidence(item.evidenceKeys);
      if (evidence.isEmpty) continue;
      actions.add(
        NabiCareAction(
          id: item.id,
          title: item.title,
          description: item.description,
          priority: item.priority.clamp(1, 5).toInt(),
          suggestedTime: item.suggestedTime,
          channelHint: item.channelHint == NabiCareChannelHint.localNotification
              ? NabiCareChannelHint.inApp
              : item.channelHint,
          evidenceKeys: evidence,
        ),
      );
    }

    final flags = <NabiCareAttentionFlag>[];
    for (final item in input.attentionFlags.take(3)) {
      final evidence = validEvidence(item.evidenceKeys);
      if (evidence.isEmpty) continue;
      flags.add(
        NabiCareAttentionFlag(
          code: item.code,
          message: item.message,
          severity: item.severity,
          evidenceKeys: evidence,
        ),
      );
    }

    final current = now();
    final minReview = current.add(const Duration(hours: 2));
    final maxReview = current.add(const Duration(hours: 48));
    final requestedReview = input.nextReviewAt;
    final nextReviewAt = requestedReview.isBefore(minReview)
        ? minReview
        : requestedReview.isAfter(maxReview)
            ? maxReview
            : requestedReview;

    return NabiCareAnalysis(
      overallStatus: input.overallStatus,
      summary: input.summary.trim().isEmpty
          ? 'NaBi đang theo dõi dữ liệu cùng bạn.'
          : input.summary.trim(),
      observations: observations,
      actions: actions,
      questions: input.questions
          .where((item) => item.text.trim().isNotEmpty)
          .take(3)
          .toList(growable: false),
      attentionFlags: flags,
      missingData: {
        ...snapshot.dataQuality.missingGroups,
        ...input.missingData,
      }.toList(growable: false),
      nextReviewAt: nextReviewAt,
      source: 'ai',
    );
  }

  NabiCareAction _fallbackAction(NabiCareSignal signal, int index) {
    final description = switch (signal.code) {
      'sleep_below_recent_pattern' =>
        'Tối nay ưu tiên một khoảng nghỉ sớm hơn và ghi lại thời lượng ngủ để NaBi so sánh tiếp.',
      'water_below_personal_pattern' =>
        'Nếu bạn không có hạn chế nước đã được ghi nhận, hãy chia lượng nước còn lại thành vài lần nhỏ trong ngày.',
      'activity_below_personal_pattern' =>
        'Nếu thấy phù hợp, chọn một khoảng vận động nhẹ ngắn để đưa nhịp hoạt động về gần thói quen của bạn.',
      'stress_above_recent_pattern' =>
        'Dành một khoảng nghỉ ngắn và cập nhật lại mức căng thẳng sau đó để NaBi theo dõi xu hướng.',
      'today_adherence_low' =>
        'Chọn một nhiệm vụ sức khỏe còn lại dễ hoàn thành nhất và làm trước.',
      'active_symptom_follow_up' =>
        'Cập nhật lại mức độ và ảnh hưởng của triệu chứng để NaBi biết tình trạng đang đỡ, giữ nguyên hay tăng lên.',
      _ =>
        'Tiếp tục ghi nhận dữ liệu và kiểm tra lại thay đổi ở lần chăm sóc tiếp theo.',
    };

    return NabiCareAction(
      id: 'fallback_${signal.code}_$index',
      title: 'Việc NaBi gợi ý',
      description: description,
      priority: index + 1,
      channelHint: NabiCareChannelHint.inApp,
      evidenceKeys: signal.evidenceKeys,
    );
  }

  String _questionForMissingGroup(String group) {
    return switch (group) {
      'tracking' => 'Hôm nay bạn muốn cập nhật giấc ngủ, nước hoặc vận động không?',
      'profile' => 'Mình cập nhật lại hồ sơ sức khỏe để NaBi hiểu bạn hơn nhé?',
      'habits' => 'Gần đây giấc ngủ và mức vận động của bạn thế nào?',
      'schedule' => 'Bạn muốn NaBi theo dõi việc hoàn thành lịch chăm sóc hôm nay không?',
      'nutrition' => 'Bạn có muốn cập nhật thêm thói quen ăn uống gần đây không?',
      'labs' => 'Nếu có kết quả xét nghiệm mới, bạn có muốn bổ sung vào hồ sơ không?',
      _ => 'Bạn có muốn bổ sung thêm dữ liệu sức khỏe gần đây không?',
    };
  }

  Map<String, Object?> _decodeObject(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
      text = text.replaceFirst(RegExp(r'\s*```$'), '');
    }
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('NaBi Care AI response is not a JSON object.');
    }
    return decoded;
  }
}
