import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/daily_health_tracking/providers/daily_health_tracking_provider.dart';
import 'package:nano_app/core/access/local_subject_resolver.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';

import '../data/water_tracking_local_store.dart';
import '../data/water_tracking_repository_impl.dart';
import '../domain/water_tracking_repository.dart';

final waterTrackingLocalStoreProvider = Provider<WaterTrackingLocalStore>(
  (_) => const SharedPreferencesWaterTrackingLocalStore(),
);

final waterTrackingSubjectResolverProvider = Provider<LocalSubjectResolver>((_) {
  return LocalSubjectResolver(
    currentActorId: currentSupabaseUserIdOrNull,
    pendingGuestUserId: AppPrefs.pendingGuestUserId,
  );
});

final waterTrackingRepositoryProvider = Provider<WaterTrackingRepository>((ref) {
  return IntegratedWaterTrackingRepository(
    localStore: ref.watch(waterTrackingLocalStoreProvider),
    dailyHealthRepository: ref.watch(dailyHealthTrackingRepositoryProvider),
    subjectResolver: ref.watch(waterTrackingSubjectResolverProvider),
  );
});
