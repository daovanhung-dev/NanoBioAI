import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/data/datasources/nutrition_profile_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/data/repositories/nutrition_profile_repository_impl.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/domain/entities/nutrition_profile_entity.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/domain/repositories/nutrition_profile_repository.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/presentation/controllers/nutrition_profile_controller.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';

final nutritionProfileLocalDatasourceProvider =
    Provider<NutritionProfileLocalDatasource>((ref) {
      return const NutritionProfileLocalDatasource();
    });

final nutritionProfileRepositoryProvider = Provider<NutritionProfileRepository>(
  (ref) {
    return NutritionProfileRepositoryImpl(
      localDatasource: ref.read(nutritionProfileLocalDatasourceProvider),
    );
  },
);

final nutritionProfileControllerProvider =
    AsyncNotifierProvider<NutritionProfileController, NutritionProfileEntity>(
      NutritionProfileController.new,
    );

final activeNutritionProfileUserIdProvider = Provider<String>((ref) {
  return ref.watch(currentAuthUserIdProvider)?.trim() ?? '';
});
