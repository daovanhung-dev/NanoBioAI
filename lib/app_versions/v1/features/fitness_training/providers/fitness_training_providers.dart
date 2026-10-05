import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';

import '../application/fitness_training_controller.dart';
import '../application/fitness_training_service.dart';
import '../data/datasources/fitness_training_local_datasource.dart';
import '../data/datasources/fitness_training_profile_local_datasource.dart';
import '../data/repositories/fitness_training_profile_repository_impl.dart';

final fitnessTrainingControllerProvider = Provider<FitnessTrainingController>((
  ref,
) {
  final profileRepository = FitnessTrainingProfileRepositoryImpl(
    datasource: const FitnessTrainingProfileLocalDatasource(),
  );
  return FitnessTrainingController(
    service: FitnessTrainingService(
      repository: const FitnessTrainingLocalDatasource(),
    ),
    profileRepository: profileRepository,
    currentUserId: currentSupabaseUserIdOrNull,
  );
});
