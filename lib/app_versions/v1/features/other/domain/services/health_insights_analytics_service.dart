import '../entities/health_insights_entity.dart';

class HealthInsightsAnalyticsService {
  final DateTime Function() _now;

  HealthInsightsAnalyticsService({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  HealthInsightsEntity build({
    required String fullName,
    required double bmi,
    required HealthInsightsHistoryEntity history,
    required HealthInsightsContextData context,
    required HealthInsightsRange range,
  }) {
    final today = _dateOnly(_now());
    final currentStart = today.subtract(Duration(days: range.days - 1));
    final previousEnd = currentStart.subtract(const Duration(days: 1));
    final previousStart = previousEnd.subtract(Duration(days: range.days - 1));

    final logs = [...history.logs]..sort((a, b) => a.date.compareTo(b.date));
    final adherence = [...history.adherence]
      ..sort((a, b) => a.date.compareTo(b.date));

    final currentLogs = logs
        .where((item) => _inRange(item.date, currentStart, today))
        .toList(growable: false);
    final previousLogs = logs
        .where((item) => _inRange(item.date, previousStart, previousEnd))
        .toList(growable: false);
    final currentAdherence = adherence
        .where((item) => _inRange(item.date, currentStart, today))
        .toList(growable: false);
    final previousAdherence = adherence
        .where((item) => _inRange(item.date, previousStart, previousEnd))
        .toList(growable: false);

    final metrics = <HealthMetricSummary>[
      _buildLogMetric(
        type: HealthMetricType.healthScore,
        isCore: true,
        currentLogs: currentLogs,
        previousLogs: previousLogs,
        extract: (item) => item.dailyScore?.toDouble(),
        isValid: (value) => value > 0 && value <= 100,
        todayOverride: context.todayHealthScore?.toDouble(),
        expectedDays: range.days,
        today: today,
      ),
      _buildLogMetric(
        type: HealthMetricType.sleep,
        isCore: true,
        currentLogs: currentLogs,
        previousLogs: previousLogs,
        extract: (item) => item.sleepHours,
        isValid: (value) => value >= 0 && value <= 24,
        todayOverride: context.todaySleepHours,
        expectedDays: range.days,
        today: today,
      ),
      _buildLogMetric(
        type: HealthMetricType.water,
        isCore: true,
        currentLogs: currentLogs,
        previousLogs: previousLogs,
        extract: (item) => item.waterMl?.toDouble(),
        isValid: (value) => value >= 0 && value <= 20000,
        todayOverride: context.todayWaterMl?.toDouble(),
        expectedDays: range.days,
        today: today,
      ),
      _buildLogMetric(
        type: HealthMetricType.steps,
        isCore: true,
        currentLogs: currentLogs,
        previousLogs: previousLogs,
        extract: (item) => item.stepsCount?.toDouble(),
        isValid: (value) => value >= 0 && value <= 200000,
        todayOverride: context.todaySteps?.toDouble(),
        expectedDays: range.days,
        today: today,
      ),
      _buildLogMetric(
        type: HealthMetricType.calories,
        isCore: true,
        currentLogs: currentLogs,
        previousLogs: previousLogs,
        extract: (item) => item.calories?.toDouble(),
        isValid: (value) => value >= 0 && value <= 30000,
        todayOverride: context.todayCaloriesLogged?.toDouble(),
        expectedDays: range.days,
        today: today,
      ),
      _buildLogMetric(
        type: HealthMetricType.stress,
        isCore: true,
        currentLogs: currentLogs,
        previousLogs: previousLogs,
        extract: (item) => item.stressLevel?.toDouble(),
        isValid: (value) => value >= 0 && value <= 100,
        todayOverride: context.todayStressLevel?.toDouble(),
        expectedDays: range.days,
        today: today,
      ),
      _buildLogMetric(
        type: HealthMetricType.weight,
        isCore: true,
        currentLogs: currentLogs,
        previousLogs: previousLogs,
        extract: (item) => item.weightKg,
        isValid: (value) => value > 0 && value <= 500,
        todayOverride: context.todayWeightKg,
        expectedDays: range.days,
        today: today,
      ),
      _buildLogMetric(
        type: HealthMetricType.heartRate,
        isCore: false,
        currentLogs: currentLogs,
        previousLogs: previousLogs,
        extract: (item) => item.heartRateBpm?.toDouble(),
        isValid: (value) => value > 0 && value <= 300,
        todayOverride: context.todayHeartRateBpm?.toDouble(),
        expectedDays: range.days,
        today: today,
      ),
      _buildLogMetric(
        type: HealthMetricType.oxygen,
        isCore: false,
        currentLogs: currentLogs,
        previousLogs: previousLogs,
        extract: (item) => item.oxygenSaturation,
        isValid: (value) => value > 0 && value <= 100,
        todayOverride: context.todayOxygenSaturation,
        expectedDays: range.days,
        today: today,
      ),
      _buildMoodMetric(
        currentLogs: currentLogs,
        todayMood: context.todayMood,
        expectedDays: range.days,
        today: today,
      ),
      _buildAdherenceMetric(
        type: HealthMetricType.taskCompletion,
        current: currentAdherence,
        previous: previousAdherence,
        extract: (item) => item.taskCompletionRate,
        todayOverride: context.totalTasks > 0
            ? context.completedTasks / context.totalTasks
            : null,
        expectedDays: range.days,
        today: today,
      ),
      _buildAdherenceMetric(
        type: HealthMetricType.mealCompletion,
        current: currentAdherence,
        previous: previousAdherence,
        extract: (item) => item.mealCompletionRate,
        todayOverride: context.totalMeals > 0
            ? context.completedMeals / context.totalMeals
            : null,
        expectedDays: range.days,
        today: today,
      ),
    ];

    final coreMetrics = metrics.where((item) => item.isCore).toList();
    final availableCore = coreMetrics.where((item) => item.hasValue).length;
    final completeness = coreMetrics.isEmpty
        ? 0.0
        : availableCore / coreMetrics.length;

    final missingMetrics = coreMetrics
        .where(
          (item) =>
              !item.hasValue || item.freshness == HealthDataFreshness.stale,
        )
        .map((item) => item.type)
        .toList(growable: false);

    final changes = _buildChanges(metrics);
    final weeklySummary = _buildWeeklySummary(
      logs: logs,
      adherence: adherence,
      today: today,
    );
    final habitSummary = _buildHabitSummary(
      logs: logs,
      adherence: adherence,
      today: today,
      currentStreak: context.selfCareStreak,
    );

    final scoreMetric = _metric(metrics, HealthMetricType.healthScore);
    final healthScore = scoreMetric?.currentValue?.round();
    final previousHealthScore = scoreMetric?.previousPeriodAverage?.round();
    final healthScoreDelta = scoreMetric?.delta;

    final signals = _buildSignals(
      metrics: metrics,
      context: context,
      completeness: completeness,
      missingMetrics: missingMetrics,
      healthScoreDelta: healthScoreDelta,
      habitSummary: habitSummary,
    );
    final actions = _buildActions(
      recommendations: context.recommendations,
      missingMetrics: missingMetrics,
      weeklySummary: weeklySummary,
    );

    final timeline = context.timeline
        .take(8)
        .map(
          (item) => HealthTimelineEntry(
            id: item.id,
            timeLabel: item.timeLabel,
            title: item.title,
            subtitle: item.subtitle,
            category: item.category,
            isCompleted: item.isCompleted,
          ),
        )
        .toList(growable: false);

    final lastUpdatedAt = _latestMetricDate(metrics) ?? _latestLogDate(logs);

    return HealthInsightsEntity(
      userId: history.userId,
      fullName: fullName,
      bmi: bmi,
      generatedAt: _now(),
      lastUpdatedAt: lastUpdatedAt,
      range: range,
      overallFreshness: _freshness(lastUpdatedAt, today),
      healthScore: healthScore,
      previousHealthScore: previousHealthScore,
      healthScoreDelta: healthScoreDelta,
      dataCompleteness: completeness.clamp(0, 1).toDouble(),
      coreMetricsAvailable: availableCore,
      coreMetricsExpected: coreMetrics.length,
      metrics: metrics,
      changes: changes,
      signals: signals,
      missingMetrics: missingMetrics,
      actions: actions,
      weeklySummary: weeklySummary,
      habitSummary: habitSummary,
      timeline: timeline,
    );
  }

  HealthMetricSummary _buildLogMetric({
    required HealthMetricType type,
    required bool isCore,
    required List<HealthLogEntry> currentLogs,
    required List<HealthLogEntry> previousLogs,
    required double? Function(HealthLogEntry item) extract,
    required bool Function(double value) isValid,
    required double? todayOverride,
    required int expectedDays,
    required DateTime today,
  }) {
    final currentPoints = <String, HealthMetricPoint>{};
    DateTime? latestRecordedAt;

    for (final item in currentLogs) {
      final value = extract(item);
      if (value == null || !value.isFinite || !isValid(value)) continue;
      currentPoints[_dateKey(item.date)] = HealthMetricPoint(
        date: _dateOnly(item.date),
        value: value,
      );
      latestRecordedAt = _later(latestRecordedAt, item.updatedAt ?? item.date);
    }

    if (todayOverride != null &&
        todayOverride.isFinite &&
        isValid(todayOverride)) {
      currentPoints[_dateKey(today)] = HealthMetricPoint(
        date: today,
        value: todayOverride,
      );
      latestRecordedAt = _later(latestRecordedAt, _now());
    }

    final previousPoints = <HealthMetricPoint>[];
    for (final item in previousLogs) {
      final value = extract(item);
      if (value == null || !value.isFinite || !isValid(value)) continue;
      previousPoints.add(
        HealthMetricPoint(date: _dateOnly(item.date), value: value),
      );
    }

    final series = currentPoints.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    previousPoints.sort((a, b) => a.date.compareTo(b.date));

    final currentValues = series.map((item) => item.value).toList();
    final previousValues = previousPoints.map((item) => item.value).toList();
    final currentAverage = _average(currentValues);
    final previousAverage = _average(previousValues);
    final delta = currentAverage != null && previousAverage != null
        ? currentAverage - previousAverage
        : null;
    final deltaPercent = previousAverage != null &&
            delta != null &&
            previousAverage.abs() > 0.000001
        ? (delta / previousAverage.abs()) * 100
        : null;

    return HealthMetricSummary(
      type: type,
      isCore: isCore,
      currentValue: series.isEmpty ? null : series.last.value,
      currentText: null,
      periodAverage: currentAverage,
      previousPeriodAverage: previousAverage,
      minimum: _minimum(currentValues),
      maximum: _maximum(currentValues),
      delta: delta,
      deltaPercent: deltaPercent,
      trend: _trend(currentAverage, previousAverage),
      confidence: _confidence(
        expectedDays: expectedDays,
        currentSamples: currentValues.length,
        previousSamples: previousValues.length,
      ),
      freshness: _freshness(latestRecordedAt, today),
      sampleCount: currentValues.length,
      previousSampleCount: previousValues.length,
      latestRecordedAt: latestRecordedAt,
      series: series,
    );
  }

  HealthMetricSummary _buildMoodMetric({
    required List<HealthLogEntry> currentLogs,
    required String? todayMood,
    required int expectedDays,
    required DateTime today,
  }) {
    final values = <String>[];
    DateTime? latest;

    for (final item in currentLogs) {
      final mood = item.mood?.trim() ?? '';
      if (mood.isEmpty) continue;
      values.add(mood);
      latest = _later(latest, item.updatedAt ?? item.date);
    }

    final override = todayMood?.trim() ?? '';
    var currentText = values.isEmpty ? null : values.last;
    if (override.isNotEmpty) {
      currentText = override;
      if (currentLogs.isEmpty ||
          _dateOnly(currentLogs.last.date) != _dateOnly(today)) {
        values.add(override);
      } else if (values.isEmpty || values.last != override) {
        values.add(override);
      }
      latest = _later(latest, _now());
    }

    return HealthMetricSummary(
      type: HealthMetricType.mood,
      isCore: true,
      currentValue: null,
      currentText: currentText,
      periodAverage: null,
      previousPeriodAverage: null,
      minimum: null,
      maximum: null,
      delta: null,
      deltaPercent: null,
      trend: HealthTrendDirection.unknown,
      confidence: _coverageConfidence(expectedDays, values.length),
      freshness: _freshness(latest, today),
      sampleCount: values.length,
      previousSampleCount: 0,
      latestRecordedAt: latest,
      series: const [],
    );
  }

  HealthMetricSummary _buildAdherenceMetric({
    required HealthMetricType type,
    required List<HealthDailyAdherenceEntry> current,
    required List<HealthDailyAdherenceEntry> previous,
    required double? Function(HealthDailyAdherenceEntry item) extract,
    required double? todayOverride,
    required int expectedDays,
    required DateTime today,
  }) {
    final currentPoints = <String, HealthMetricPoint>{};
    for (final item in current) {
      final value = extract(item);
      if (value == null || !value.isFinite) continue;
      currentPoints[_dateKey(item.date)] = HealthMetricPoint(
        date: _dateOnly(item.date),
        value: value.clamp(0, 1).toDouble(),
      );
    }

    if (todayOverride != null && todayOverride.isFinite) {
      currentPoints[_dateKey(today)] = HealthMetricPoint(
        date: today,
        value: todayOverride.clamp(0, 1).toDouble(),
      );
    }

    final previousPoints = <HealthMetricPoint>[];
    for (final item in previous) {
      final value = extract(item);
      if (value == null || !value.isFinite) continue;
      previousPoints.add(
        HealthMetricPoint(
          date: _dateOnly(item.date),
          value: value.clamp(0, 1).toDouble(),
        ),
      );
    }

    final series = currentPoints.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    previousPoints.sort((a, b) => a.date.compareTo(b.date));
    final currentValues = series.map((item) => item.value).toList();
    final previousValues = previousPoints.map((item) => item.value).toList();
    final currentAverage = _average(currentValues);
    final previousAverage = _average(previousValues);
    final delta = currentAverage != null && previousAverage != null
        ? currentAverage - previousAverage
        : null;
    final deltaPercent = previousAverage != null &&
            delta != null &&
            previousAverage.abs() > 0.000001
        ? (delta / previousAverage.abs()) * 100
        : null;
    final latest = series.isEmpty ? null : series.last.date;

    return HealthMetricSummary(
      type: type,
      isCore: false,
      currentValue: series.isEmpty ? null : series.last.value,
      currentText: null,
      periodAverage: currentAverage,
      previousPeriodAverage: previousAverage,
      minimum: _minimum(currentValues),
      maximum: _maximum(currentValues),
      delta: delta,
      deltaPercent: deltaPercent,
      trend: _trend(currentAverage, previousAverage),
      confidence: _confidence(
        expectedDays: expectedDays,
        currentSamples: currentValues.length,
        previousSamples: previousValues.length,
      ),
      freshness: _freshness(latest, today),
      sampleCount: currentValues.length,
      previousSampleCount: previousValues.length,
      latestRecordedAt: latest,
      series: series,
    );
  }

  List<HealthChangeItem> _buildChanges(List<HealthMetricSummary> metrics) {
    final changes = metrics
        .where((item) => item.hasTrend && item.delta != null)
        .map(
          (item) => HealthChangeItem(
            metric: item.type,
            direction: item.trend,
            delta: item.delta ?? 0,
            deltaPercent: item.deltaPercent,
            confidence: item.confidence,
          ),
        )
        .toList();

    changes.sort((a, b) {
      final aMagnitude = (a.deltaPercent ?? a.delta).abs();
      final bMagnitude = (b.deltaPercent ?? b.delta).abs();
      return bMagnitude.compareTo(aMagnitude);
    });
    return changes.take(6).toList(growable: false);
  }

  List<HealthSignalItem> _buildSignals({
    required List<HealthMetricSummary> metrics,
    required HealthInsightsContextData context,
    required double completeness,
    required List<HealthMetricType> missingMetrics,
    required double? healthScoreDelta,
    required HealthHabitSummary habitSummary,
  }) {
    final items = <HealthSignalItem>[];

    for (final insight in context.insights.take(5)) {
      final risk = insight.riskLevel.trim().toLowerCase();
      final attention = risk == 'warning' ||
          risk == 'high' ||
          risk == 'critical' ||
          risk == 'danger' ||
          risk == 'error';
      items.add(
        HealthSignalItem(
          kind: attention ? HealthSignalKind.attention : HealthSignalKind.info,
          title: insight.title.trim().isEmpty
              ? 'Điều Nabi nhận thấy'
              : insight.title.trim(),
          message: insight.content.trim(),
          sourceLabel: 'Nabi',
        ),
      );
    }

    if (healthScoreDelta != null && healthScoreDelta <= -5) {
      items.add(
        const HealthSignalItem(
          kind: HealthSignalKind.attention,
          title: 'Nhịp chăm sóc đang chậm lại',
          message:
              'Điểm chăm sóc thấp hơn giai đoạn trước. Bạn có thể xem các chỉ số bên dưới để biết phần nào thay đổi nhiều nhất.',
          metric: HealthMetricType.healthScore,
          actionTarget: HealthActionTarget.weeklySummary,
        ),
      );
    }

    if (completeness < .5) {
      items.add(
        const HealthSignalItem(
          kind: HealthSignalKind.dataGap,
          title: 'Dữ liệu hôm nay còn thưa',
          message:
              'Thêm vài ghi nhận cơ bản sẽ giúp NanoBio phản ánh tình trạng của bạn đầy đủ hơn.',
          actionTarget: HealthActionTarget.healthTracking,
        ),
      );
    }

    for (final type in missingMetrics.take(3)) {
      items.add(
        HealthSignalItem(
          kind: HealthSignalKind.dataGap,
          title: 'Thiếu ${_metricName(type)}',
          message: _missingMessage(type),
          metric: type,
          actionTarget: _targetForMetric(type),
        ),
      );
    }

    if (context.selfCareStreak >= 3) {
      items.add(
        HealthSignalItem(
          kind: HealthSignalKind.progress,
          title: 'Bạn đang giữ nhịp rất đều',
          message:
              'Chuỗi tự chăm sóc hiện tại là ${context.selfCareStreak} ngày. Tiếp tục duy trì theo khả năng của bạn nhé.',
          actionTarget: HealthActionTarget.weeklySummary,
        ),
      );
    }

    final taskMetric = _metric(metrics, HealthMetricType.taskCompletion);
    if ((taskMetric?.periodAverage ?? 0) >= .8) {
      items.add(
        const HealthSignalItem(
          kind: HealthSignalKind.progress,
          title: 'Lịch trình đang được theo khá sát',
          message:
              'Tỷ lệ hoàn thành nhiệm vụ trong giai đoạn này đạt từ 80% trở lên.',
          metric: HealthMetricType.taskCompletion,
          actionTarget: HealthActionTarget.lifestyleSchedule,
        ),
      );
    }

    final mealMetric = _metric(metrics, HealthMetricType.mealCompletion);
    if ((mealMetric?.periodAverage ?? 0) >= .8) {
      items.add(
        const HealthSignalItem(
          kind: HealthSignalKind.progress,
          title: 'Nhịp thực đơn đang ổn định',
          message:
              'Tỷ lệ hoàn thành bữa ăn trong giai đoạn này đạt từ 80% trở lên.',
          metric: HealthMetricType.mealCompletion,
          actionTarget: HealthActionTarget.mealPlan,
        ),
      );
    }

    if (healthScoreDelta != null && healthScoreDelta >= 3) {
      items.add(
        const HealthSignalItem(
          kind: HealthSignalKind.progress,
          title: 'Điểm chăm sóc đang tăng',
          message:
              'Điểm chăm sóc trung bình cao hơn giai đoạn trước. Đây là tín hiệu về nhịp theo dõi và thói quen, không phải kết luận y khoa.',
          metric: HealthMetricType.healthScore,
          actionTarget: HealthActionTarget.weeklySummary,
        ),
      );
    }

    if (completeness >= .75 && habitSummary.careDays7 >= 4) {
      items.add(
        const HealthSignalItem(
          kind: HealthSignalKind.progress,
          title: 'Dữ liệu theo dõi đang khá đầy đủ',
          message:
              'Bạn đã duy trì ghi nhận đủ đều để NanoBio hiển thị xu hướng đáng tin cậy hơn.',
          actionTarget: HealthActionTarget.healthTracking,
        ),
      );
    }

    return _dedupeSignals(items).take(10).toList(growable: false);
  }

  List<HealthActionItem> _buildActions({
    required List<HealthExternalRecommendation> recommendations,
    required List<HealthMetricType> missingMetrics,
    required HealthWeeklySummary weeklySummary,
  }) {
    final items = <HealthActionItem>[];

    for (final item in recommendations) {
      final description = item.description.trim();
      if (description.isEmpty) continue;
      final actionText = item.actionText.trim();
      items.add(
        HealthActionItem(
          title: item.title.trim().isEmpty ? 'Gợi ý từ Nabi' : item.title.trim(),
          description: description,
          actionLabel: actionText.isEmpty ? 'Mở theo dõi' : actionText,
          target: _targetForRecommendation(item),
          isRead: item.isRead,
        ),
      );
      if (items.length >= 3) return items;
    }

    for (final metric in missingMetrics) {
      final target = _targetForMetric(metric);
      if (target == HealthActionTarget.none ||
          items.any((item) => item.target == target)) {
        continue;
      }
      items.add(
        HealthActionItem(
          title: 'Bổ sung ${_metricName(metric)}',
          description:
              'Cập nhật dữ liệu còn thiếu để NanoBio theo dõi sát nhịp chăm sóc của bạn hơn.',
          actionLabel: 'Cập nhật',
          target: target,
          isRead: false,
        ),
      );
      if (items.length >= 3) return items;
    }

    if (weeklySummary.daysWithLogs > 0 &&
        !items.any((item) => item.target == HealthActionTarget.weeklySummary)) {
      items.add(
        const HealthActionItem(
          title: 'Xem lại 7 ngày gần nhất',
          description:
              'Đối chiếu những ngày đã ghi nhận để thấy nhịp chăm sóc nào đang được duy trì tốt.',
          actionLabel: 'Xem tổng kết',
          target: HealthActionTarget.weeklySummary,
          isRead: false,
        ),
      );
    }

    return items.take(3).toList(growable: false);
  }

  HealthWeeklySummary _buildWeeklySummary({
    required List<HealthLogEntry> logs,
    required List<HealthDailyAdherenceEntry> adherence,
    required DateTime today,
  }) {
    final start = today.subtract(const Duration(days: 6));
    final weekLogs = logs
        .where((item) => _inRange(item.date, start, today))
        .toList(growable: false);
    final weekAdherence = adherence
        .where((item) => _inRange(item.date, start, today))
        .toList(growable: false);

    final scores = <_DatedValue>[];
    final sleep = <double>[];
    final water = <double>[];
    final steps = <double>[];
    final stress = <double>[];

    for (final item in weekLogs) {
      final score = item.dailyScore;
      if (score != null && score > 0 && score <= 100) {
        scores.add(_DatedValue(date: item.date, value: score.toDouble()));
      }
      final sleepValue = item.sleepHours;
      if (sleepValue != null && sleepValue.isFinite && sleepValue >= 0) {
        sleep.add(sleepValue);
      }
      final waterValue = item.waterMl;
      if (waterValue != null && waterValue >= 0) {
        water.add(waterValue.toDouble());
      }
      final stepValue = item.stepsCount;
      if (stepValue != null && stepValue >= 0) {
        steps.add(stepValue.toDouble());
      }
      final stressValue = item.stressLevel;
      if (stressValue != null && stressValue >= 0) {
        stress.add(stressValue.toDouble());
      }
    }

    _DatedValue? best;
    for (final score in scores) {
      if (best == null || score.value > best.value) best = score;
    }

    var completedTasks = 0;
    var totalTasks = 0;
    var completedMeals = 0;
    var totalMeals = 0;
    for (final item in weekAdherence) {
      completedTasks += item.completedTasks;
      totalTasks += item.totalTasks;
      completedMeals += item.completedMeals;
      totalMeals += item.totalMeals;
    }

    return HealthWeeklySummary(
      daysWithLogs: weekLogs.map((item) => _dateKey(item.date)).toSet().length,
      averageScore: _average(scores.map((item) => item.value).toList()),
      bestScore: best?.value.round(),
      bestScoreDate: best?.date,
      averageSleepHours: _average(sleep),
      averageWaterMl: _average(water),
      averageSteps: _average(steps),
      averageStress: _average(stress),
      taskCompletionRate: totalTasks <= 0 ? null : completedTasks / totalTasks,
      mealCompletionRate: totalMeals <= 0 ? null : completedMeals / totalMeals,
    );
  }

  HealthHabitSummary _buildHabitSummary({
    required List<HealthLogEntry> logs,
    required List<HealthDailyAdherenceEntry> adherence,
    required DateTime today,
    required int currentStreak,
  }) {
    final start = today.subtract(const Duration(days: 6));
    final careDates = <String>{};

    for (final log in logs) {
      if (_inRange(log.date, start, today)) {
        careDates.add(_dateKey(log.date));
      }
    }

    var completedTasks = 0;
    var totalTasks = 0;
    var completedMeals = 0;
    var totalMeals = 0;
    for (final item in adherence) {
      if (!_inRange(item.date, start, today)) continue;
      if (item.hasCareSignal) careDates.add(_dateKey(item.date));
      completedTasks += item.completedTasks;
      totalTasks += item.totalTasks;
      completedMeals += item.completedMeals;
      totalMeals += item.totalMeals;
    }

    return HealthHabitSummary(
      currentStreak: currentStreak,
      careDays7: careDates.length.clamp(0, 7).toInt(),
      taskCompletionRate7: totalTasks <= 0 ? null : completedTasks / totalTasks,
      mealCompletionRate7: totalMeals <= 0 ? null : completedMeals / totalMeals,
    );
  }

  HealthInsightConfidence _confidence({
    required int expectedDays,
    required int currentSamples,
    required int previousSamples,
  }) {
    if (currentSamples <= 0) return HealthInsightConfidence.insufficient;
    if (expectedDays <= 1) {
      return previousSamples > 0
          ? HealthInsightConfidence.high
          : HealthInsightConfidence.low;
    }

    final currentCoverage = currentSamples / expectedDays;
    final previousCoverage = previousSamples / expectedDays;
    if (currentSamples >= 3 &&
        previousSamples >= 3 &&
        currentCoverage >= .7 &&
        previousCoverage >= .7) {
      return HealthInsightConfidence.high;
    }
    if (currentSamples >= 2 &&
        previousSamples >= 2 &&
        currentCoverage >= .4 &&
        previousCoverage >= .4) {
      return HealthInsightConfidence.medium;
    }
    return HealthInsightConfidence.low;
  }

  HealthInsightConfidence _coverageConfidence(int expectedDays, int samples) {
    if (samples <= 0) return HealthInsightConfidence.insufficient;
    if (expectedDays <= 1) return HealthInsightConfidence.high;
    final coverage = samples / expectedDays;
    if (samples >= 3 && coverage >= .7) return HealthInsightConfidence.high;
    if (samples >= 2 && coverage >= .4) return HealthInsightConfidence.medium;
    return HealthInsightConfidence.low;
  }

  HealthTrendDirection _trend(double? current, double? previous) {
    if (current == null || previous == null) {
      return HealthTrendDirection.unknown;
    }
    final delta = current - previous;
    final threshold = previous.abs() <= 0.000001
        ? 0.01
        : previous.abs() * .03;
    if (delta.abs() <= threshold) return HealthTrendDirection.stable;
    return delta > 0 ? HealthTrendDirection.up : HealthTrendDirection.down;
  }

  HealthDataFreshness _freshness(DateTime? latest, DateTime today) {
    if (latest == null) return HealthDataFreshness.missing;
    final latestDate = _dateOnly(latest);
    final age = today.difference(latestDate).inDays;
    if (age <= 0) return HealthDataFreshness.today;
    if (age <= 2) return HealthDataFreshness.recent;
    return HealthDataFreshness.stale;
  }

  HealthActionTarget _targetForRecommendation(
    HealthExternalRecommendation item,
  ) {
    final text = '${item.type} ${item.title} ${item.actionText}'.toLowerCase();
    if (text.contains('water') ||
        text.contains('hydration') ||
        text.contains('nước')) {
      return HealthActionTarget.waterTracking;
    }
    if (text.contains('sleep') || text.contains('ngủ')) {
      return HealthActionTarget.sleepTracking;
    }
    if (text.contains('stress') || text.contains('căng thẳng')) {
      return HealthActionTarget.stressTracking;
    }
    if (text.contains('meal') ||
        text.contains('nutrition') ||
        text.contains('bữa') ||
        text.contains('ăn')) {
      return HealthActionTarget.mealPlan;
    }
    if (text.contains('weight') ||
        text.contains('bmi') ||
        text.contains('cân nặng')) {
      return HealthActionTarget.bodyMetrics;
    }
    if (text.contains('schedule') ||
        text.contains('task') ||
        text.contains('lịch') ||
        text.contains('nhiệm vụ') ||
        text.contains('exercise') ||
        text.contains('vận động')) {
      return HealthActionTarget.lifestyleSchedule;
    }
    return HealthActionTarget.healthTracking;
  }

  HealthActionTarget _targetForMetric(HealthMetricType type) {
    return switch (type) {
      HealthMetricType.water => HealthActionTarget.waterTracking,
      HealthMetricType.sleep => HealthActionTarget.sleepTracking,
      HealthMetricType.stress => HealthActionTarget.stressTracking,
      HealthMetricType.weight => HealthActionTarget.bodyMetrics,
      HealthMetricType.calories || HealthMetricType.mealCompletion =>
        HealthActionTarget.mealPlan,
      HealthMetricType.taskCompletion => HealthActionTarget.lifestyleSchedule,
      HealthMetricType.healthScore => HealthActionTarget.weeklySummary,
      HealthMetricType.steps ||
      HealthMetricType.heartRate ||
      HealthMetricType.oxygen ||
      HealthMetricType.mood => HealthActionTarget.healthTracking,
    };
  }

  String _metricName(HealthMetricType type) {
    return switch (type) {
      HealthMetricType.healthScore => 'điểm chăm sóc',
      HealthMetricType.sleep => 'giấc ngủ',
      HealthMetricType.water => 'lượng nước',
      HealthMetricType.steps => 'bước chân',
      HealthMetricType.calories => 'năng lượng',
      HealthMetricType.stress => 'mức căng thẳng',
      HealthMetricType.weight => 'cân nặng',
      HealthMetricType.heartRate => 'nhịp tim',
      HealthMetricType.oxygen => 'SpO₂',
      HealthMetricType.mood => 'tâm trạng',
      HealthMetricType.taskCompletion => 'tiến độ nhiệm vụ',
      HealthMetricType.mealCompletion => 'tiến độ thực đơn',
    };
  }

  String _missingMessage(HealthMetricType type) {
    return switch (type) {
      HealthMetricType.healthScore =>
        'Chưa đủ dữ liệu để tổng hợp điểm chăm sóc cho giai đoạn này.',
      HealthMetricType.sleep =>
        'Chưa có ghi nhận giấc ngủ gần đây để so sánh xu hướng.',
      HealthMetricType.water =>
        'Chưa có lượng nước gần đây để NanoBio theo dõi nhịp uống nước.',
      HealthMetricType.steps =>
        'Chưa có số bước gần đây để hiển thị nhịp vận động.',
      HealthMetricType.calories =>
        'Chưa có dữ liệu năng lượng đã ghi nhận trong giai đoạn này.',
      HealthMetricType.stress =>
        'Chưa có mức căng thẳng gần đây để so sánh theo thời gian.',
      HealthMetricType.weight =>
        'Chưa có cân nặng gần đây để hiển thị thay đổi.',
      HealthMetricType.heartRate =>
        'Chưa có nhịp tim gần đây trong dữ liệu NanoBio.',
      HealthMetricType.oxygen =>
        'Chưa có SpO₂ gần đây trong dữ liệu NanoBio.',
      HealthMetricType.mood =>
        'Chưa có ghi nhận tâm trạng gần đây để nhìn lại nhịp cảm xúc.',
      HealthMetricType.taskCompletion =>
        'Chưa có nhiệm vụ trong giai đoạn này để tính tiến độ.',
      HealthMetricType.mealCompletion =>
        'Chưa có thực đơn trong giai đoạn này để tính tiến độ.',
    };
  }

  List<HealthSignalItem> _dedupeSignals(List<HealthSignalItem> items) {
    final seen = <String>{};
    final result = <HealthSignalItem>[];
    for (final item in items) {
      final key = '${item.kind.name}|${item.title.trim().toLowerCase()}';
      if (!seen.add(key)) continue;
      if (item.message.trim().isEmpty) continue;
      result.add(item);
    }
    return result;
  }

  HealthMetricSummary? _metric(
    List<HealthMetricSummary> metrics,
    HealthMetricType type,
  ) {
    for (final item in metrics) {
      if (item.type == type) return item;
    }
    return null;
  }

  DateTime? _latestMetricDate(List<HealthMetricSummary> metrics) {
    DateTime? latest;
    for (final item in metrics) {
      latest = _later(latest, item.latestRecordedAt);
    }
    return latest;
  }

  DateTime? _latestLogDate(List<HealthLogEntry> logs) {
    DateTime? latest;
    for (final item in logs) {
      latest = _later(latest, item.updatedAt ?? item.date);
    }
    return latest;
  }

  DateTime? _later(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return b.isAfter(a) ? b : a;
  }

  double? _average(List<double> values) {
    if (values.isEmpty) return null;
    var sum = 0.0;
    var count = 0;
    for (final value in values) {
      if (!value.isFinite) continue;
      sum += value;
      count++;
    }
    return count == 0 ? null : sum / count;
  }

  double? _minimum(List<double> values) {
    double? result;
    for (final value in values) {
      if (!value.isFinite) continue;
      if (result == null || value < result) result = value;
    }
    return result;
  }

  double? _maximum(List<double> values) {
    double? result;
    for (final value in values) {
      if (!value.isFinite) continue;
      if (result == null || value > result) result = value;
    }
    return result;
  }

  bool _inRange(DateTime value, DateTime start, DateTime end) {
    final date = _dateOnly(value);
    return !date.isBefore(start) && !date.isAfter(end);
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

class _DatedValue {
  final DateTime date;
  final double value;

  const _DatedValue({required this.date, required this.value});
}
