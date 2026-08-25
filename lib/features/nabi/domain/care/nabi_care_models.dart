import 'dart:convert';

enum NabiCareSeverity { info, low, medium, high }

enum NabiCareOverallStatus {
  stable,
  needsAttention,
  improving,
  insufficientData,
}

enum NabiCareChannelHint { inApp, localNotification, conversation }

enum NabiCareTrigger {
  appOpen,
  appResume,
  healthTrackingChanged,
  symptomChanged,
  medicationChanged,
  labChanged,
  taskChanged,
  dayStart,
  dayEnd,
  nearSleep,
  scoreChanged,
  returnAfterAbsence,
  manualReview,
}

enum NabiCareFeedbackType {
  helpful,
  notHelpful,
  notRelevant,
  alreadyDone,
  doLater,
  dismissed,
  completed,
}

class NabiCareEvidence {
  final String key;
  final Object? value;
  final String source;
  final String? unit;
  final DateTime? measuredAt;
  final bool fresh;

  const NabiCareEvidence({
    required this.key,
    required this.value,
    required this.source,
    this.unit,
    this.measuredAt,
    this.fresh = true,
  });

  Map<String, Object?> toJson() => {
        'key': key,
        'value': value,
        'source': source,
        if (unit != null) 'unit': unit,
        if (measuredAt != null) 'measured_at': measuredAt!.toIso8601String(),
        'fresh': fresh,
      };
}

class NabiCareDataQuality {
  final double completeness;
  final List<String> availableGroups;
  final List<String> missingGroups;
  final List<String> staleGroups;

  const NabiCareDataQuality({
    required this.completeness,
    this.availableGroups = const [],
    this.missingGroups = const [],
    this.staleGroups = const [],
  });

  Map<String, Object?> toJson() => {
        'completeness': completeness,
        'available_groups': availableGroups,
        'missing_groups': missingGroups,
        'stale_groups': staleGroups,
      };
}

class NabiCareSignal {
  final String code;
  final String title;
  final String description;
  final NabiCareSeverity severity;
  final double confidence;
  final List<String> evidenceKeys;
  final bool positive;

  const NabiCareSignal({
    required this.code,
    required this.title,
    required this.description,
    required this.severity,
    required this.confidence,
    required this.evidenceKeys,
    this.positive = false,
  });

  Map<String, Object?> toJson() => {
        'code': code,
        'title': title,
        'description': description,
        'severity': severity.name,
        'confidence': confidence,
        'evidence_keys': evidenceKeys,
        'positive': positive,
      };
}

class NabiCareObservation {
  final String title;
  final String detail;
  final NabiCareSeverity severity;
  final double confidence;
  final List<String> evidenceKeys;

  const NabiCareObservation({
    required this.title,
    required this.detail,
    required this.severity,
    required this.confidence,
    required this.evidenceKeys,
  });

  Map<String, Object?> toJson() => {
        'title': title,
        'detail': detail,
        'severity': severity.name,
        'confidence': confidence,
        'evidence_keys': evidenceKeys,
      };

  factory NabiCareObservation.fromJson(Map<String, Object?> json) {
    return NabiCareObservation(
      title: _text(json['title']) ?? 'Điểm cần theo dõi',
      detail: _text(json['detail']) ?? '',
      severity: _severity(json['severity']),
      confidence: _unitInterval(json['confidence']),
      evidenceKeys: _stringList(json['evidence_keys']),
    );
  }
}

class NabiCareAction {
  final String id;
  final String title;
  final String description;
  final int priority;
  final String? suggestedTime;
  final NabiCareChannelHint channelHint;
  final List<String> evidenceKeys;

  const NabiCareAction({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.channelHint,
    required this.evidenceKeys,
    this.suggestedTime,
  });

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'priority': priority,
        if (suggestedTime != null) 'suggested_time': suggestedTime,
        'channel_hint': channelHint.name,
        'evidence_keys': evidenceKeys,
      };

  factory NabiCareAction.fromJson(
    Map<String, Object?> json, {
    int index = 0,
  }) {
    return NabiCareAction(
      id: _text(json['id']) ?? 'care_action_$index',
      title: _text(json['title']) ?? 'Việc nhỏ cho hôm nay',
      description: _text(json['description']) ?? '',
      priority: _integer(json['priority'], fallback: index + 1)
          .clamp(1, 5)
          .toInt(),
      suggestedTime: _text(json['suggested_time']),
      channelHint: _channel(json['channel_hint']),
      evidenceKeys: _stringList(json['evidence_keys']),
    );
  }
}

