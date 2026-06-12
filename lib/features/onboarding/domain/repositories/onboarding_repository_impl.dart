import '../../data/datasource/onboarding_local_datasource.dart';
import '../entities/onboarding_entity.dart';
import 'onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final OnboardingLocalDatasource localDatasource;

  OnboardingRepositoryImpl({
    required this.localDatasource,
  });

  @override
  Future<void> save(OnboardingEntity entity) {
    return localDatasource.saveOnboarding(entity);
  }
}
