import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/onboarding_repository.dart';
import '../domain/repositories/onboarding_repository_impl.dart';
import '../data/datasource/onboarding_local_datasource.dart';

final onboardingLocalDatasourceProvider = Provider<OnboardingLocalDatasource>(
  (ref) => const OnboardingLocalDatasource(),
);

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepositoryImpl(
    localDatasource: ref.watch(onboardingLocalDatasourceProvider),
  ),
);
