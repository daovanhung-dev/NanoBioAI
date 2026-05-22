import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/onboarding_repository.dart';
import '../domain/repositories/onboarding_repository_impl.dart';
import '../data/datasource/onboarding_remote_datasource.dart';

final onboardingRemoteDatasourceProvider = Provider<OnboardingRemoteDatasource>(
  (ref) => const OnboardingRemoteDatasource(),
);

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepositoryImpl(
    remoteDatasource: ref.watch(onboardingRemoteDatasourceProvider),
  ),
);