class NabiCareQuestion {
  final String id;
  final String text;
  final String reason;

  const NabiCareQuestion({
    required this.id,
    required this.text,
    required this.reason,
  });

  Map<String, Object?> toJson() => {
        'id': id,
        'text': text,
        'reason': reason,
      };

  factory NabiCareQuestion.fromJson(
    Map<String, Object?> json, {
    int index = 0,
  }) {
    return NabiCareQuestion(
      id: _text(json['id']) ?? 'care_question_$index',
      text: _text(json['text']) ?? '',
      reason: _text(json['reason']) ?? '',
    );
  }
}

class NabiCareAttentionFlag {
  final String code;
  final String message;
  final NabiCareSeverity severity;
  final List<String> evidenceKeys;

  const NabiCareAttentionFlag({
    required this.code,
    required this.message,
    required this.severity,
    required this.evidenceKeys,
  });

  Map<String, Object?> toJson() => {
        'code': code,
        'message': message,
        'severity': severity.name,
        'evidence_keys': evidenceKeys,
      };

  factory NabiCareAttentionFlag.fromJson(
    Map<String, Object?> json, {
    int index = 0,
  }) {
    return NabiCareAttentionFlag(
      code: _text(json['code']) ?? 'attention_$index',
      message: _text(json['message']) ?? '',
      severity: _severity(json['severity']),
      evidenceKeys: _stringList(json['evidence_keys']),
    );
  }
}

class NabiCareAnalysis {
  final NabiCareOverallStatus overallStatus;
  final String summary;
  final List<NabiCareObservation> observations;
  final List<NabiCareAction> actions;
  final List<NabiCareQuestion> questions;
  final List<NabiCareAttentionFlag> attentionFlags;
  final List<String> missingData;
  final DateTime nextReviewAt;
  final String source;

  const NabiCareAnalysis({
    required this.overallStatus,
    required this.summary,
    required this.observations,
    required this.actions,
    required this.questions,
    required this.attentionFlags,
    required this.missingData,
    required this.nextReviewAt,
    required this.source,
  });

  Map<String, Object?> toJson() => {
        'overall_status': overallStatus.name,
        'summary': summary,
        'observations': observations.map((item) => item.toJson()).toList(),
        'care_actions': actions.map((item) => item.toJson()).toList(),
        'questions': questions.map((item) => item.toJson()).toList(),
        'attention_flags':
            attentionFlags.map((item) => item.toJson()).toList(),
        'missing_data': missingData,
        'next_review_at': nextReviewAt.toIso8601String(),
        'source': source,
      };

  factory NabiCareAnalysis.fromJson(Map<String, Object?> json) {
    final observationMaps = _mapList(json['observations']);
    final actionMaps = _mapList(json['care_actions']);
    final questionMaps = _mapList(json['questions']);
    final flagMaps = _mapList(json['attention_flags']);

    return NabiCareAnalysis(
      overallStatus: _status(json['overall_status']),
      summary: _text(json['summary']) ?? 'Nabi đang theo dõi dữ liệu cùng bạn.',
      observations: [
        for (final item in observationMaps) NabiCareObservation.fromJson(item),
      ],
      actions: [
        for (var index = 0; index < actionMaps.length; index++)
          NabiCareAction.fromJson(actionMaps[index], index: index),
      ],
      questions: [
        for (var index = 0; index < questionMaps.length; index++)
          NabiCareQuestion.fromJson(questionMaps[index], index: index),
      ],
      attentionFlags: [
        for (var index = 0; index < flagMaps.length; index++)
          NabiCareAttentionFlag.fromJson(flagMaps[index], index: index),
      ],
      missingData: _stringList(json['missing_data']),
      nextReviewAt:
          DateTime.tryParse(_text(json['next_review_at']) ?? '') ??
              DateTime.now().add(const Duration(hours: 12)),
      source: _text(json['source']) ?? 'unknown',
    );
  }
}

class NabiCareRawContext {
  final String actorKey;
  final Map<String, List<Map<String, Object?>>> rowsByTable;

  const NabiCareRawContext({
    required this.actorKey,
    required this.rowsByTable,
  });

  List<Map<String, Object?>> rows(String table) =>
      rowsByTable[table] ?? const <Map<String, Object?>>[];
}

class NabiCareSnapshot {
  static const schemaVersion = 1;

