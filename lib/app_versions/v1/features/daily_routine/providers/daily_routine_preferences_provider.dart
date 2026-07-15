import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/daily_routine_preferences_local_datasource.dart';
import '../domain/entities/daily_routine_preferences.dart';
import '../domain/repositories/daily_routine_preferences_repository.dart';
import '../domain/repositories/daily_routine_preferences_repository_impl.dart';

final dailyRoutinePreferencesDatasourceProvider =
    Provider<DailyRoutinePreferencesLocalDatasource>((ref) {
      return const DailyRoutinePreferencesLocalDatasource();
    });

final dailyRoutinePreferencesRepositoryProvider =
    Provider<DailyRoutinePreferencesRepository>((ref) {
      return DailyRoutinePreferencesRepositoryImpl(
        datasource: ref.read(dailyRoutinePreferencesDatasourceProvider),
      );
    });

final dailyRoutinePreferencesProvider =
    FutureProvider<DailyRoutinePreferences?>((ref) {
      return ref
          .read(dailyRoutinePreferencesRepositoryProvider)
          .loadForCurrentUser();
    });
