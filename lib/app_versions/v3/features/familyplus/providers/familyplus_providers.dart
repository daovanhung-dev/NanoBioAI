import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/domain/entities/effective_access.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/providers/membership_entitlement_providers.dart';

import '../data/datasources/familyplus_remote_datasource.dart';
import '../data/repositories/supabase_familyplus_repository.dart';
import '../domain/entities/familyplus_models.dart';
import '../domain/repositories/familyplus_repository.dart';

final familyPlusCurrentUserIdProvider = Provider.autoDispose<String?>((ref) {
  return ref.watch(currentAuthUserIdProvider);
});

final familyPlusEffectiveAccessProvider =
    FutureProvider.autoDispose<EffectiveAccess?>((ref) async {
      final userId = ref.watch(familyPlusCurrentUserIdProvider);
      if (userId == null || userId.trim().isEmpty) return null;

      // Share the canonical entitlement provider with checkout. Once a
      // manually approved payment becomes succeeded, the checkout invalidates
      // this provider so the covered FamilyPlus screen also rebuilds with the
      // server-authoritative plan rather than retaining a stale lock.
      final access = await ref.watch(effectiveAccessProvider.future);
      if (access == null || access.userId.trim() != userId.trim()) return null;
      return access;
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

final familyPlusContextProvider =
    FutureProvider.autoDispose<FamilyPlusViewModel>((ref) async {
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
        if (context.actorId.trim() != userId.trim()) {
          return const FamilyPlusViewModel.locked();
        }
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
          'Nabi chưa thể tải dữ liệu FamilyPlus lúc này.',
        );
      }
    });

final familyPlusCommandsProvider = Provider<FamilyPlusCommands>((ref) {
  return FamilyPlusCommands(
    repository: ref.read(familyPlusRepositoryProvider),
    invalidateContext: () => ref.invalidate(familyPlusContextProvider),
  );
});

/// Backward-compatible command provider. The command itself is single-flight,
/// so button double-taps or two presentation entry points share one request and
/// one idempotency key until that request settles.
final familyPlusCreateDefaultGroupProvider = Provider<Future<void> Function()>((
  ref,
) {
  return ref.watch(familyPlusCommandsProvider).createDefaultGroup;
});

final familyPlusSwitchSubjectProvider =
    Provider<String Function(FamilyPlusContext, String)>((ref) {
      return (context, subjectId) {
        return ref
            .read(familyPlusRepositoryProvider)
            .switchSubjectContext(context, requestedSubjectId: subjectId);
      };
    });

class FamilyPlusCommands {
  FamilyPlusCommands({
    required FamilyPlusRepository repository,
    required void Function() invalidateContext,
  }) : _repository = repository,
       _invalidateContext = invalidateContext;

  final FamilyPlusRepository _repository;
  final void Function() _invalidateContext;

  Future<void>? _createGroupInFlight;
  String? _createGroupIdempotencyKey;

  Future<void> createDefaultGroup() {
    final existing = _createGroupInFlight;
    if (existing != null) return existing;

    final key = _createGroupIdempotencyKey ??= _idempotencyKey('family-group');
    final future = _runCreateDefaultGroup(key);
    _createGroupInFlight = future;
    return future;
  }

  Future<void> _runCreateDefaultGroup(String key) async {
    try {
      await _repository.upsertGroup(
        FamilyPlusUpsertGroupCommand(
          displayName: 'Gia đình của tôi',
          idempotencyKey: key,
        ),
      );
      _invalidateContext();
    } finally {
      _createGroupInFlight = null;
      _createGroupIdempotencyKey = null;
    }
  }
}

String _idempotencyKey(String prefix) {
  return '$prefix-${DateTime.now().toUtc().microsecondsSinceEpoch}';
}
