import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/app_versions/v1/features/meal_plan/data/daos/meal_plan_dao.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_model.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/application/nutrition_ai_service.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/application/nutrition_metrics_engine.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/data/datasources/nutrition_profile_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/domain/entities/nutrition_intelligence_entity.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/domain/entities/nutrition_profile_entity.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';
import 'package:nano_app/core/storage/localdb/daos/health_profiles_dao.dart';
import 'package:nano_app/core/storage/localdb/daos/health_tracking_logs_dao.dart';
import 'package:nano_app/core/storage/localdb/daos/nutrition_logs_dao.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/models/health_profile_model.dart';
import 'package:nano_app/core/storage/localdb/models/health_tracking_log_model.dart';
import 'package:nano_app/core/storage/localdb/models/nutrition_log_model.dart';

final selectedNutritionDateProvider =
    NotifierProvider<SelectedNutritionDateController, DateTime>(
      SelectedNutritionDateController.new,
    );

class SelectedNutritionDateController extends Notifier<DateTime> {
  @override
  DateTime build() => _day(DateTime.now());

  void setDate(DateTime value) {
    state = _day(value);
  }
}

final nutritionMetricsEngineProvider = Provider<NutritionMetricsEngine>(
  (_) => const NutritionMetricsEngine(),
);

final nutritionAiServiceProvider = Provider<NutritionAiService>(
  (_) => const NutritionAiService(),
);

/// One DB read bundle shared by summary, deterministic metrics and AI snapshot.
/// Date changes do not re-query SQLite; only the in-memory projection changes.
final nutritionDataBundleProvider = FutureProvider<NutritionDataBundle>((ref) async {
  final db = await DatabaseService.database;
  final authUserId = ref.watch(currentAuthUserIdProvider)?.trim();
  final userRows = await db.query(
    'users',
    where: authUserId == null || authUserId.isEmpty ? null : 'id = ?',
    whereArgs: authUserId == null || authUserId.isEmpty ? null : [authUserId],
    orderBy: 'created_at DESC',
    limit: 1,
  );
  if (userRows.isEmpty) return NutritionDataBundle.empty();

  final user = userRows.first;
  final userId = _readString(user['id']);
  if (userId == null || userId.isEmpty) return NutritionDataBundle.empty();

  final results = await Future.wait<Object?>([
    NutritionLogsDao(db).getByUserId(userId),
    MealPlansDao(db).getByUserId(userId),
    HealthTrackingLogsDao(db).getByUserId(userId),
    HealthProfilesDao(db).getLatestByUserId(userId),
    const NutritionProfileLocalDatasource().load(userId),
  ]);

  return NutritionDataBundle(
    userId: userId,
    fullName: _readString(user['full_name']) ?? '',
    logs: results[0] as List<NutritionLogModel>,
    meals: results[1] as List<MealPlanModel>,
    healthHistory: results[2] as List<HealthTrackingLogModel>,
    healthProfile: results[3] as HealthProfileModel?,
    nutritionProfile: results[4] as NutritionProfileEntity,
    generatedAt: DateTime.now(),
  );
});

final nutritionSummaryProvider = FutureProvider<NutritionSummary>((ref) async {
  final bundle = await ref.watch(nutritionDataBundleProvider.future);
  final selectedDate = ref.watch(selectedNutritionDateProvider);
  return NutritionSummary(
    userId: bundle.userId,
    fullName: bundle.fullName,
    logs: bundle.logs,
    meals: bundle.meals,
    selectedDate: selectedDate,
    generatedAt: bundle.generatedAt,
  );
});

final nutritionIntelligenceProvider =
    FutureProvider<NutritionIntelligence>((ref) async {
      final bundle = await ref.watch(nutritionDataBundleProvider.future);
      final selectedDate = ref.watch(selectedNutritionDateProvider);
      return ref.read(nutritionMetricsEngineProvider).analyze(
            selectedDate: selectedDate,
            allLogs: bundle.logs,
            allMeals: bundle.meals,
            healthHistory: bundle.healthHistory,
            healthProfile: bundle.healthProfile,
            hasProfileContext: bundle.hasNutritionProfileContext,
          );
    });

final nutritionAiReportProvider = FutureProvider<NutritionAiReport>((ref) async {
  final bundle = await ref.watch(nutritionDataBundleProvider.future);
  final intelligence = await ref.watch(nutritionIntelligenceProvider.future);
  final snapshot = _buildHealthSnapshot(
    intelligence: intelligence,
    profile: bundle.nutritionProfile,
  );
  return ref.read(nutritionAiServiceProvider).analyze(snapshot);
});

class NutritionDataBundle {
  const NutritionDataBundle({
    required this.userId,
    required this.fullName,
    required this.logs,
    required this.meals,
    required this.healthHistory,
    required this.healthProfile,
    required this.nutritionProfile,
    required this.generatedAt,
  });

  final String? userId;
  final String fullName;
  final List<NutritionLogModel> logs;
  final List<MealPlanModel> meals;
  final List<HealthTrackingLogModel> healthHistory;
  final HealthProfileModel? healthProfile;
  final NutritionProfileEntity nutritionProfile;
  final DateTime generatedAt;

  factory NutritionDataBundle.empty() => NutritionDataBundle(
        userId: null,
        fullName: '',
        logs: const [],
        meals: const [],
        healthHistory: const [],
        healthProfile: null,
        nutritionProfile: NutritionProfileEntity.empty(''),
        generatedAt: DateTime.now(),
      );

