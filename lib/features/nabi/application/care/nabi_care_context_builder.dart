import '../../domain/care/nabi_care_models.dart';

class NabiCareContextBuilder {
  final DateTime Function() now;

  NabiCareContextBuilder({DateTime Function()? now})
      : now = now ?? DateTime.now;

  NabiCareSnapshot build(NabiCareRawContext raw) {
    final generatedAt = now();
    final user = _first(raw.rows('users'));
    final healthProfile = _first(raw.rows('health_profiles'));
    final lifestyle = _first(raw.rows('lifestyle_habits'));
    final nutritionProfile = _first(raw.rows('nutrition_profiles'));
    final tracking = _sortedTracking(raw.rows('health_tracking_logs'));
    final latestTracking = _first(tracking);

    final birthYear = _int(user?['birth_year']);
    final ageYears = birthYear == null
        ? null
        : (generatedAt.year - birthYear).clamp(0, 120).toInt();

    final profile = <String, Object?>{
      if (ageYears != null) 'age_years': ageYears,
      if (nabiCareText(user?['gender']) != null)
        'gender': nabiCareText(user?['gender']),
      if (nabiCareText(healthProfile?['occupation']) != null)
        'occupation': nabiCareText(healthProfile?['occupation']),
      if (nabiCareNumber(healthProfile?['height_cm']) != null)
        'height_cm': nabiCareNumber(healthProfile?['height_cm']),
      if (nabiCareNumber(healthProfile?['weight_kg']) != null)
        'profile_weight_kg': nabiCareNumber(healthProfile?['weight_kg']),
      if (nabiCareNumber(healthProfile?['bmi']) != null)
        'bmi': nabiCareNumber(healthProfile?['bmi']),
      if (nabiCareText(healthProfile?['blood_pressure']) != null)
        'blood_pressure_note': nabiCareText(healthProfile?['blood_pressure']),
      if (nabiCareText(healthProfile?['blood_sugar']) != null)
        'blood_sugar_note': nabiCareText(healthProfile?['blood_sugar']),
      if (nabiCareNumber(nutritionProfile?['waist_cm']) != null)
        'waist_cm': nabiCareNumber(nutritionProfile?['waist_cm']),
      if (nabiCareText(nutritionProfile?['current_status']) != null)
        'current_status': nabiCareText(nutritionProfile?['current_status']),
      if (nabiCareNumber(nutritionProfile?['average_sleep_hours']) != null)
        'reported_average_sleep_hours':
            nabiCareNumber(nutritionProfile?['average_sleep_hours']),
      if (nabiCareText(nutritionProfile?['smoking_status']) != null)
        'smoking_status': nabiCareText(nutritionProfile?['smoking_status']),
      if (nabiCareText(nutritionProfile?['alcohol_frequency']) != null)
        'alcohol_frequency':
            nabiCareText(nutritionProfile?['alcohol_frequency']),
      if (nabiCareText(nutritionProfile?['coffee_frequency']) != null)
        'coffee_frequency':
            nabiCareText(nutritionProfile?['coffee_frequency']),
      if (nabiCareNumber(nutritionProfile?['target_weight_kg']) != null)
        'target_weight_kg':
            nabiCareNumber(nutritionProfile?['target_weight_kg']),
      'water_restriction': _truthy(nutritionProfile?['water_restriction']),
      if (nabiCareText(nutritionProfile?['water_restriction_note']) != null)
        'water_restriction_note':
            nabiCareText(nutritionProfile?['water_restriction_note']),
      if (nabiCareText(lifestyle?['sleep_quality']) != null)
        'sleep_quality': nabiCareText(lifestyle?['sleep_quality']),
      if (nabiCareText(lifestyle?['activity_level']) != null)
        'activity_level': nabiCareText(lifestyle?['activity_level']),
      if (nabiCareNumber(lifestyle?['water_per_day']) != null)
        'reported_water_per_day':
            nabiCareNumber(lifestyle?['water_per_day']),
    };

    final current = <String, Object?>{};
    _copyNumber(latestTracking, current, 'weight_kg');
    _copyNumber(latestTracking, current, 'calories');
    _copyNumber(latestTracking, current, 'water_ml');
    _copyNumber(latestTracking, current, 'sleep_hours');
    _copyNumber(latestTracking, current, 'stress_level');
    _copyNumber(latestTracking, current, 'steps_count');
    _copyNumber(latestTracking, current, 'heart_rate_bpm');
    _copyNumber(latestTracking, current, 'oxygen_saturation');
    _copyNumber(latestTracking, current, 'daily_score');
    if (nabiCareText(latestTracking?['mood']) != null) {
      current['mood'] = nabiCareText(latestTracking?['mood']);
    }
    final latestTrackingAt = _rowDate(
      latestTracking,
      const ['log_date', 'updated_at', 'created_at'],
    );
    if (latestTrackingAt != null) {
      current['measured_at'] = latestTrackingAt.toIso8601String();
    }

    final baselines = <String, Object?>{
      ..._trackingAverages(tracking, generatedAt, const Duration(days: 7), '7d'),
      ..._trackingAverages(
        tracking,
        generatedAt,
        const Duration(days: 30),
        '30d',
      ),
    };

    final adherence = _buildAdherence(raw, generatedAt);
    final conditions = _projectRows(
      raw.rows('health_conditions'),
      const ['condition_code', 'condition_name', 'severity_level'],
      activeOnly: false,
      limit: 20,
    );
    final symptoms = _projectRows(
      raw.rows('health_symptoms'),
      const [
        'symptom_type',
        'body_location',
        'severity_level',
        'started_at',
        'trigger_note',
        'impact_note',
        'note',
      ],
      activeOnly: true,
      limit: 20,
    );
    final medications = _projectRows(
      raw.rows('medication_records'),
      const [
        'name',
        'product_type',
        'usage_schedule',
        'prescriber_confirmed',
        'note',
      ],
      activeOnly: true,
      limit: 20,
    );
    final labs = _projectRows(
      raw.rows('lab_results'),
      const [
        'test_code',
        'test_name',
        'value_text',
        'unit',
        'measured_at',
        'reference_note',
      ],
      activeOnly: false,
      limit: 16,
    );
    final goals = <Map<String, Object?>>[
      ..._projectRows(
        raw.rows('health_goals'),
        const ['goal_code', 'goal_name'],
        activeOnly: true,
        limit: 20,
      ),
      ..._projectRows(
        raw.rows('nutrition_goals'),
        const [
          'goal_code',
          'goal_name',
          'priority',
          'target_period',
          'target_date',
        ],
        activeOnly: true,
        limit: 20,
      ),
    ];

    final evidence = <String, NabiCareEvidence>{};
    _addTrackingEvidence(evidence, current, latestTrackingAt);
    _addBaselineEvidence(evidence, baselines);
    _addProfileEvidence(evidence, profile, healthProfile, nutritionProfile);
    _addAdherenceEvidence(evidence, adherence);
    _addListEvidence(evidence, 'conditions', conditions, 'health_conditions');
    _addListEvidence(evidence, 'symptoms', symptoms, 'health_symptoms');
    _addListEvidence(evidence, 'medications', medications, 'medication_records');
    _addListEvidence(evidence, 'labs', labs, 'lab_results');
    _addListEvidence(evidence, 'goals', goals, 'health_goals');

    final dataQuality = _dataQuality(
      raw: raw,
      profile: profile,
      current: current,
      adherence: adherence,
      generatedAt: generatedAt,
      latestTrackingAt: latestTrackingAt,
      healthProfile: healthProfile,
    );

    final productAccess =
        nabiCareText(user?['product_access_status'])?.toLowerCase() ?? 'guest';
    final membership =
        nabiCareText(user?['subscription_tier'])?.toLowerCase() ?? 'free';
    final actorKind =
        productAccess == 'guest' || membership == 'guest' ? 'guest' : 'member';

    return NabiCareSnapshot(
      actorKey: raw.actorKey,
      actorKind: actorKind,
      membershipPlan: membership,
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
    );
  }

