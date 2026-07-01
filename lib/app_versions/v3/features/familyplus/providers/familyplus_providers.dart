import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/domain/entities/effective_access.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/providers/membership_entitlement_providers.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';

import '../data/datasources/familyplus_remote_datasource.dart';
import '../data/repositories/supabase_familyplus_repository.dart';
import '../domain/entities/familyplus_models.dart';
import '../domain/repositories/familyplus_repository.dart';

final familyPlusCurrentUserIdProvider = Provider<String?>((ref) {
  return currentSupabaseUserIdOrNull();
});

final familyPlusEffectiveAccessProvider = FutureProvider<EffectiveAccess?>((
  ref,
) {
  return ref.watch(effectiveAccessProvider.future);
});

final familyPlusRemoteDatasourceProvider = Provider<FamilyPlusRemoteDatasource>(
  (ref) {
    return const SupabaseFamilyPlusRemoteDatasource();
  },
);

final familyPlusRepositoryProvider = Provider<FamilyPlusRepository>((ref) {
  return SupabaseFamilyPlusRepository(
    datasource: ref.watch(familyPlusRemoteDatasourceProvider),
  );
});

final familyPlusContextProvider = FutureProvider<FamilyPlusViewModel>((
  ref,
) async {
  final userId = ref.watch(familyPlusCurrentUserIdProvider);
  if (userId == null || userId.trim().isEmpty) {
    return const FamilyPlusViewModel.authRequired();
  }

  final access = await ref.watch(familyPlusEffectiveAccessProvider.future);
  if (access == null || !access.isFamilyPlus) {
    return const FamilyPlusViewModel.locked();
  }

  try {
    final context = await ref
        .watch(familyPlusRepositoryProvider)
        .fetchContext();
    if (!context.hasFamilyPlus) return const FamilyPlusViewModel.locked();
    if (context.isEmpty) return FamilyPlusViewModel.empty(context);
    return FamilyPlusViewModel.ready(context);
  } on FamilyPlusException catch (error) {
    if (error.code == 'AUTH_REQUIRED') {
      return const FamilyPlusViewModel.authRequired();
    }
    if (error.code == 'FORBIDDEN') {
      return const FamilyPlusViewModel.locked();
    }
    return FamilyPlusViewModel.failure(error.safeMessage);
  } catch (_) {
    return const FamilyPlusViewModel.failure(
      'Nabi chua the tai du lieu FamilyPlus luc nay.',
    );
  }
});

final familyPlusCreateDefaultGroupProvider = Provider<Future<void> Function()>((
  ref,
) {
  return () async {
    final key = _idempotencyKey('family-group');
    await ref
        .read(familyPlusRepositoryProvider)
        .upsertGroup(
          FamilyPlusUpsertGroupCommand(
            displayName: 'Gia dinh cua toi',
            idempotencyKey: key,
          ),
        );
    ref.invalidate(familyPlusContextProvider);
  };
});

final familyPlusSwitchSubjectProvider =
    Provider<String Function(FamilyPlusContext, String)>((ref) {
      return (context, subjectId) {
        return ref
            .read(familyPlusRepositoryProvider)
            .switchSubjectContext(context, requestedSubjectId: subjectId);
      };
    });

String _idempotencyKey(String prefix) {
  return '$prefix-${DateTime.now().toUtc().microsecondsSinceEpoch}';
}
