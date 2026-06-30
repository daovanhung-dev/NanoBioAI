import 'dart:math' as math;

import '../entities/health_score_habits_models.dart';

class HealthScoreHabitsCalculator {
  const HealthScoreHabitsCalculator._();

  static HealthScoreHabitsResult calculate(HealthScoreInputSnapshot input) {
    final habitProgress = buildHabitProgress(input);
    final breakdown = _buildBreakdown(input);
    final dayScores = <int>[];
    final logsByDate = {for (final log in input.dailyLogs) log.date: log};

    for (final date in input.period.dateKeys) {
      final entries = input.completionEntries
          .where((entry) => entry.date == date && entry.isDue)
          .toList(growable: false);
      final log = logsByDate[date];
      final dayScore = _calculateDayScore(entries: entries, log: log);
      if (dayScore != null) dayScores.add(dayScore);
    }

    if (dayScores.isEmpty) {
      return HealthScoreHabitsResult.empty(period: input.period);
    }

    final periodScore = (dayScores.reduce((a, b) => a + b) / dayScores.length)
        .round();

    return HealthScoreHabitsResult(
      score: periodScore.clamp(0, 100).toInt(),
      formulaVersion: healthScoreHabitsFormulaVersion,
      period: input.period,
      hasInputs: true,
      breakdown: breakdown.where((item) => item.hasInput).toList(),
      habitProgress: habitProgress,
    );
  }

  static List<HealthScoreHabitProgressItem> buildHabitProgress(
    HealthScoreInputSnapshot input,
  ) {
    final dueEntries = input.completionEntries
        .where((entry) => entry.isDue)
        .toList(growable: false);
    final byCategory = <String, List<HealthScoreCompletionEntry>>{};
    for (final entry in dueEntries) {
      final code = _normalizeCode(entry.category);
      byCategory.putIfAbsent(code, () => []).add(entry);
    }

    final items = byCategory.entries.map((entry) {
      final completed = entry.value.where((item) => item.isCompleted).length;
      return HealthScoreHabitProgressItem(
        code: entry.key,
        label: _labelForCategory(entry.key),
        completedCount: completed,
        dueCount: entry.value.length,
      );
    }).toList();

    items.sort((a, b) {
      final dueCompare = b.dueCount.compareTo(a.dueCount);
      if (dueCompare != 0) return dueCompare;
      return a.code.compareTo(b.code);
    });
    return items;
  }

  static int? _calculateDayScore({
    required List<HealthScoreCompletionEntry> entries,
    required HealthScoreDailyLogEntry? log,
  }) {
    var weightedScore = 0.0;
    var activeWeight = 0.0;

    final tasks = entries
        .where((entry) => entry.group == HealthScoreCompletionGroup.tasksHabits)
        .toList(growable: false);
    if (tasks.isNotEmpty) {
      weightedScore += _completionRatio(tasks) * 45;
      activeWeight += 45;
    }

    final meals = entries
        .where((entry) => entry.group == HealthScoreCompletionGroup.meals)
        .toList(growable: false);
    if (meals.isNotEmpty) {
      weightedScore += _completionRatio(meals) * 25;
      activeWeight += 25;
    }

    if (log != null && log.waterMl > 0) {
      weightedScore += (log.waterMl / 2000).clamp(0, 1).toDouble() * 15;
      activeWeight += 15;
    }

    if (log != null && log.sleepHours > 0) {
      weightedScore += (log.sleepHours / 8).clamp(0, 1).toDouble() * 15;
      activeWeight += 15;
    }

    if (activeWeight == 0) return null;
    return ((weightedScore / activeWeight) * 100).round().clamp(0, 100).toInt();
  }