  bool get hasNutritionProfileContext {
    final profile = nutritionProfile;
    return profile.currentStatus.trim().isNotEmpty ||
        profile.restrictions.any((item) => item.isActive) ||
        profile.symptoms.any((item) => item.isActive) ||
        profile.medications.any((item) => item.isActive) ||
        profile.labResults.isNotEmpty ||
        profile.goals.any((item) => item.isActive) ||
        profile.targetWeightKg != null ||
        profile.averageSleepHours != null ||
        profile.waistCm != null;
  }
}

class NutritionSummary {
  const NutritionSummary({
    required this.userId,
    required this.fullName,
    required this.logs,
    required this.meals,
    required this.selectedDate,
    required this.generatedAt,
  });

  final String? userId;
  final String fullName;
  final List<NutritionLogModel> logs;
  final List<MealPlanModel> meals;
  final DateTime selectedDate;
  final DateTime generatedAt;

  List<NutritionLogModel> get todayLogs {
    final key = _dateKey(selectedDate);
    return logs
        .where((log) => _dateFromText(log.eatenAt) == key)
        .toList(growable: false);
  }

  List<MealPlanModel> get todayMeals {
    final key = _dateKey(selectedDate);
    return meals
        .where((meal) => _dateFromText(meal.planDate) == key)
        .toList(growable: false);
  }

  int get loggedCalories =>
      todayLogs.fold(0, (sum, log) => sum + (log.calories ?? 0));

  int get plannedCalories =>
      todayMeals.fold(0, (sum, meal) => sum + meal.calories);

  double get protein =>
      todayLogs.fold(0, (sum, log) => sum + (log.protein ?? 0));

  double get carbs =>
      todayLogs.fold(0, (sum, log) => sum + (log.carbs ?? 0));

  double get fat =>
      todayLogs.fold(0, (sum, log) => sum + (log.fat ?? 0));

  bool get hasAnyData => logs.isNotEmpty || meals.isNotEmpty;
}

NutritionHealthSnapshot _buildHealthSnapshot({
  required NutritionIntelligence intelligence,
  required NutritionProfileEntity profile,
}) {
  final activeRestrictions =
      profile.restrictions.where((item) => item.isActive).toList();
  final allergies = <NutritionEvidenceSignal>[];
  final restrictions = <NutritionEvidenceSignal>[];
  for (var index = 0; index < activeRestrictions.length; index++) {
    final item = activeRestrictions[index];
    final type = item.type.trim().toLowerCase();
    final signal = NutritionEvidenceSignal(
      code: _evidenceCode(
        type.contains('allerg') || type.contains('dị ứng')
            ? 'allergy'
            : 'avoid',
        item.itemName,
        index,
      ),
      label: item.itemName.trim().isEmpty ? 'Hạn chế thực phẩm' : item.itemName,
      note: item.note,
    );
    if (type.contains('allerg') || type.contains('dị ứng')) {
      allergies.add(signal);
    } else {
      restrictions.add(signal);
    }
  }

  final symptoms = <NutritionEvidenceSignal>[
    for (var index = 0; index < profile.symptoms.length; index++)
      if (profile.symptoms[index].isActive)
        NutritionEvidenceSignal(
          code: _evidenceCode(
            'symptom',
            profile.symptoms[index].symptomType,
            index,
          ),
          label: profile.symptoms[index].symptomType,
          note: profile.symptoms[index].note,
        ),
  ];

  final labs = <NutritionEvidenceSignal>[
    for (var index = 0; index < profile.labResults.length && index < 8; index++)
      NutritionEvidenceSignal(
        code: _evidenceCode(
          'lab',
          profile.labResults[index].testCode.trim().isNotEmpty
              ? profile.labResults[index].testCode
              : profile.labResults[index].testName,
          index,
        ),
        label: profile.labResults[index].testName,
        note: [
          profile.labResults[index].valueText,
          profile.labResults[index].unit,
          profile.labResults[index].referenceNote,
        ].where((value) => value.trim().isNotEmpty).join(' '),
      ),
  ];

  final activeGoals = profile.goals.where((item) => item.isActive).toList()
    ..sort((a, b) => b.priority.compareTo(a.priority));
  final goal = activeGoals.isEmpty
      ? null
      : NutritionEvidenceSignal(
          code: _evidenceCode('goal', activeGoals.first.code, 0),
          label: activeGoals.first.name,
          note: activeGoals.first.targetPeriod,
        );

  return NutritionHealthSnapshot(
    intelligence: intelligence,
    goal: goal,
    restrictions: List.unmodifiable(restrictions),
    allergies: List.unmodifiable(allergies),
    symptoms: List.unmodifiable(symptoms),
    labs: List.unmodifiable(labs),
    medicationCount: profile.medications.where((item) => item.isActive).length,
    currentStatus: profile.currentStatus,
  );
}

String _evidenceCode(String prefix, String raw, int index) {
  final normalized = raw
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return '$prefix:${normalized.isEmpty ? 'item_${index + 1}' : normalized}';
}

String? _readString(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String? _dateFromText(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final text = value.trim();
  final parsed = DateTime.tryParse(text);
  if (parsed != null) return _dateKey(parsed.toLocal());
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(text);
  if (match == null) return null;
  return '${match.group(1)}-${match.group(2)}-${match.group(3)}';
}
