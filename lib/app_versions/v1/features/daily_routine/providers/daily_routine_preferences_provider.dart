import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/access/local_subject_resolver.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';

import '../data/datasources/daily_routine_preferences_local_datasource.dart';
import '../domain/entities/daily_routine_preferences.dart';
import '../domain/repositories/daily_routine_preferences_repository.dart';
import '../domain/repositories/daily_routine_preferences_repository_impl.dart';

final dailyRoutinePreferencesDatasourceProvider =
    Provider<DailyRoutinePreferencesLocalDatasource>((ref) {
      return const DailyRoutinePreferencesLocalDatasource();
    });

final dailyRoutineSubjectResolverProvider = Provider<LocalSubjectResolver>((ref) {
  return LocalSubjectResolver(
    currentActorId: currentSupabaseUserIdOrNull,
    pendingGuestUserId: AppPrefs.pendingGuestUserId,
  );
});

final dailyRoutinePreferencesRepositoryProvider =
    Provider<DailyRoutinePreferencesRepository>((ref) {
      final subjectResolver = ref.read(dailyRoutineSubjectResolverProvider);
      return DailyRoutinePreferencesRepositoryImpl(
        datasource: ref.read(dailyRoutinePreferencesDatasourceProvider),
        resolveSubjectId: subjectResolver.resolve,
      );
    });

final dailyRoutinePreferencesProvider =
    FutureProvider<DailyRoutinePreferences?>((ref) {
      return ref
          .read(dailyRoutinePreferencesRepositoryProvider)
          .loadForCurrentUser();
    });