  Map<String, Object?> _buildAdherence(
    NabiCareRawContext raw,
    DateTime generatedAt,
  ) {
    final today = _dateKey(generatedAt);
    final tasks = raw.rows('daily_health_tasks');
    final schedules = raw.rows('lifestyle_schedule_items');

    final todayTasks = tasks.where(
      (row) => nabiCareText(row['task_date'])?.startsWith(today) == true,
    );
    final todaySchedules = schedules.where(
      (row) => nabiCareText(row['schedule_date'])?.startsWith(today) == true,
    );

    final recentStart = DateTime(
      generatedAt.year,
      generatedAt.month,
      generatedAt.day,
    ).subtract(const Duration(days: 6));
    final recentTasks = tasks.where((row) {
      final date = nabiCareDate(row['task_date']);
      return date != null && !date.isBefore(recentStart);
    });
    final recentSchedules = schedules.where((row) {
      final date = nabiCareDate(row['schedule_date']);
      return date != null && !date.isBefore(recentStart);
    });

    final todayTotal = todayTasks.length + todaySchedules.length;
    final todayCompleted =
        todayTasks.where((row) => _truthy(row['is_completed'])).length +
            todaySchedules.where((row) => _truthy(row['is_completed'])).length;
    final recentTotal = recentTasks.length + recentSchedules.length;
    final recentCompleted =
        recentTasks.where((row) => _truthy(row['is_completed'])).length +
            recentSchedules.where((row) => _truthy(row['is_completed'])).length;

    return {
      'today_completed': todayCompleted,
      'today_total': todayTotal,
      if (todayTotal > 0) 'today_ratio': todayCompleted / todayTotal,
      'last_7d_completed': recentCompleted,
      'last_7d_total': recentTotal,
      if (recentTotal > 0) 'last_7d_ratio': recentCompleted / recentTotal,
    };
  }

