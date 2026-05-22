import '../../data/datasource/onboarding_remote_datasource.dart';
import '../entities/onboarding_entity.dart';
import 'onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final OnboardingRemoteDatasource remoteDatasource;

  OnboardingRepositoryImpl({
    required this.remoteDatasource,
  });

  @override
  Future<void> save(OnboardingEntity entity) {
    return remoteDatasource.saveOnboarding(entity);
  }
}
