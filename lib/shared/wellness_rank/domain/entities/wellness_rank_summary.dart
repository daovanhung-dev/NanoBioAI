class WellnessRankSummary {
  final String rankCode;
  final int rankLevel;
  final String title;
  final int experiencePoints;
  final int currentRankThreshold;
  final int? nextRankThreshold;
  final int experienceToNextRank;
  final int rankProgressExp;
  final int rankProgressTarget;
  final DateTime computedAt;
  final DateTime? nextDecayAt;
  final DateTime lastSyncedAt;
  final bool isStale;

  const WellnessRankSummary({
    required this.rankCode,
    required this.rankLevel,
    required this.title,
    required this.experiencePoints,
    required this.currentRankThreshold,
    required this.nextRankThreshold,
    required this.experienceToNextRank,
    required this.rankProgressExp,
    required this.rankProgressTarget,
    required this.computedAt,
    required this.nextDecayAt,
    required this.lastSyncedAt,
    this.isStale = false,
  });

  factory WellnessRankSummary.fromMap(
    Map<String, Object?> map, {
    DateTime? lastSyncedAt,
    bool isStale = false,
  }) {
    final computedAt = _date(map['computed_at']) ?? DateTime.now().toUtc();
    return WellnessRankSummary(
      rankCode: map['rank_code']?.toString() ?? 'wellness_rank_1',
      rankLevel: _integer(map['rank_level'], fallback: 1),
      title: map['title']?.toString() ?? 'Mầm An Nhiên',
      experiencePoints: _integer(map['experience_points']),
      currentRankThreshold: _integer(map['current_rank_threshold']),
      nextRankThreshold: _nullableInteger(map['next_rank_threshold']),
      experienceToNextRank: _integer(map['experience_to_next_rank']),
      rankProgressExp: _integer(map['rank_progress_exp']),
      rankProgressTarget: _integer(map['rank_progress_target']),
      computedAt: computedAt,
      nextDecayAt: _date(map['next_decay_at']),
      lastSyncedAt: lastSyncedAt ?? _date(map['synced_at']) ?? computedAt,
      isStale: isStale,
    );
  }

  factory WellnessRankSummary.fromCache(Map<String, Object?> row) =>
      WellnessRankSummary.fromMap(
        row,
        lastSyncedAt: _date(row['synced_at']),
        isStale: true,
      );

  Map<String, Object?> toCacheMap({required String userId}) => {
    'user_id': userId,
    'rank_code': rankCode,
    'rank_level': rankLevel,
    'title': title,
    'experience_points': experiencePoints,
    'current_rank_threshold': currentRankThreshold,
    'next_rank_threshold': nextRankThreshold,
    'experience_to_next_rank': experienceToNextRank,
    'rank_progress_exp': rankProgressExp,
    'rank_progress_target': rankProgressTarget,
    'computed_at': computedAt.toUtc().toIso8601String(),
    'next_decay_at': nextDecayAt?.toUtc().toIso8601String(),
    'synced_at': lastSyncedAt.toUtc().toIso8601String(),
  };

  WellnessRankSummary asStale() => WellnessRankSummary(
    rankCode: rankCode,
    rankLevel: rankLevel,
    title: title,
    experiencePoints: experiencePoints,
    currentRankThreshold: currentRankThreshold,
    nextRankThreshold: nextRankThreshold,
    experienceToNextRank: experienceToNextRank,
    rankProgressExp: rankProgressExp,
    rankProgressTarget: rankProgressTarget,
    computedAt: computedAt,
    nextDecayAt: nextDecayAt,
    lastSyncedAt: lastSyncedAt,
    isStale: true,
  );
}

int _integer(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _nullableInteger(Object? value) {
  if (value == null) return null;
  return _integer(value);
}

DateTime? _date(Object? value) {
  if (value is DateTime) return value.toUtc();
  return DateTime.tryParse(value?.toString() ?? '')?.toUtc();
}