  static List<HealthScoreBreakdownItem> _buildBreakdown(
    HealthScoreInputSnapshot input,
  ) {
    final dueEntries = input.completionEntries
        .where((entry) => entry.isDue)
        .toList(growable: false);
    final tasks = dueEntries
        .where((entry) => entry.group == HealthScoreCompletionGroup.tasksHabits)
        .toList(growable: false);
    final meals = dueEntries
        .where((entry) => entry.group == HealthScoreCompletionGroup.meals)
        .toList(growable: false);
    final waterLogs = input.dailyLogs
        .where((log) => log.waterMl > 0)
        .toList(growable: false);
    final sleepLogs = input.dailyLogs
        .where((log) => log.sleepHours > 0)
        .toList(growable: false);

    return [
      _completionBreakdown(
        code: 'tasks_habits',
        label: 'Nhiem vu va thoi quen',
        weight: 45,
        entries: tasks,
      ),
      _completionBreakdown(
        code: 'meals',
        label: 'Bua an',
        weight: 25,
        entries: meals,
      ),
      _logBreakdown(
        code: 'water',
        label: 'Nuoc',
        weight: 15,
        logs: waterLogs,
        scoreForLog: (log) => (log.waterMl / 2000).clamp(0, 1).toDouble(),
        completedForLog: (log) => log.waterMl >= 2000,
      ),
      _logBreakdown(
        code: 'sleep',
        label: 'Giac ngu',
        weight: 15,
        logs: sleepLogs,
        scoreForLog: (log) => (log.sleepHours / 8).clamp(0, 1).toDouble(),
        completedForLog: (log) => log.sleepHours >= 8,
      ),
    ];
  }

  static HealthScoreBreakdownItem _completionBreakdown({
    required String code,
    required String label,
    required int weight,
    required List<HealthScoreCompletionEntry> entries,
  }) {
    final completed = entries.where((entry) => entry.isCompleted).length;
    return HealthScoreBreakdownItem(
      code: code,
      label: label,
      weight: weight,
      score: entries.isEmpty ? 0 : (_completionRatio(entries) * 100).round(),
      completedCount: completed,
      totalCount: entries.length,
    );
  }

  static HealthScoreBreakdownItem _logBreakdown({
    required String code,
    required String label,
    required int weight,
    required List<HealthScoreDailyLogEntry> logs,
    required double Function(HealthScoreDailyLogEntry log) scoreForLog,
    required bool Function(HealthScoreDailyLogEntry log) completedForLog,
  }) {
    if (logs.isEmpty) {
      return HealthScoreBreakdownItem(
        code: code,
        label: label,
        weight: weight,
        score: 0,
        completedCount: 0,
        totalCount: 0,
      );
    }

    final totalScore = logs.fold<double>(
      0,
      (sum, log) => sum + scoreForLog(log),
    );
    final completed = logs.where(completedForLog).length;
    return HealthScoreBreakdownItem(
      code: code,
      label: label,
      weight: weight,
      score: ((totalScore / logs.length) * 100).round().clamp(0, 100).toInt(),
      completedCount: completed,
      totalCount: logs.length,
    );
  }

  static double _completionRatio(List<HealthScoreCompletionEntry> entries) {
    if (entries.isEmpty) return 0;
    final completed = entries.where((entry) => entry.isCompleted).length;
    return completed / entries.length;
  }

  static String _normalizeCode(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return 'habit';
    return normalized.replaceAll(RegExp(r'[^a-z0-9_]+'), '_');
  }

  static String _labelForCategory(String code) {
    const labels = <String, String>{
      'meal': 'Bua an',
      'water': 'Nuoc',
      'body': 'Van dong',
      'mind': 'Tinh than',
      'brain': 'Tap trung',
      'sleep': 'Giac ngu',
      'routine': 'Nhip sinh hoat',
      'health': 'Suc khoe',
      'habit': 'Thoi quen',
    };
    return labels[code] ?? _titleCase(code.replaceAll('_', ' '));
  }

  static String _titleCase(String value) {
    return value
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              part[0].toUpperCase() + part.substring(math.min(1, part.length)),
        )
        .join(' ');
  }
}
