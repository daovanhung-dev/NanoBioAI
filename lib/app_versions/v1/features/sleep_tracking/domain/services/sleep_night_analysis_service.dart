import 'dart:math' as math;

import '../entities/sleep_morning_checkin.dart';
import '../entities/sleep_night_analysis.dart';
import '../entities/sleep_safety_event.dart';
import '../entities/sleep_safety_session.dart';

class SleepNightInput {
  const SleepNightInput({required this.session, required this.events});
  final SleepSafetySession session;
  final List<SleepSafetyEvent> events;
}

class SleepNightAnalysisService {
  const SleepNightAnalysisService();
  static const formulaVersion = 'm31_sleep_wellness_v1_2026_08';

  SleepNightAnalysis calculate({
    required SleepSafetySession session,
    required List<SleepSafetyEvent> events,
    List<SleepNightInput> previousNights = const [],
    SleepMorningCheckin? morningCheckin,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final basic = _basicMetrics(session, events);
    final distribution = <String, int>{};
    for (final event in events) {
      distribution.update(
        event.eventType.name,
        (v) => v + 1,
        ifAbsent: () => 1,
      );
    }
    final history = <SleepNightInput>[
      ...previousNights,
      SleepNightInput(session: session, events: events),
    ]..sort((a, b) => a.session.startedAt.compareTo(b.session.startedAt));
    final recentHistory = history.length <= 7
        ? history
        : history.sublist(history.length - 7);
    final trend = _trendMetrics(recentHistory, currentSessionId: session.id);
    final metrics = <String, double>{...basic};

    if (morningCheckin != null) {
      final timeInBed = morningCheckin.timeInBedMinutes.toDouble();
      final sleepMinutes = morningCheckin.estimatedSleepMinutes.toDouble();
      final sleepHours = sleepMinutes / 60.0;
      metrics['estimatedTotalSleepMinutes'] = sleepMinutes;
      metrics['selfReportedSleepEfficiency'] = timeInBed <= 0
          ? 0
          : _clamp01(sleepMinutes / timeInBed);
      metrics['selfReportedFragmentationRate'] = sleepHours <= 0
          ? 0
          : morningCheckin.rememberedAwakenings / sleepHours;
      metrics['restfulnessScore'] =
          _clamp01(morningCheckin.restfulness / 5.0) * 100;
    }

    final dataQuality = _dataQuality(session, events);
    final attention = _attentionScore(
      weightedDisturbance: metrics['weightedDisturbanceIndex'] ?? 0,
      noResponseRate: metrics['noResponseRate'] ?? 0,
      escalationRate: metrics['escalationRate'] ?? 0,
      clustering: metrics['alertClusteringIndex'] ?? 0,
    );
    final baselineDeviation = trend['personalBaselineDeviation'] ?? 0;
    final consistency =
        (trend['monitoringDurationConsistency'] ?? 0.5) * 0.5 +
        (trend['startTimeConsistency'] ?? 0.5) * 0.5;
    final wellness = _clamp100(
      100 -
          attention * 0.55 -
          (metrics['noResponseRate'] ?? 0) * 15 -
          (metrics['escalationRate'] ?? 0) * 15 -
          math.min(1.0, baselineDeviation.abs()) * 10 +
          consistency * 8,
    );

    return SleepNightAnalysis(
      sessionId: session.id,
      userId: session.userId,
      formulaVersion: formulaVersion,
      startedAt: session.startedAt,
      endedAt: session.endedAt,
      metrics: metrics,
      eventDistribution: distribution,
      trend: trend,
      dataQualityScore: dataQuality,
      safetyAttentionScore: attention,
      sleepWellnessScore: wellness,
      morningCheckin: morningCheckin,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  Map<String, double> _basicMetrics(
    SleepSafetySession session,
    List<SleepSafetyEvent> events,
  ) {
    final end = session.endedAt ?? DateTime.now();
    final durationMinutes = math
        .max(0.0, end.difference(session.startedAt).inSeconds / 60.0)
        .toDouble();
    final hours = math.max(durationMinutes / 60.0, 1 / 60.0).toDouble();
    final eventCount = events.length.toDouble();
    final high = events.where((e) => e.severity == 'high').length;
    final repeated = events.where((e) => e.repetitionCount > 1).length;
    final repeatedPatterns = events
        .where(
          (e) => e.eventType == SleepSafetyEventType.repeatedSuspiciousPattern,
        )
        .length;
    final responded = events
        .where(
          (e) =>
              e.response == SleepSafetyResponse.ok ||
              e.response == SleepSafetyResponse.needHelp,
        )
        .length;
    final noResponse = events
        .where((e) => e.response == SleepSafetyResponse.noResponse)
        .length;
    final needHelp = events
        .where((e) => e.response == SleepSafetyResponse.needHelp)
        .length;
    final escalated = events.where((e) => e.escalationRequired).length;
    final actionable = events
        .where((e) => e.response != SleepSafetyResponse.none)
        .length;

    final latencies = <double>[];
    for (final event in events) {
      final responseAt = event.responseAt;
      if (responseAt != null && !responseAt.isBefore(event.detectedAt)) {
        latencies.add(
          responseAt.difference(event.detectedAt).inMilliseconds / 1000.0,
        );
      }
    }
    final sortedTimes = events.map((e) => e.detectedAt).toList()..sort();
    final interEventMinutes = <double>[];
    for (var i = 1; i < sortedTimes.length; i++) {
      interEventMinutes.add(
        sortedTimes[i].difference(sortedTimes[i - 1]).inSeconds / 60.0,
      );
    }
    final gapBoundaries = <DateTime>[session.startedAt, ...sortedTimes, end]
      ..sort();
    var longestGap = durationMinutes;
    if (gapBoundaries.length > 1) {
      longestGap = 0;
      for (var i = 1; i < gapBoundaries.length; i++) {
        longestGap = math
            .max(
              longestGap,
              gapBoundaries[i].difference(gapBoundaries[i - 1]).inSeconds /
                  60.0,
            )
            .toDouble();
      }
    }

    final weightedDisturbance =
        events.fold<double>(0, (sum, event) {
          final severityWeight = event.severity == 'high' ? 1.6 : 1.0;
          final confidenceWeight = 0.5 + _clamp01(event.confidence) * 0.5;
          final energyWeight =
              1.0 + math.min(event.relativeEnergy, 8.0).toDouble() / 8.0;
          final repetitionWeight =
              1.0 +
              math.min(math.max(event.repetitionCount - 1, 0), 4).toDouble() *
                  0.15;
          return sum +
              severityWeight *
                  confidenceWeight *
                  energyWeight *
                  repetitionWeight;
        }) /
        hours;

    final clustering = _maxEventsInWindow(
      sortedTimes,
      const Duration(minutes: 30),
    );
    final distribution = <String, int>{};
    for (final event in events) {
      distribution.update(
        event.eventType.name,
        (v) => v + 1,
        ifAbsent: () => 1,
      );
    }

    return {
      'monitoringDurationMinutes': durationMinutes,
      'eventCount': eventCount,
      'eventsPerHour': eventCount / hours,
      'highSeverityCount': high.toDouble(),
      'highSeverityRatio': _ratio(high, events.length),
      'averageConfidence': _average(events.map((e) => e.confidence)),
      'peakConfidence': _max(events.map((e) => e.confidence)),
      'averageRelativeEnergy': _average(events.map((e) => e.relativeEnergy)),
      'peakRelativeEnergy': _max(events.map((e) => e.relativeEnergy)),
      'averageBaselineDelta': _average(events.map((e) => e.baselineDelta)),
      'peakBaselineDelta': _max(events.map((e) => e.baselineDelta)),
      'repeatedEventRatio': _ratio(repeated, events.length),
      'repetitionBurden': events.isEmpty
          ? 0
          : events.fold<double>(
                  0,
                  (sum, e) =>
                      sum + math.max(e.repetitionCount - 1, 0).toDouble(),
                ) /
                events.length,
      'repeatedPatternShare': _ratio(repeatedPatterns, events.length),
      'acousticDiversityIndex': _normalizedEntropy(distribution),
      'alertClusteringIndex': events.isEmpty ? 0 : clustering / events.length,
      'longestAlertFreeMinutes': longestGap,
      'medianInterEventMinutes': _median(interEventMinutes),
      'responseRate': _ratio(responded, actionable),
      'noResponseRate': _ratio(noResponse, actionable),
      'needHelpRate': _ratio(needHelp, actionable),
      'escalationRate': _ratio(escalated, actionable),
      'averageResponseLatencySeconds': _average(latencies),
      'medianResponseLatencySeconds': _median(latencies),
      'weightedDisturbanceIndex': weightedDisturbance,
      'quietWindowRatioProxy': durationMinutes <= 0
          ? 0
          : _clamp01(longestGap / durationMinutes),
      'maxRepetitionCount': _max(
        events.map((e) => e.repetitionCount.toDouble()),
      ),
      'responsiveEventCount': responded.toDouble(),
      'unresponsiveEventCount': noResponse.toDouble(),
      'resolvedEventCount': (responded + noResponse).toDouble(),
      'attentionEventCount': events
          .where((e) => e.severity != 'high')
          .length
          .toDouble(),
      'eventTypeCount': distribution.length.toDouble(),
    };
  }

  Map<String, double> _trendMetrics(
    List<SleepNightInput> nights, {
    required String currentSessionId,
  }) {
    if (nights.isEmpty) return const {};
    final eventRates = <double>[];
    final disturbances = <double>[];
    final durations = <double>[];
    final startMinutes = <double>[];
    final quality = <double>[];
    for (final night in nights) {
      final m = _basicMetrics(night.session, night.events);
      eventRates.add(m['eventsPerHour'] ?? 0);
      disturbances.add(m['weightedDisturbanceIndex'] ?? 0);
      durations.add(m['monitoringDurationMinutes'] ?? 0);
      startMinutes.add(
        (night.session.startedAt.hour * 60 + night.session.startedAt.minute)
            .toDouble(),
      );
      quality.add(_dataQuality(night.session, night.events));
    }
    final currentIndex = nights.indexWhere(
      (n) => n.session.id == currentSessionId,
    );
    final resolvedIndex = currentIndex < 0 ? nights.length - 1 : currentIndex;
    final currentDisturbance = disturbances[resolvedIndex];
    final previousDisturbances = <double>[
      for (var i = 0; i < disturbances.length; i++)
        if (i != resolvedIndex) disturbances[i],
    ];
    final previousMedian = _median(previousDisturbances);
    final mad = _median(
      previousDisturbances.map((v) => (v - previousMedian).abs()),
    );
    final baselineDeviation = previousDisturbances.isEmpty
        ? 0.0
        : (currentDisturbance - previousMedian) /
              math.max(mad, 0.25).toDouble();
    final recent = disturbances.length <= 3
        ? disturbances
        : disturbances.sublist(disturbances.length - 3);
    final older = disturbances.length <= 3
        ? const <double>[]
        : disturbances.sublist(0, disturbances.length - 3);
    final recentVsBaseline = older.isEmpty
        ? 0.0
        : (_median(recent) - _median(older)) /
              math.max(_median(older).abs(), 0.25).toDouble();

    return {
      'nightCount': nights.length.toDouble(),
      'eventRateTrend': _linearSlope(eventRates),
      'disturbanceTrend': _linearSlope(disturbances),
      'monitoringDurationConsistency': _consistency(durations),
      'startTimeConsistency': _circularTimeConsistency(startMinutes),
      'personalBaselineDeviation': baselineDeviation,
      'recentVsBaselineChange': recentVsBaseline,
      'trendConfidence': _clamp01((nights.length / 7.0) * _average(quality)),
      'sevenNightAverageEventRate': _average(eventRates),
      'sevenNightAverageDisturbance': _average(disturbances),
      'sevenNightAverageMonitoringMinutes': _average(durations),
    };
  }

  double _dataQuality(
    SleepSafetySession session,
    List<SleepSafetyEvent> events,
  ) {
    var score = 0.0;
    if (session.endedAt != null) score += 0.25;
    final end = session.endedAt ?? DateTime.now();
    final duration = end.difference(session.startedAt).inMinutes;
    if (duration >= 180) {
      score += 0.25;
    } else if (duration >= 60) {
      score += 0.15;
    } else if (duration > 0) {
      score += 0.05;
    }
    if (session.status != SleepSafetySessionStatus.failed) score += 0.2;
    final validEvents = events
        .where(
          (e) =>
              e.confidence.isFinite &&
              e.relativeEnergy.isFinite &&
              e.baselineDelta.isFinite &&
              !e.detectedAt.isBefore(session.startedAt),
        )
        .length;
    score += events.isEmpty ? 0.3 : 0.3 * validEvents / events.length;
    return _clamp01(score);
  }

  double _attentionScore({
    required double weightedDisturbance,
    required double noResponseRate,
    required double escalationRate,
    required double clustering,
  }) {
    final disturbanceScore = 100 * (1 - math.exp(-weightedDisturbance / 3.0));
    return _clamp100(
      disturbanceScore * 0.65 +
          _clamp01(noResponseRate) * 15 +
          _clamp01(escalationRate) * 15 +
          _clamp01(clustering) * 5,
    );
  }

  int _maxEventsInWindow(List<DateTime> sorted, Duration window) {
    var maxCount = 0;
    var left = 0;
    for (var right = 0; right < sorted.length; right++) {
      while (sorted[right].difference(sorted[left]) > window) {
        left++;
      }
      final count = right - left + 1;
      if (count > maxCount) maxCount = count;
    }
    return maxCount;
  }

  double _normalizedEntropy(Map<String, int> distribution) {
    final total = distribution.values.fold<int>(0, (a, b) => a + b);
    if (total <= 1 || distribution.length <= 1) return 0;
    var entropy = 0.0;
    for (final count in distribution.values) {
      final p = count / total;
      entropy -= p * math.log(p);
    }
    return _clamp01(entropy / math.log(distribution.length));
  }

  double _circularTimeConsistency(List<double> minuteValues) {
    if (minuteValues.length < 2) return minuteValues.isEmpty ? 0 : 1;
    var sinSum = 0.0, cosSum = 0.0;
    for (final minute in minuteValues) {
      final angle = minute / 1440.0 * 2 * math.pi;
      sinSum += math.sin(angle);
      cosSum += math.cos(angle);
    }
    return _clamp01(
      math.sqrt(sinSum * sinSum + cosSum * cosSum) / minuteValues.length,
    );
  }

  double _consistency(List<double> values) {
    if (values.length < 2) return values.isEmpty ? 0 : 1;
    final mean = _average(values);
    if (mean <= 0) return 0;
    final variance =
        values.fold<double>(
          0,
          (sum, v) => sum + math.pow(v - mean, 2).toDouble(),
        ) /
        values.length;
    return _clamp01(1 - math.sqrt(variance) / mean);
  }

  double _linearSlope(List<double> values) {
    if (values.length < 2) return 0;
    final meanX = (values.length - 1) / 2.0, meanY = _average(values);
    var numerator = 0.0, denominator = 0.0;
    for (var i = 0; i < values.length; i++) {
      final dx = i - meanX;
      numerator += dx * (values[i] - meanY);
      denominator += dx * dx;
    }
    return denominator == 0 ? 0 : numerator / denominator;
  }

  double _average(Iterable<double> values) {
    var count = 0, sum = 0.0;
    for (final value in values) {
      if (!value.isFinite) continue;
      count++;
      sum += value;
    }
    return count == 0 ? 0 : sum / count;
  }

  double _max(Iterable<double> values) {
    var found = false, result = 0.0;
    for (final value in values) {
      if (!value.isFinite) continue;
      if (!found || value > result) result = value;
      found = true;
    }
    return found ? result : 0;
  }

  double _median(Iterable<double> values) {
    final sorted = values.where((v) => v.isFinite).toList()..sort();
    if (sorted.isEmpty) return 0;
    final middle = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[middle]
        : (sorted[middle - 1] + sorted[middle]) / 2.0;
  }

  double _ratio(int numerator, int denominator) =>
      denominator <= 0 ? 0 : _clamp01(numerator / denominator);
  double _clamp01(num value) => value.toDouble().clamp(0.0, 1.0).toDouble();
  double _clamp100(num value) => value.toDouble().clamp(0.0, 100.0).toDouble();
}
