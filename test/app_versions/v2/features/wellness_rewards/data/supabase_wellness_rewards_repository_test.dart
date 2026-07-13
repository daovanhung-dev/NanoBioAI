import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/wellness_rewards/data/datasources/wellness_rewards_local_datasource.dart';
import 'package:nano_app/app_versions/v2/features/wellness_rewards/data/datasources/wellness_rewards_remote_datasource.dart';
import 'package:nano_app/app_versions/v2/features/wellness_rewards/data/repositories/supabase_wellness_rewards_repository.dart';
import 'package:nano_app/app_versions/v2/features/wellness_rewards/domain/entities/wellness_reward_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('SupabaseWellnessRewardsRepository', () {
    test(
      'builds a dashboard, filters invalid rows, and updates cache',
      () async {
        final remote = _FakeRemoteDatasource();
        final local = _FakeLocalDatasource();
        final repository = SupabaseWellnessRewardsRepository(
          remoteDatasource: remote,
          localDatasource: local,
          currentUserId: () => 'user-1',
        );

        final result = await repository.loadDashboard();

        expect(result.summary.availablePoints, 30);
        expect(result.offers.map((item) => item.id), ['offer-active']);
        expect(result.pointHistory.map((item) => item.id), ['history-1']);
        expect(result.redemptions.map((item) => item.id), ['redemption-1']);
        expect(local.replacedUserId, 'user-1');
        expect(local.replacedDashboard, same(result));
      },
    );

    test(
      'returns account-scoped cache when an unknown network error occurs',
      () async {
        final cached = _cachedDashboard();
        final remote = _FakeRemoteDatasource(loadError: StateError('offline'));
        final local = _FakeLocalDatasource(cachedDashboard: cached);
        final repository = SupabaseWellnessRewardsRepository(
          remoteDatasource: remote,
          localDatasource: local,
          currentUserId: () => 'user-1',
        );

        final result = await repository.loadDashboard();

        expect(result, same(cached));
        expect(local.loadedUserId, 'user-1');
      },
    );

    test('does not use cache for a known business error', () async {
      final remote = _FakeRemoteDatasource(
        loadError: WellnessRewardException.fromCode('auth_required'),
      );
      final local = _FakeLocalDatasource(cachedDashboard: _cachedDashboard());
      final repository = SupabaseWellnessRewardsRepository(
        remoteDatasource: remote,
        localDatasource: local,
        currentUserId: () => 'user-1',
      );

      await expectLater(
        repository.loadDashboard(),
        throwsA(
          isA<WellnessRewardException>().having(
            (error) => error.code,
            'code',
            'auth_required',
          ),
        ),
      );
      expect(local.loadedUserId, isNull);
    });

    test('server redemption denial maps to a stable safe error', () async {
      final remote = _FakeRemoteDatasource(
        redeemResponse: const {
          'success': false,
          'error_code': 'insufficient_points',
        },
      );
      final repository = SupabaseWellnessRewardsRepository(
        remoteDatasource: remote,
        localDatasource: _FakeLocalDatasource(),
        currentUserId: () => 'user-1',
      );

      await expectLater(
        repository.redeemOffer(offerId: 'offer-1', idempotencyKey: 'request-1'),
        throwsA(
          isA<WellnessRewardException>().having(
            (error) => error.code,
            'code',
            'insufficient_points',
          ),
        ),
      );
    });

    test(
      'PostgREST out-of-stock text is normalized without leaking it',
      () async {
        final remote = _FakeRemoteDatasource(
          redeemError: const PostgrestException(
            message: 'rpc failed: offer_out_of_stock',
            code: 'P0001',
          ),
        );
        final repository = SupabaseWellnessRewardsRepository(
          remoteDatasource: remote,
          localDatasource: _FakeLocalDatasource(),
          currentUserId: () => 'user-1',
        );

        await expectLater(
          repository.redeemOffer(
            offerId: 'offer-1',
            idempotencyKey: 'request-1',
          ),
          throwsA(
            isA<WellnessRewardException>()
                .having((error) => error.code, 'code', 'offer_out_of_stock')
                .having(
                  (error) => error.safeMessage,
                  'safeMessage',
                  isNot(contains('P0001')),
                ),
          ),
        );
      },
    );

    test(
      'successful redemption remains successful when cache write fails',
      () async {
        final local = _FakeLocalDatasource(throwOnWrite: true);
        final repository = SupabaseWellnessRewardsRepository(
          remoteDatasource: _FakeRemoteDatasource(),
          localDatasource: local,
          currentUserId: () => 'user-1',
        );

        final result = await repository.redeemOffer(
          offerId: 'offer-active',
          idempotencyKey: 'request-1',
        );

        expect(result.id, 'redemption-1');
        expect(result.voucherCode, 'PRIVATE-CODE');
        expect(local.upsertedUserId, 'user-1');
      },
    );
  });
}

