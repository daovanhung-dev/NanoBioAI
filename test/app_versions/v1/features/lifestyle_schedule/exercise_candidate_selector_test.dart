import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/daily_health_tracking/domain/entities/daily_health_profile_entity.dart';
import 'package:nano_app/app_versions/v1/features/daily_routine/domain/entities/exercise_planning_preferences.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/services/exercise_candidate_selector.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';

void main() {
  const selector = ExerciseCandidateSelector();

  test('known conditions require condition-reviewed exercise metadata', () {
    final candidates = selector.eligibleExercises(
      catalog: [
        _exercise(code: 'unreviewed'),
        _exercise(code: 'reviewed', safetyStatus: 'condition_reviewed'),
        _exercise(
          code: 'contraindicated',
          safetyStatus: 'condition_reviewed',
          conditionContraindications: const ['type_2_diabetes'],
        ),
      ],
      profile: _profile(conditions: const ['type 2 diabetes']),
      preferences: const ExercisePlanningPreferences(),
    );

    expect(candidates.map((item) => item.code), ['reviewed']);
  });

  test('equipment, body limitations, and goals filter locally', () {
    final candidates = selector.eligibleExercises(
      catalog: [
        _exercise(
          code: 'safe-cardio',
          equipment: const ['chair'],
          movementAreas: const ['cardio', 'upper_body'],
        ),
        _exercise(
          code: 'knee-cardio',
          equipment: const ['chair'],
          movementAreas: const ['cardio', 'knee'],
        ),
        _exercise(
          code: 'needs-band',
          equipment: const ['resistance_band'],
          movementAreas: const ['cardio'],
        ),
        _exercise(
          code: 'wrong-goal',
          equipment: const ['chair'],
          movementAreas: const ['mobility'],
        ),
      ],
      profile: _profile(goals: const ['improve_cardio']),
      preferences: const ExercisePlanningPreferences(
        availableEquipment: ['chair'],
        mobilityLimitations: ['knee'],
      ),
    );

    expect(candidates.map((item) => item.code), ['safe-cardio']);
  });

  test('no-constraint sentinel does not block general wellness exercises', () {
    final candidates = selector.eligibleExercises(
      catalog: [_exercise(code: 'general')],
      profile: _profile(conditions: const ['no_special_issue']),
      preferences: const ExercisePlanningPreferences(),
    );

    expect(candidates.map((item) => item.code), ['general']);
  });
}

DailyHealthProfileEntity _profile({
  List<String> goals = const [],
  List<String> conditions = const [],
}) => DailyHealthProfileEntity(
  userId: 'user-1',
  fullName: 'Sensitive Name',
  goals: goals,
  conditions: conditions,
  habits: const [],
  sleepQuality: '',
  activityLevel: '',
  waterPerDay: '',
);

ExerciseCatalogItemModel _exercise({
  required String code,
  List<String> equipment = const [],
  List<String> movementAreas = const ['cardio'],
  List<String> conditionContraindications = const [],
  String safetyStatus = 'general_wellness_unreviewed',
  bool isActive = true,
}) => ExerciseCatalogItemModel(
  code: code,
  category: 'cardio',
  title: 'Bài tập $code',
  description: '',
  unit: 'phút',
  encouragement: '',
  minTarget: 5,
  maxTarget: 30,
  defaultTarget: 10,
  intensityLevel: 'light',
  equipment: equipment,
  movementAreas: movementAreas,
  conditionContraindications: conditionContraindications,
  safetyStatus: safetyStatus,
  isActive: isActive,
  createdAt: '2026-10-13T00:00:00Z',
  updatedAt: '2026-10-13T00:00:00Z',
);
