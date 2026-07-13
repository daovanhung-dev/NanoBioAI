import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/wellness_rewards/data/datasources/wellness_voucher_secure_store.dart';
import 'package:nano_app/app_versions/v2/features/wellness_rewards/domain/entities/wellness_reward_models.dart';
import 'package:nano_app/app_versions/v2/features/wellness_rewards/domain/repositories/wellness_rewards_repository.dart';
import 'package:nano_app/app_versions/v2/features/wellness_rewards/providers/wellness_rewards_providers.dart';

void main() {
  group('WellnessRewardsController secure voucher flow', () {
    test('uses secure local code before calling the private RPC', () async {
      final repository = _FakeRepository();
      final secureStore = _FakeSecureStore()
        ..codes['user-1:redemption-1'] = 'LOCAL-CODE';
      final container = _container(repository, secureStore);
      addTearDown(container.dispose);
      await container.read(wellnessRewardsControllerProvider.future);

      final code = await container
          .read(wellnessRewardsControllerProvider.notifier)
          .loadVoucherCode('redemption-1');

      expect(code, 'LOCAL-CODE');
      expect(repository.voucherCodeCalls, 0);
      expect(secureStore.readKeys, ['user-1:redemption-1']);
    });

    test(
      'downloads a missing code once and writes it to secure storage',
      () async {
        final repository = _FakeRepository(remoteVoucherCode: 'REMOTE-CODE');
        final secureStore = _FakeSecureStore();
        final container = _container(repository, secureStore);
        addTearDown(container.dispose);
        await container.read(wellnessRewardsControllerProvider.future);

        final code = await container
            .read(wellnessRewardsControllerProvider.notifier)
            .loadVoucherCode('redemption-1');

        expect(code, 'REMOTE-CODE');
        expect(repository.voucherCodeCalls, 1);
        expect(secureStore.codes['user-1:redemption-1'], 'REMOTE-CODE');
      },
    );

    test('redeem caches the issued code and refreshes the dashboard', () async {
      final repository = _FakeRepository();
      final secureStore = _FakeSecureStore();
      final container = _container(repository, secureStore);
      addTearDown(container.dispose);
      await container.read(wellnessRewardsControllerProvider.future);

      final redemption = await container
          .read(wellnessRewardsControllerProvider.notifier)
          .redeem('offer-1');

      expect(redemption.id, 'redemption-1');
      expect(secureStore.codes['user-1:redemption-1'], 'ISSUED-CODE');
      expect(repository.lastOfferId, 'offer-1');
      expect(repository.lastIdempotencyKey, startsWith('reward-offer-1-'));
      expect(repository.loadCalls, 2);
    });

    test('rejects a concurrent double tap for the same offer', () async {
      final pending = Completer<WellnessRewardRedemption>();
      final repository = _FakeRepository(redeemCompleter: pending);
      final secureStore = _FakeSecureStore();
      final container = _container(repository, secureStore);
      addTearDown(container.dispose);
      await container.read(wellnessRewardsControllerProvider.future);
      final controller = container.read(
        wellnessRewardsControllerProvider.notifier,
      );

      final first = controller.redeem('offer-1');
      await expectLater(
        controller.redeem('offer-1'),
        throwsA(
          isA<WellnessRewardException>().having(
            (error) => error.code,
            'code',
            'duplicate_request',
          ),
        ),
      );

      pending.complete(_issuedRedemption());
      await first;
      expect(repository.redeemCalls, 1);
    });

    test('reuses the persisted idempotency key after response loss', () async {
      final repository = _FakeRepository(
        redeemErrors: [WellnessRewardException.fromCode('unknown')],
      );
      final secureStore = _FakeSecureStore();
      final container = _container(repository, secureStore);
      addTearDown(container.dispose);
      await container.read(wellnessRewardsControllerProvider.future);
      final controller = container.read(
        wellnessRewardsControllerProvider.notifier,
      );

      await expectLater(
        controller.redeem('offer-1'),
        throwsA(isA<WellnessRewardException>()),
      );
      final firstKey = repository.idempotencyKeys.single;
      expect(secureStore.pendingKeys['user-1:offer-1'], firstKey);

      final redemption = await controller.redeem('offer-1');

      expect(redemption.id, 'redemption-1');
      expect(repository.idempotencyKeys, [firstKey, firstKey]);
      expect(secureStore.pendingKeys, isEmpty);
    });

    test('creates a new key after each confirmed redemption', () async {
      final repository = _FakeRepository();
      final secureStore = _FakeSecureStore();
      final container = _container(repository, secureStore);
      addTearDown(container.dispose);
      await container.read(wellnessRewardsControllerProvider.future);
      final controller = container.read(
        wellnessRewardsControllerProvider.notifier,
      );

      await controller.redeem('offer-1');
      await controller.redeem('offer-1');

      expect(repository.idempotencyKeys, hasLength(2));
      expect(
        repository.idempotencyKeys.first,
        isNot(repository.idempotencyKeys.last),
      );
    });

    test('requires an authenticated account before reading a code', () async {
      final repository = _FakeRepository();
      final secureStore = _FakeSecureStore();
      final container = ProviderContainer(
        overrides: [
          wellnessRewardsRepositoryProvider.overrideWithValue(repository),
          wellnessVoucherSecureStoreProvider.overrideWithValue(secureStore),
          wellnessRewardsUserIdProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);
      await container.read(wellnessRewardsControllerProvider.future);

      await expectLater(
        container
            .read(wellnessRewardsControllerProvider.notifier)
            .loadVoucherCode('redemption-1'),
        throwsA(
          isA<WellnessRewardException>().having(
            (error) => error.code,
            'code',
            'auth_required',
          ),
        ),
      );
    });
  });
}

ProviderContainer _container(
  WellnessRewardsRepository repository,
  WellnessVoucherSecureStore secureStore,
) {
  return ProviderContainer(
    overrides: [
      wellnessRewardsRepositoryProvider.overrideWithValue(repository),
      wellnessVoucherSecureStoreProvider.overrideWithValue(secureStore),
      wellnessRewardsUserIdProvider.overrideWithValue('user-1'),
    ],
  );
}

class _FakeRepository implements WellnessRewardsRepository {
  final String? remoteVoucherCode;
  final Completer<WellnessRewardRedemption>? redeemCompleter;
  final List<Object> redeemErrors;

  int loadCalls = 0;
  int redeemCalls = 0;
  int voucherCodeCalls = 0;
  String? lastOfferId;
  String? lastIdempotencyKey;
  final List<String> idempotencyKeys = <String>[];

  _FakeRepository({
    this.remoteVoucherCode = 'REMOTE-CODE',
    this.redeemCompleter,
    List<Object> redeemErrors = const [],
  }) : redeemErrors = List<Object>.of(redeemErrors);

  @override
  Future<WellnessRewardsDashboard> loadDashboard() async {
    loadCalls++;
    return const WellnessRewardsDashboard(
      summary: WellnessRewardSummary(
        pendingPoints: 10,
        availablePoints: 20,
        expiringSoonPoints: 0,
      ),
      offers: [],
      pointHistory: [],
      redemptions: [],
    );
  }

  @override
  Future<WellnessRewardRedemption> redeemOffer({
    required String offerId,
    required String idempotencyKey,
  }) async {
    redeemCalls++;
    lastOfferId = offerId;
    lastIdempotencyKey = idempotencyKey;
    idempotencyKeys.add(idempotencyKey);
    if (redeemErrors.isNotEmpty) throw redeemErrors.removeAt(0);
    return redeemCompleter == null
        ? _issuedRedemption()
        : redeemCompleter!.future;
  }

  @override
  Future<String?> loadVoucherCode(String redemptionId) async {
    voucherCodeCalls++;
    return remoteVoucherCode;
  }
}

class _FakeSecureStore implements WellnessVoucherSecureStore {
  final Map<String, String> codes = <String, String>{};
  final Map<String, String> pendingKeys = <String, String>{};
  final List<String> readKeys = <String>[];

  @override
  Future<String?> readCode({
    required String userId,
    required String redemptionId,
  }) async {
    final key = '$userId:$redemptionId';
    readKeys.add(key);
    return codes[key];
  }

  @override
  Future<void> writeCode({
    required String userId,
    required String redemptionId,
    required String code,
  }) async {
    codes['$userId:$redemptionId'] = code;
  }

  @override
  Future<void> deleteUserCodes(String userId) async {
    codes.removeWhere((key, value) => key.startsWith('$userId:'));
    pendingKeys.removeWhere((key, value) => key.startsWith('$userId:'));
  }

  @override
  Future<void> writePendingRedemptionKey({
    required String userId,
    required String offerId,
    required String idempotencyKey,
  }) async {
    pendingKeys['$userId:$offerId'] = idempotencyKey;
  }

  @override
  Future<String?> readPendingRedemptionKey({
    required String userId,
    required String offerId,
  }) async {
    return pendingKeys['$userId:$offerId'];
  }

  @override
  Future<void> deletePendingRedemptionKey({
    required String userId,
    required String offerId,
  }) async {
    pendingKeys.remove('$userId:$offerId');
  }
}

WellnessRewardRedemption _issuedRedemption() {
  return const WellnessRewardRedemption(
    id: 'redemption-1',
    offerId: 'offer-1',
    title: 'Voucher NanoBio',
    providerName: 'NanoBio',
    pointsSpent: 20,
    status: 'issued',
    voucherCode: 'ISSUED-CODE',
  );
}
