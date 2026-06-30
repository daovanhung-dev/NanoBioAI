import 'package:nano_app/app_versions/v2/features/membership_entitlement/domain/entities/effective_access.dart';

abstract class EffectiveAccessRepository {
  Future<EffectiveAccess?> fetchCurrentAccess();
}