  final String actorKey;
  final String actorKind;
  final String membershipPlan;
  final DateTime generatedAt;
  final Map<String, Object?> profile;
  final Map<String, Object?> current;
  final Map<String, Object?> baselines;
  final Map<String, Object?> adherence;
  final List<Map<String, Object?>> conditions;
  final List<Map<String, Object?>> symptoms;
  final List<Map<String, Object?>> medications;
  final List<Map<String, Object?>> labs;
  final List<Map<String, Object?>> goals;
  final Map<String, NabiCareEvidence> evidence;
  final NabiCareDataQuality dataQuality;
  final List<NabiCareSignal> signals;

  const NabiCareSnapshot({
    required this.actorKey,
    required this.actorKind,
    required this.membershipPlan,
    required this.generatedAt,
    required this.profile,
    required this.current,
    required this.baselines,
    required this.adherence,
    required this.conditions,
    required this.symptoms,
    required this.medications,
    required this.labs,
    required this.goals,
    required this.evidence,
    required this.dataQuality,
    this.signals = const [],
  });

  NabiCareSnapshot withSignals(List<NabiCareSignal> nextSignals) {
    return NabiCareSnapshot(
      actorKey: actorKey,
      actorKind: actorKind,
      membershipPlan: membershipPlan,
      generatedAt: generatedAt,
      profile: profile,
      current: current,
      baselines: baselines,
      adherence: adherence,
      conditions: conditions,
      symptoms: symptoms,
      medications: medications,
      labs: labs,
      goals: goals,
      evidence: evidence,
      dataQuality: dataQuality,
      signals: nextSignals,
    );
  }

  Map<String, Object?> toAiPayload() => {
        'schema_version': schemaVersion,
        // Deliberately excludes actorKey, name, email, phone and avatar.
        'profile': profile,
        'current': current,
        'baselines': baselines,
        'adherence': adherence,
        'conditions': conditions,
        'symptoms': symptoms,
        'medications': medications,
        'labs': labs,
        'goals': goals,
        'signals': signals.map((item) => item.toJson()).toList(),
        'data_quality': dataQuality.toJson(),
        'evidence': evidence.values.map((item) => item.toJson()).toList(),
      };

  String fingerprint() {
    final canonical = jsonEncode(_canonicalize(toAiPayload()));
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(canonical)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}

class NabiCareResult {
  final NabiCareSnapshot snapshot;
  final NabiCareAnalysis analysis;
  final String fingerprint;
  final bool fromCache;

  const NabiCareResult({
    required this.snapshot,
    required this.analysis,
    required this.fingerprint,
    this.fromCache = false,
  });
}

class NabiCareCachedAnalysis {
  final String fingerprint;
  final NabiCareAnalysis analysis;
  final DateTime createdAt;

  const NabiCareCachedAnalysis({
    required this.fingerprint,
    required this.analysis,
    required this.createdAt,
  });
}

String? nabiCareText(Object? value) => _text(value);

double? nabiCareNumber(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

DateTime? nabiCareDate(Object? value) =>
    DateTime.tryParse(_text(value) ?? '');

String? _text(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _integer(Object? value, {int fallback = 0}) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _unitInterval(Object? value) {
  final number = value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0.5;
  return number.clamp(0.0, 1.0).toDouble();
}

List<String> _stringList(Object? value) {
  if (value is! List<Object?>) return const [];
  return value
      .map(_text)
      .whereType<String>()
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<Map<String, Object?>> _mapList(Object? value) {
  if (value is! List<Object?>) return const [];
  return value.whereType<Map<String, Object?>>().toList(growable: false);
}

NabiCareSeverity _severity(Object? value) {
  final name = _text(value)?.toLowerCase();
  return NabiCareSeverity.values.firstWhere(
    (item) => item.name.toLowerCase() == name,
    orElse: () => NabiCareSeverity.low,
  );
}

NabiCareOverallStatus _status(Object? value) {
  final normalized = (_text(value) ?? '').replaceAll('_', '').toLowerCase();
  return NabiCareOverallStatus.values.firstWhere(
    (item) => item.name.toLowerCase() == normalized,
    orElse: () => NabiCareOverallStatus.stable,
  );
}

NabiCareChannelHint _channel(Object? value) {
  final normalized = (_text(value) ?? '').replaceAll('_', '').toLowerCase();
  return NabiCareChannelHint.values.firstWhere(
    (item) => item.name.toLowerCase() == normalized,
    orElse: () => NabiCareChannelHint.inApp,
  );
}

Object? _canonicalize(Object? value) {
  if (value is Map<String, Object?>) {
    final keys = value.keys.toList()..sort();
    return <String, Object?>{
      for (final key in keys) key: _canonicalize(value[key]),
    };
  }
  if (value is List<Object?>) {
    return value.map(_canonicalize).toList(growable: false);
  }
  return value;
}
