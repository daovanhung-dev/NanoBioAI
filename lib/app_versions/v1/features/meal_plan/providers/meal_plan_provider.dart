import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/datasources/meal_plan_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_plan_entity.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/repositories/meal_plan_repository.dart';
import 'package:nano_app/core/access/local_subject_resolver.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';

import '../domain/repositories/meal_plan_repository_impl.dart';

final mealPlanLocalDatasourceProvider = Provider<MealPlanLocalDatasource>((
  ref,
) {
  return const MealPlanLocalDatasource();
});

final mealPlanSubjectResolverProvider = Provider<LocalSubjectResolver>((ref) {
  return LocalSubjectResolver(
    currentActorId: currentSupabaseUserIdOrNull,
    pendingGuestUserId: AppPrefs.pendingGuestUserId,
  );
});

final mealPlanRepositoryProvider = Provider<MealPlanRepository>((ref) {
  final subjectResolver = ref.read(mealPlanSubjectResolverProvider);
  return MealPlanRepositoryImpl(
    datasource: ref.read(mealPlanLocalDatasourceProvider),
    resolveSubjectId: subjectResolver.resolve,
  );
});

final getMealPlanProvider = FutureProvider<List<MealPlanEntity>>((ref) async {
  final repository = ref.read(mealPlanRepositoryProvider);
  return repository.getMealByWeeks();
});