class _FakeRemoteDatasource implements WellnessRewardsRemoteDatasource {
  final Object? loadError;
  final Object? redeemError;
  final Map<String, Object?>? redeemResponse;

  _FakeRemoteDatasource({
    this.loadError,
    this.redeemError,
    this.redeemResponse,
  });

  @override
  Future<Map<String, Object?>> getSummary() async {
    if (loadError != null) throw loadError!;
    return const {
      'pending_points': 10,
      'available_points': 30,
      'expiring_soon_points': 5,
    };
  }

  @override
  Future<List<Map<String, Object?>>> listOffers({int limit = 100}) async {
    return const [
      {
        'id': 'offer-active',
        'title': 'Ưu đãi đang mở',
        'description': 'Mô tả',
        'provider_name': 'NanoBio',
        'cost_points': 20,
        'available_codes': 3,
        'eligible_plan_codes': ['free'],
        'is_active': true,
      },
      {'id': 'offer-disabled', 'title': 'Ưu đãi đã tắt', 'is_active': false},
      {'id': '', 'title': 'Dòng lỗi', 'is_active': true},
    ];
  }

  @override
  Future<List<Map<String, Object?>>> listPointHistory({int limit = 100}) async {
    return const [
      {
        'id': 'history-1',
        'points_delta': 10,
        'event_type': 'schedule_completion',
        'status': 'pending',
        'title': 'Hoàn thành nhiệm vụ',
        'is_redeemable': true,
      },
      {'id': '', 'points_delta': 999},
    ];
  }

  @override
  Future<List<Map<String, Object?>>> listRedemptions({int limit = 100}) async {
    return const [
      {
        'id': 'redemption-1',
        'offer_id': 'offer-active',
        'title': 'Voucher NanoBio',
        'provider_name': 'NanoBio',
        'points_spent': 20,
        'status': 'issued',
      },
      {'id': '', 'offer_id': 'offer-active'},
    ];
  }

  @override
  Future<Map<String, Object?>> redeemOffer({
    required String offerId,
    required String idempotencyKey,
  }) async {
    if (redeemError != null) throw redeemError!;
    return redeemResponse ??
        const {
          'success': true,
          'redemption_id': 'redemption-1',
          'offer_id': 'offer-active',
          'title': 'Voucher NanoBio',
          'provider_name': 'NanoBio',
          'points_spent': 20,
          'status': 'issued',
          'voucher_code': 'PRIVATE-CODE',
        };
  }

  @override
  Future<String?> getVoucherCode(String redemptionId) async => 'PRIVATE-CODE';
}

class _FakeLocalDatasource extends WellnessRewardsLocalDatasource {
  final WellnessRewardsDashboard? cachedDashboard;
  final bool throwOnWrite;

  String? loadedUserId;
  String? replacedUserId;
  String? upsertedUserId;
  WellnessRewardsDashboard? replacedDashboard;

  _FakeLocalDatasource({this.cachedDashboard, this.throwOnWrite = false});

  @override
  Future<WellnessRewardsDashboard?> loadDashboard(String userId) async {
    loadedUserId = userId;
    return cachedDashboard;
  }

  @override
  Future<void> replaceDashboard({
    required String userId,
    required WellnessRewardsDashboard dashboard,
  }) async {
    replacedUserId = userId;
    replacedDashboard = dashboard;
    if (throwOnWrite) throw StateError('cache unavailable');
  }

  @override
  Future<void> upsertRedemption({
    required String userId,
    required WellnessRewardRedemption redemption,
  }) async {
    upsertedUserId = userId;
    if (throwOnWrite) throw StateError('cache unavailable');
  }
}

WellnessRewardsDashboard _cachedDashboard() {
  return const WellnessRewardsDashboard(
    summary: WellnessRewardSummary(
      pendingPoints: 0,
      availablePoints: 90,
      expiringSoonPoints: 10,
    ),
    offers: [],
    pointHistory: [],
    redemptions: [],
  );
}
