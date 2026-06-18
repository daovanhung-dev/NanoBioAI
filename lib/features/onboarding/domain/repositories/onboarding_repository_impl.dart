import 'package:nano_app/core/utils/logger/app_logger.dart';

import '../../data/datasource/onboarding_local_datasource.dart';
import '../entities/onboarding_entity.dart';
import 'onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  static const _tag = 'ONBOARDING_REPO';

  final OnboardingLocalDatasource localDatasource;

  OnboardingRepositoryImpl({required this.localDatasource});

  @override
  Future<void> save(OnboardingEntity entity) async {
    try {
      AppLogger.info(_tag, 'Delegating save to local datasource');
      await localDatasource.saveOnboarding(entity);
      AppLogger.success(_tag, 'Save completed successfully');
    } catch (e, st) {
      AppLogger.error(_tag, 'Repository save failed', e, st);
      rethrow;
    }
  }
}
