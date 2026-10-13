import 'package:nano_app/app_versions/v1/features/daily_health_tracking/domain/entities/daily_health_profile_entity.dart';
import 'package:nano_app/app_versions/v1/features/daily_routine/domain/entities/exercise_planning_preferences.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';

class ExerciseCandidateSelector {
  const ExerciseCandidateSelector();

  List<ExerciseCatalogItemModel> eligibleExercises({
    required Iterable<ExerciseCatalogItemModel> catalog,
    required DailyHealthProfileEntity profile,
    required ExercisePlanningPreferences preferences,
  }) {
    final conditions = profile.conditions
        .map(_normalize)
        .where((value) => value.isNotEmpty && !_isNoConstraint(value))
        .toSet();
    final goals = profile.goals
        .map(_normalize)
        .where((value) => value.isNotEmpty)
        .toSet();
    final limitations = preferences.mobilityLimitations
        .map(_normalize)
        .where((value) => value.isNotEmpty)
        .toSet();
    final equipment = preferences.availableEquipment
        .map(_normalize)
        .where((value) => value.isNotEmpty)
        .toSet();

    final results =
        catalog
            .where((exercise) {
              if (!exercise.isActive || exercise.code.trim().isEmpty) {
                return false;
              }
              if (conditions.isNotEmpty &&
                  exercise.safetyStatus != 'condition_reviewed') {
                return false;
              }
              if (conditions.any(
                (condition) => exercise.conditionContraindications.any(
                  (tag) => _overlaps(_normalize(tag), condition),
                ),
              )) {
                return false;
              }
              if (goals.any(_requiresConditionReview) &&
                  exercise.safetyStatus != 'condition_reviewed') {
                return false;
              }
              if (limitations.isNotEmpty) {
                if (limitations.contains('other') ||
                    exercise.movementAreas.isEmpty) {
                  return false;
                }
                final movementAreas = exercise.movementAreas
                    .map(_normalize)
                    .toSet();
                final contraindications = exercise.limitationTags
                    .map(_normalize)
                    .toSet();
                if (limitations.any(
                  (tag) =>
                      movementAreas.contains(tag) ||
                      contraindications.contains(tag),
                )) {
                  return false;
                }
              }
              final requiredEquipment = exercise.equipment
                  .map(_normalize)
                  .toSet();
              if (!equipment.containsAll(requiredEquipment)) return false;
              if (!_matchesGoals(exercise, goals)) return false;
              return true;
            })
            .toList(growable: false)
          ..sort((left, right) {
            final intensity = _intensityScore(
              left.intensityLevel,
            ).compareTo(_intensityScore(right.intensityLevel));
            if (intensity != 0) return intensity;
            return left.code.compareTo(right.code);
          });
    return results;
  }

  int _intensityScore(String value) {
    switch (_normalize(value)) {
      case 'light':
        return 0;
      case 'moderate':
        return 1;
      default:
        return 2;
    }
  }

  bool _requiresConditionReview(String value) => const {
    'stable blood sugar',
    'stable blood pressure',
    'heart health',
    'joint health',
  }.contains(value);

  bool _matchesGoals(ExerciseCatalogItemModel exercise, Set<String> goals) {
    final areas = exercise.movementAreas.map(_normalize).toSet();
    final matchedGoalGroups = <bool>[
      if (goals.any(const {'gain muscle', 'improve strength'}.contains))
        areas.contains('strength'),
      if (goals.any(const {'improve cardio', 'daily activity'}.contains))
        areas.contains('cardio'),
      if (goals.contains('improve flexibility')) areas.contains('mobility'),
    ];
    return matchedGoalGroups.isEmpty ||
        matchedGoalGroups.any((matches) => matches);
  }

  bool _isNoConstraint(String value) => const {
    'none',
    'no',
    'no issue',
    'no special issue',
    'no_special_issue',
    'khong',
    'khong co',
    'khong co van de dac biet',
  }.contains(_normalize(value));

  String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
      .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
      .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
      .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
      .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
      .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
      .replaceAll('đ', 'd')
      .replaceAll('_', ' ')
      .replaceAll(RegExp(r'\s+'), ' ');

  bool _overlaps(String left, String right) =>
      left == right || left.contains(right) || right.contains(left);
}