  Map<String, Object?> _trackingAverages(
    List<Map<String, Object?>> rows,
    DateTime generatedAt,
    Duration window,
    String suffix,
  ) {
    final start = generatedAt.subtract(window);
    final windowRows = rows.where((row) {
      final date = _rowDate(
        row,
        const ['log_date', 'updated_at', 'created_at'],
      );
      return date != null && !date.isBefore(start) && !date.isAfter(generatedAt);
    }).toList(growable: false);

    final result = <String, Object?>{};
    for (final metric in const [
      'weight_kg',
      'calories',
      'water_ml',
      'sleep_hours',
      'stress_level',
      'steps_count',
      'heart_rate_bpm',
      'oxygen_saturation',
      'daily_score',
    ]) {
      final values = windowRows
          .map((row) => nabiCareNumber(row[metric]))
          .whereType<double>()
          .toList(growable: false);
      if (values.isEmpty) continue;
      result['${metric}_avg_$suffix'] =
          values.reduce((left, right) => left + right) / values.length;
    }
    result['tracking_days_$suffix'] = windowRows.length;
    return result;
  }

  List<Map<String, Object?>> _sortedTracking(
    List<Map<String, Object?>> rows,
  ) {
    final sorted = [...rows];
    sorted.sort((left, right) {
      final leftDate = _rowDate(
        left,
        const ['log_date', 'updated_at', 'created_at'],
      );
      final rightDate = _rowDate(
        right,
        const ['log_date', 'updated_at', 'created_at'],
      );
      if (leftDate == null && rightDate == null) return 0;
      if (leftDate == null) return 1;
      if (rightDate == null) return -1;
      return rightDate.compareTo(leftDate);
    });
    return sorted;
  }

  List<Map<String, Object?>> _projectRows(
    List<Map<String, Object?>> rows,
    List<String> keys, {
    required bool activeOnly,
    required int limit,
  }) {
    final output = <Map<String, Object?>>[];
    for (final row in rows) {
      if (activeOnly &&
          row.containsKey('is_active') &&
          !_truthy(row['is_active'])) {
        continue;
      }
      final item = <String, Object?>{};
      for (final key in keys) {
        final value = row[key];
        if (value == null) continue;
        final text = value is String ? value.trim() : null;
        if (text != null && text.isEmpty) continue;
        item[key] = value;
      }
      if (item.isNotEmpty) output.add(item);
      if (output.length >= limit) break;
    }
    return output;
  }

  void _addTrackingEvidence(
    Map<String, NabiCareEvidence> evidence,
    Map<String, Object?> current,
    DateTime? measuredAt,
  ) {
    const units = <String, String>{
      'weight_kg': 'kg',
      'calories': 'kcal',
      'water_ml': 'ml',
      'sleep_hours': 'hours',
      'steps_count': 'steps',
      'heart_rate_bpm': 'bpm',
      'oxygen_saturation': '%',
    };
    for (final entry in current.entries) {
      if (entry.key == 'measured_at') continue;
      evidence['health.${entry.key}.current'] = NabiCareEvidence(
        key: 'health.${entry.key}.current',
        value: entry.value,
        source: 'health_tracking_logs',
        unit: units[entry.key],
        measuredAt: measuredAt,
        fresh: measuredAt == null ||
            now().difference(measuredAt).inHours <= 72,
      );
    }
  }

