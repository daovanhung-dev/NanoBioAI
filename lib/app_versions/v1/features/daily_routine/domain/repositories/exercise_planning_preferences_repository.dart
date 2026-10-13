import '../entities/exercise_planning_preferences.dart';

abstract class ExercisePlanningPreferencesRepository {
  Future<ExercisePlanningPreferences> loadForUser(String userId);

  Future<ExercisePlanningPreferences> loadForCurrentUser();

  Future<void> saveForCurrentUser(ExercisePlanningPreferences preferences);
}
