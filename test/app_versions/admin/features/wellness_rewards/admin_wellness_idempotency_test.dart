import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/admin/features/wellness_rewards/data/datasources/admin_wellness_mutation_idempotency_store.dart';
import 'package:nano_app/app_versions/admin/features/wellness_rewards/domain/entities/admin_wellness_reward_models.dart';
import 'package:nano_app/app_versions/admin/features/wellness_rewards/domain/repositories/admin_wellness_rewards_repository.dart';
import 'package:nano_app/app_versions/admin/features/wellness_rewards/providers/admin_wellness_rewards_providers.dart';

void main() {
  group('AdminWellnessMutationIdempotencyStore', () {
    test('reuses a pending key after the store is recreated', () async {
      final backend = _MemorySecureStore();
      final firstStore = OsAdminWellnessMutationIdempotencyStore(
        storage: backend,
        keyFactory: (_) => 'pending-key-1',
      );

      final first = await firstStore.acquire(
        userId: 'admin-1',
        operation: 'upsert_offer',
        fingerprint: 'same-request',
      );
      final recreatedStore = OsAdminWellnessMutationIdempotencyStore(
        storage: backend,
        keyFactory: (_) => 'must-not-be-used',
      );
      final second = await recreatedStore.acquire(
        userId: 'admin-1',
        operation: 'upsert_offer',
        fingerprint: 'same-request',
      );

      expect(first, 'pending-key-1');
      expect(second, first);
    });

    test('separates the same request content for different users', () async {
      var sequence = 0;
      final store = OsAdminWellnessMutationIdempotencyStore(
        storage: _MemorySecureStore(),
        keyFactory: (_) => 'key-${++sequence}',
      );

      final first = await store.acquire(
        userId: 'admin-1',
        operation: 'import_codes',
        fingerprint: 'same-batch',
      );
      final second = await store.acquire(
        userId: 'admin-2',
        operation: 'import_codes',
        fingerprint: 'same-batch',
      );

      expect(first, isNot(second));
    });

    test('rotates after success even when secure deletion fails', () async {
      var sequence = 0;
      final backend = _MemorySecureStore()..failDelete = true;
      final store = OsAdminWellnessMutationIdempotencyStore(
        storage: backend,
        keyFactory: (_) => 'key-${++sequence}',
      );

      final first = await store.acquire(
        userId: 'admin-1',
        operation: 'import_codes',
        fingerprint: 'batch-1',
      );
      await store.markSucceeded(
        userId: 'admin-1',
        operation: 'import_codes',
        fingerprint: 'batch-1',
        idempotencyKey: first,
      );
      final recreatedStore = OsAdminWellnessMutationIdempotencyStore(
        storage: backend,
        keyFactory: (_) => 'key-${++sequence}',
      );
      final second = await recreatedStore.acquire(
        userId: 'admin-1',
        operation: 'import_codes',
        fingerprint: 'batch-1',
      );

      expect(first, 'key-1');
      expect(second, 'key-2');
    });
  });

  group('AdminWellnessRewardsController idempotency', () {
    test('replays the same durable key after a response-loss error', () async {
      final repository = _FakeAdminRepository(
        mutationErrors: [
          const AdminWellnessRewardException(
            'Kết nối bị gián đoạn sau khi gửi yêu cầu.',
          ),
        ],
      );
      final backend = _MemorySecureStore();
      final firstStore = OsAdminWellnessMutationIdempotencyStore(
        storage: backend,
        keyFactory: (_) => 'durable-key-1',
      );
      final firstContainer = _container(repository, firstStore);
      await firstContainer.read(adminWellnessRewardsControllerProvider.future);

      await expectLater(
        firstContainer
            .read(adminWellnessRewardsControllerProvider.notifier)
            .upsertOffer(_offerCommand()),
        throwsA(isA<AdminWellnessRewardException>()),
      );
      firstContainer.dispose();

      final secondStore = OsAdminWellnessMutationIdempotencyStore(
        storage: backend,
        keyFactory: (_) => 'must-not-be-used',
      );
      final secondContainer = _container(repository, secondStore);
      addTearDown(secondContainer.dispose);
      await secondContainer.read(adminWellnessRewardsControllerProvider.future);
      await secondContainer
          .read(adminWellnessRewardsControllerProvider.notifier)
          .upsertOffer(_offerCommand());

      expect(repository.upsertKeys, ['durable-key-1', 'durable-key-1']);
      expect(backend.deleteCalls, 1);
    });

    test('protects upsert, import and cancel with operation keys', () async {
      var sequence = 0;
      final repository = _FakeAdminRepository();
      final store = OsAdminWellnessMutationIdempotencyStore(
        storage: _MemorySecureStore(),
        keyFactory: (operation) => '$operation-${++sequence}',
      );
      final container = _container(repository, store);
      addTearDown(container.dispose);
      await container.read(adminWellnessRewardsControllerProvider.future);
      final controller = container.read(
        adminWellnessRewardsControllerProvider.notifier,
      );

      await controller.upsertOffer(_offerCommand());
      await controller.importCodes(
        const AdminRewardCodeImportCommand(
          offerId: 'offer-1',
          codes: ['CODE-001', 'CODE-002'],
          reason: 'Nhập kho mã đợt một',
        ),
      );
      await controller.cancelRedemption(
        redemptionId: 'redemption-1',
        reason: 'Đã vô hiệu hóa mã ở nhà cung cấp',
      );

      expect(repository.upsertKeys, ['upsert_offer-1']);
      expect(repository.importKeys, ['import_codes-2']);
      expect(repository.cancelKeys, ['cancel_redemption-3']);
    });

    test('server success remains successful when secure clear fails', () async {
      var sequence = 0;
      final repository = _FakeAdminRepository();
      final backend = _MemorySecureStore()..failDelete = true;
      final store = OsAdminWellnessMutationIdempotencyStore(
        storage: backend,
        keyFactory: (_) => 'key-${++sequence}',
      );
      final container = _container(repository, store);
      addTearDown(container.dispose);
      await container.read(adminWellnessRewardsControllerProvider.future);
      final controller = container.read(
        adminWellnessRewardsControllerProvider.notifier,
      );

      final first = await controller.importCodes(
        const AdminRewardCodeImportCommand(
          offerId: 'offer-1',
          codes: ['CODE-001'],
          reason: 'Nhập kho mã',
        ),
      );
      final second = await controller.importCodes(
        const AdminRewardCodeImportCommand(
          offerId: 'offer-1',
          codes: ['CODE-001'],
          reason: 'Nhập kho mã',
        ),
      );

      expect(first.success, isTrue);
      expect(second.success, isTrue);
      expect(repository.importKeys, ['key-1', 'key-2']);
    });

    test('does not clear a pending key after a server error', () async {
      final repository = _FakeAdminRepository(
        mutationErrors: [
          const AdminWellnessRewardException('Máy chủ tạm thời gián đoạn.'),
        ],
      );
      final backend = _MemorySecureStore();
      final store = OsAdminWellnessMutationIdempotencyStore(
        storage: backend,
        keyFactory: (_) => 'still-pending',
      );
      final container = _container(repository, store);
      addTearDown(container.dispose);
      await container.read(adminWellnessRewardsControllerProvider.future);

      await expectLater(
        container
            .read(adminWellnessRewardsControllerProvider.notifier)
            .upsertOffer(_offerCommand()),
        throwsA(isA<AdminWellnessRewardException>()),
      );

      expect(backend.deleteCalls, 0);
      expect(backend.values.values.single, contains('pending'));
    });
  });
}