  void _addBaselineEvidence(
    Map<String, NabiCareEvidence> evidence,
    Map<String, Object?> baselines,
  ) {
    for (final entry in baselines.entries) {
      evidence['baseline.${entry.key}'] = NabiCareEvidence(
        key: 'baseline.${entry.key}',
        value: entry.value,
        source: 'health_tracking_logs',
      );
    }
  }

  void _addProfileEvidence(
    Map<String, NabiCareEvidence> evidence,
    Map<String, Object?> profile,
    Map<String, Object?>? healthProfile,
    Map<String, Object?>? nutritionProfile,
  ) {
    final measuredAt = _rowDate(
      healthProfile,
      const ['updated_at', 'created_at'],
    );
    for (final entry in profile.entries) {
      final source = nutritionProfile?.containsKey(entry.key) == true
          ? 'nutrition_profiles'
          : 'health_profiles';
      evidence['profile.${entry.key}'] = NabiCareEvidence(
        key: 'profile.${entry.key}',
        value: entry.value,
        source: source,
        measuredAt: measuredAt,
      );
    }
  }

  void _addAdherenceEvidence(
    Map<String, NabiCareEvidence> evidence,
    Map<String, Object?> adherence,
  ) {
    for (final entry in adherence.entries) {
      evidence['adherence.${entry.key}'] = NabiCareEvidence(
        key: 'adherence.${entry.key}',
        value: entry.value,
        source: 'daily_health_tasks+lifestyle_schedule_items',
      );
    }
  }

  void _addListEvidence(
    Map<String, NabiCareEvidence> evidence,
    String key,
    List<Map<String, Object?>> rows,
    String source,
  ) {
    if (rows.isEmpty) return;
    evidence['health.$key'] = NabiCareEvidence(
      key: 'health.$key',
      value: rows,
      source: source,
    );
  }

  NabiCareDataQuality _dataQuality({
    required NabiCareRawContext raw,
    required Map<String, Object?> profile,
    required Map<String, Object?> current,
    required Map<String, Object?> adherence,
    required DateTime generatedAt,
    required DateTime? latestTrackingAt,
    required Map<String, Object?>? healthProfile,
  }) {
    final available = <String>[];
    final missing = <String>[];
    final stale = <String>[];

    void group(String name, bool hasData) {
      (hasData ? available : missing).add(name);
    }

    group('profile', profile.isNotEmpty);
    group('tracking', current.isNotEmpty);
    group('habits', raw.rows('lifestyle_habits').isNotEmpty);
    group(
      'schedule',
      (adherence['today_total'] as int? ?? 0) > 0 ||
          (adherence['last_7d_total'] as int? ?? 0) > 0,
    );
    group(
      'health_context',
      raw.rows('health_conditions').isNotEmpty ||
          raw.rows('health_symptoms').isNotEmpty ||
          raw.rows('health_goals').isNotEmpty,
    );
    group(
      'nutrition',
      raw.rows('nutrition_profiles').isNotEmpty ||
          raw.rows('nutrition_logs').isNotEmpty,
    );
    group('labs', raw.rows('lab_results').isNotEmpty);

    if (latestTrackingAt != null &&
        generatedAt.difference(latestTrackingAt).inHours > 72) {
      stale.add('tracking');
    }
    final profileAt = _rowDate(
      healthProfile,
      const ['updated_at', 'created_at'],
    );
    if (profileAt != null &&
        generatedAt.difference(profileAt).inDays > 30) {
      stale.add('profile');
    }

    return NabiCareDataQuality(
      completeness: available.length / 7,
      availableGroups: available,
      missingGroups: missing,
      staleGroups: stale,
    );
  }

  void _copyNumber(
    Map<String, Object?>? source,
    Map<String, Object?> target,
    String key,
  ) {
    final value = nabiCareNumber(source?[key]);
    if (value != null) target[key] = value;
  }

  DateTime? _rowDate(
    Map<String, Object?>? row,
    List<String> keys,
  ) {
    if (row == null) return null;
    for (final key in keys) {
      final parsed = nabiCareDate(row[key]);
      if (parsed != null) return parsed;
    }
    return null;
  }

  Map<String, Object?>? _first(List<Map<String, Object?>> rows) =>
      rows.isEmpty ? null : rows.first;

  int? _int(Object? value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }

  bool _truthy(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'active';
  }

  String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
