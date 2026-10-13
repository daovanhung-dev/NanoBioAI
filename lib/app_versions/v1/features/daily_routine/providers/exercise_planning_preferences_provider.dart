import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/exercise_planning_preferences_local_datasource.dart';
import '../domain/entities/exercise_planning_preferences.dart';
import '../domain/repositories/exercise_planning_preferences_repository.dart';
import '../domain/repositories/exercise_planning_preferences_repository_impl.dart';
import 'daily_routine_preferences_provider.dart';

final exercisePlanningPreferencesDatasourceProvider =
    Provider<ExercisePlanningPreferencesLocalDatasource>((ref) {
      return const ExercisePlanningPreferencesLocalDatasource();
    });

final exercisePlanningPreferencesRepositoryProvider =
    Provider<ExercisePlanningPreferencesRepository>((ref) {
      final subjectResolver = ref.read(dailyRoutineSubjectResolverProvider);
      return ExercisePlanningPreferencesRepositoryImpl(
        datasource: ref.read(exercisePlanningPreferencesDatasourceProvider),
        resolveSubjectId: subjectResolver.resolve,
      );
    });

final exercisePlanningPreferencesProvider =
    FutureProvider<ExercisePlanningPreferences>((ref) {
      return ref
          .read(exercisePlanningPreferencesRepositoryProvider)
          .loadForCurrentUser();
    });
