import '../../data/datasources/exercise_planning_preferences_local_datasource.dart';
import '../entities/exercise_planning_preferences.dart';
import 'exercise_planning_preferences_repository.dart';

typedef ExercisePlanningSubjectIdResolver = Future<String> Function();

class ExercisePlanningPreferencesRepositoryImpl
    implements ExercisePlanningPreferencesRepository {
  final ExercisePlanningPreferencesLocalDatasource datasource;
  final ExercisePlanningSubjectIdResolver resolveSubjectId;

  const ExercisePlanningPreferencesRepositoryImpl({
    required this.datasource,
    required this.resolveSubjectId,
  });

  @override
  Future<ExercisePlanningPreferences> loadForUser(String userId) =>
      datasource.loadForUser(userId);

  @override
  Future<ExercisePlanningPreferences> loadForCurrentUser() async =>
      datasource.loadForUser(await resolveSubjectId());

  @override
  Future<void> saveForCurrentUser(
    ExercisePlanningPreferences preferences,
  ) async {
    await datasource.saveForUser(await resolveSubjectId(), preferences);
  }
}
