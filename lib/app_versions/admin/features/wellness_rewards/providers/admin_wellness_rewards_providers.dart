import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/network/backend_api_client.dart';

import '../data/datasources/admin_wellness_mutation_idempotency_store.dart';
import '../data/datasources/backend_admin_wellness_rewards_remote_datasource.dart';
import '../data/repositories/backend_admin_wellness_rewards_repository.dart';
import '../domain/entities/admin_wellness_reward_models.dart';
import '../domain/repositories/admin_wellness_rewards_repository.dart';

final adminWellnessRewardsDatasourceProvider =
    Provider<BackendAdminWellnessRewardsRemoteDatasource>((ref) {
      return const BackendAdminWellnessRewardsRemoteDatasource();
    });

final adminWellnessRewardsUserIdProvider = Provider<String?>((ref) {
  return BackendApiClient.shared.currentUserId;
});

final adminWellnessMutationIdempotencyStoreProvider =
    Provider<AdminWellnessMutationIdempotencyStore>((ref) {
      return OsAdminWellnessMutationIdempotencyStore();
    });

final adminWellnessRewardsRepositoryProvider =
    Provider<AdminWellnessRewardsRepository>((ref) {
      return BackendAdminWellnessRewardsRepository(
        datasource: ref.watch(adminWellnessRewardsDatasourceProvider),
      );
    });

final adminWellnessRewardsControllerProvider =
    AsyncNotifierProvider<
      AdminWellnessRewardsController,
      AdminWellnessRewardsSnapshot
    >(AdminWellnessRewardsController.new);

class AdminWellnessRewardsController
    extends AsyncNotifier<AdminWellnessRewardsSnapshot> {
  bool _mutating = false;

  @override
  Future<AdminWellnessRewardsSnapshot> build() {
    return ref.read(adminWellnessRewardsRepositoryProvider).load();
  }

  Future<void> refresh({String query = ''}) async {
    state = await AsyncValue.guard(
      () => ref.read(adminWellnessRewardsRepositoryProvider).load(query: query),
    );
  }

  Future<AdminRewardMutationResult> upsertOffer(
    AdminRewardOfferCommand command,
  ) {
    return _runMutation(
      operation: 'upsert_offer',
      fingerprint: AdminWellnessMutationFingerprint.upsertOffer(command),
      operationCall: (idempotencyKey) => ref
          .read(adminWellnessRewardsRepositoryProvider)
          .upsertOffer(command.withIdempotencyKey(idempotencyKey)),
    );
  }

  Future<AdminRewardMutationResult> importCodes(
    AdminRewardCodeImportCommand command,
  ) {
    return _runMutation(
      operation: 'import_codes',
      fingerprint: AdminWellnessMutationFingerprint.importCodes(command),
      operationCall: (idempotencyKey) => ref
          .read(adminWellnessRewardsRepositoryProvider)
          .importCodes(command.withIdempotencyKey(idempotencyKey)),
    );
  }

  Future<AdminRewardMutationResult> cancelRedemption({
    required String redemptionId,
    required String reason,
  }) {
    return _runMutation(
      operation: 'cancel_redemption',
      fingerprint: AdminWellnessMutationFingerprint.cancelRedemption(
        redemptionId: redemptionId,
        reason: reason,
      ),
      operationCall: (idempotencyKey) => ref
          .read(adminWellnessRewardsRepositoryProvider)
          .cancelRedemption(
            redemptionId: redemptionId,
            reason: reason,
            idempotencyKey: idempotencyKey,
          ),
    );
  }

  Future<AdminRewardMutationResult> markRedemptionReceived({
    required String redemptionId,
    required String reason,
  }) {
    return _runMutation(
      operation: 'mark_received',
      fingerprint: AdminWellnessMutationFingerprint.receivedRedemption(
        redemptionId: redemptionId,
        reason: reason,
      ),
      operationCall: (idempotencyKey) => ref
          .read(adminWellnessRewardsRepositoryProvider)
          .markRedemptionReceived(
            redemptionId: redemptionId,
            reason: reason,
            idempotencyKey: idempotencyKey,
          ),
    );
  }

  Future<AdminRewardMutationResult> _runMutation({
    required String operation,
    required String fingerprint,
    required Future<AdminRewardMutationResult> Function(String idempotencyKey)
    operationCall,
  }) async {
    if (_mutating) {
      throw const AdminWellnessRewardException(
        'Một yêu cầu khác đang được xử lý. Hãy chờ trong giây lát.',
      );
    }
    _mutating = true;
    try {
      final userId = ref.read(adminWellnessRewardsUserIdProvider)?.trim();
      if (userId == null || userId.isEmpty) {
        throw const AdminWellnessRewardException(
          'Phiên quản trị đã hết hạn. Hãy đăng nhập lại.',
        );
      }
      final idempotencyStore = ref.read(
        adminWellnessMutationIdempotencyStoreProvider,
      );
      final idempotencyKey = await idempotencyStore.acquire(
        userId: userId,
        operation: operation,
        fingerprint: fingerprint,
      );
      final result = await operationCall(idempotencyKey);
      try {
        await idempotencyStore.markSucceeded(
          userId: userId,
          operation: operation,
          fingerprint: fingerprint,
          idempotencyKey: idempotencyKey,
        );
      } catch (_) {
        // Máy chủ đã xử lý xong; lỗi dọn khóa cục bộ không được báo thất bại giả.
      }
      try {
        final refreshed = await ref
            .read(adminWellnessRewardsRepositoryProvider)
            .load();
        state = AsyncData(refreshed);
      } catch (_) {
        // Mutation đã thành công; người dùng có thể tải lại danh sách sau.
      }
      return result;
    } finally {
      _mutating = false;
    }
  }
}