ProviderContainer _container(
  AdminWellnessRewardsRepository repository,
  AdminWellnessMutationIdempotencyStore store,
) {
  return ProviderContainer(
    overrides: [
      adminWellnessRewardsRepositoryProvider.overrideWithValue(repository),
      adminWellnessMutationIdempotencyStoreProvider.overrideWithValue(store),
      adminWellnessRewardsUserIdProvider.overrideWithValue('admin-1'),
    ],
  );
}

AdminRewardOfferCommand _offerCommand() {
  return const AdminRewardOfferCommand(
    offerId: 'offer-1',
    title: 'Ưu đãi chăm sóc sức khỏe',
    description: 'Nhận quà tặng dành cho thành viên NanoBio',
    providerName: 'NanoBio',
    costPoints: 50,
    eligiblePlanCodes: ['free', 'plus'],
    isActive: true,
    reason: 'Cập nhật danh mục ưu đãi',
  );
}

class _MemorySecureStore implements AdminWellnessSecureKeyValueStore {
  final Map<String, String> values = <String, String>{};
  bool failDelete = false;
  int deleteCalls = 0;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    deleteCalls++;
    if (failDelete) throw StateError('secure_delete_failed');
    values.remove(key);
  }
}

class _FakeAdminRepository implements AdminWellnessRewardsRepository {
  final List<Object> mutationErrors;
  final List<String> upsertKeys = <String>[];
  final List<String> importKeys = <String>[];
  final List<String> cancelKeys = <String>[];

  _FakeAdminRepository({List<Object> mutationErrors = const []})
    : mutationErrors = List<Object>.of(mutationErrors);

  @override
  Future<AdminWellnessRewardsSnapshot> load({String query = ''}) async {
    return const AdminWellnessRewardsSnapshot(offers: [], redemptions: []);
  }

  @override
  Future<AdminRewardMutationResult> upsertOffer(
    AdminRewardOfferCommand command,
  ) async {
    upsertKeys.add(command.idempotencyKey);
    _throwNextError();
    return _success();
  }

  @override
  Future<AdminRewardMutationResult> importCodes(
    AdminRewardCodeImportCommand command,
  ) async {
    importKeys.add(command.idempotencyKey);
    _throwNextError();
    return _success();
  }

  @override
  Future<AdminRewardMutationResult> cancelRedemption({
    required String redemptionId,
    required String reason,
    required String idempotencyKey,
  }) async {
    cancelKeys.add(idempotencyKey);
    _throwNextError();
    return _success();
  }

  void _throwNextError() {
    if (mutationErrors.isNotEmpty) throw mutationErrors.removeAt(0);
  }

  AdminRewardMutationResult _success() {
    return const AdminRewardMutationResult(
      success: true,
      message: 'Đã cập nhật dữ liệu ưu đãi.',
    );
  }
}
