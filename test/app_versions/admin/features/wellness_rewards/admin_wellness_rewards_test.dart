import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/admin/features/wellness_rewards/data/datasources/admin_wellness_rewards_remote_datasource.dart';
import 'package:nano_app/app_versions/admin/features/wellness_rewards/data/repositories/supabase_admin_wellness_rewards_repository.dart';
import 'package:nano_app/app_versions/admin/features/wellness_rewards/domain/entities/admin_wellness_reward_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Admin wellness reward models', () {
    test('offer parses RPC aliases and typed values', () {
      final offer = AdminWellnessRewardOffer.fromMap({
        'offer_id': 'offer-1',
        'title': 'Ưu đãi sức khỏe',
        'description': 'Mô tả có dấu',
        'provider_name': 'Đối tác A',
        'cost_points': '50',
        'stock_count': 12.8,
        'issued_codes': '3',
        'eligible_plan_codes': ['free', ' plus ', ''],
        'is_active': '0',
        'available_from': '2026-07-14T00:00:00Z',
      });

      expect(offer.id, 'offer-1');
      expect(offer.costPoints, 50);
      expect(offer.availableCodes, 12);
      expect(offer.issuedCodes, 3);
      expect(offer.eligiblePlanCodes, ['free', 'plus']);
      expect(offer.isActive, isFalse);
      expect(offer.availableFrom, DateTime.utc(2026, 7, 14));
    });

    test('only an issued voucher can be cancelled', () {
      final issued = AdminWellnessRewardRedemption.fromMap({
        'redemption_id': 'redemption-issued',
        'status': ' ISSUED ',
      });
      final cancelled = AdminWellnessRewardRedemption.fromMap({
        'redemption_id': 'redemption-cancelled',
        'status': 'cancelled',
      });

      expect(issued.canCancel, isTrue);
      expect(cancelled.canCancel, isFalse);
    });

    test('bulk import statistics parse numeric server values', () {
      final result = AdminRewardMutationResult.fromMap({
        'success': 'true',
        'message': 'Đã nhập kho mã.',
        'accepted_count': '8',
        'duplicate_count': 2.9,
        'rejected_count': null,
      });

      expect(result.success, isTrue);
      expect(result.acceptedCount, 8);
      expect(result.duplicateCount, 2);
      expect(result.rejectedCount, 0);
    });
  });

  group('SupabaseAdminWellnessRewardsRepository', () {
    test('splits wrapped offer and redemption results safely', () async {
      final datasource = _FakeAdminDatasource(
        listResponse: const {
          'offers': [
            {
              'id': 'offer-1',
              'title': 'Ưu đãi một',
              'cost_points': 20,
              'available_codes': 4,
              'issued_codes': 1,
              'eligible_plan_codes': ['free'],
              'is_active': true,
            },
            {'id': '', 'title': 'Dòng không hợp lệ'},
          ],
          'redemptions': [
            {
              'id': 'redemption-1',
              'title': 'Voucher một',
              'points_spent': 20,
              'status': 'issued',
              'masked_code': '••••1234',
            },
            {'id': '', 'title': 'Dòng không hợp lệ'},
          ],
        },
      );
      final repository = SupabaseAdminWellnessRewardsRepository(
        datasource: datasource,
      );

      final snapshot = await repository.load(query: ' nano ');

      expect(snapshot.offers.map((item) => item.id), ['offer-1']);
      expect(snapshot.redemptions.map((item) => item.id), ['redemption-1']);
      expect(datasource.lastQuery, ' nano ');
    });

    test('forwards offer command and returns mutation counters', () async {
      final datasource = _FakeAdminDatasource(
        mutationResponse: const {
          'success': true,
          'message': 'Đã lưu ưu đãi.',
          'accepted_count': 1,
        },
      );
      final repository = SupabaseAdminWellnessRewardsRepository(
        datasource: datasource,
      );
      final command = AdminRewardOfferCommand(
        offerId: 'offer-1',
        title: 'Ưu đãi chăm sóc',
        description: 'Mô tả tiếng Việt có dấu',
        providerName: 'NanoBio',
        costPoints: 50,
        eligiblePlanCodes: const ['free', 'plus'],
        availableFrom: DateTime.utc(2026, 7, 14),
        isActive: true,
        reason: 'Cập nhật catalog',
        idempotencyKey: 'admin-offer-1',
      );

      final result = await repository.upsertOffer(command);

      expect(result.success, isTrue);
      expect(result.acceptedCount, 1);
      expect(datasource.lastOfferCommand, same(command));
    });

    test('maps Vietnamese copy validation failure to a safe message', () async {
      final datasource = _FakeAdminDatasource(
        mutationError: const PostgrestException(
          message: 'invalid_vietnamese_copy',
          code: 'P0001',
        ),
      );
      final repository = SupabaseAdminWellnessRewardsRepository(
        datasource: datasource,
      );

      await expectLater(
        repository.upsertOffer(
          const AdminRewardOfferCommand(
            title: 'Offer',
            description: 'English text',
            providerName: 'NanoBio',
            costPoints: 20,
            eligiblePlanCodes: ['free'],
            isActive: true,
            reason: 'Kiểm thử',
            idempotencyKey: 'invalid-copy-1',
          ),
        ),
        throwsA(
          isA<AdminWellnessRewardException>()
              .having(
                (error) => error.safeMessage,
                'safeMessage',
                contains('tiếng Việt'),
              )
              .having(
                (error) => error.safeMessage,
                'safeMessage',
                isNot(contains('P0001')),
              ),
        ),
      );
    });

    test('rejects a server mutation result that is not successful', () async {
      final repository = SupabaseAdminWellnessRewardsRepository(
        datasource: _FakeAdminDatasource(
          mutationResponse: const {
            'success': false,
            'message': 'technical backend detail',
          },
        ),
      );

      await expectLater(
        repository.cancelRedemption(
          redemptionId: 'redemption-1',
          reason: 'Đã xử lý mã bên ngoài',
          idempotencyKey: 'cancel-1',
        ),
        throwsA(
          isA<AdminWellnessRewardException>().having(
            (error) => error.safeMessage,
            'safeMessage',
            isNot(contains('technical backend detail')),
          ),
        ),
      );
    });
  });

  test('admin datasource keeps RPC names and external revocation guard', () {
    final source = File(
      'lib/app_versions/admin/features/wellness_rewards/data/datasources/'
      'admin_wellness_rewards_remote_datasource.dart',
    ).readAsStringSync();

    expect(source, contains("'admin_list_wellness_rewards'"));
    expect(source, contains("'admin_upsert_reward_offer'"));
    expect(source, contains("'admin_import_reward_codes'"));
    expect(source, contains("'admin_cancel_reward_redemption'"));
    expect(source, contains("'p_external_revocation_confirmed': true"));
  });
}

class _FakeAdminDatasource extends AdminWellnessRewardsRemoteDatasource {
  final Object? listResponse;
  final Object? mutationResponse;
  final Object? mutationError;

  String? lastQuery;
  AdminRewardOfferCommand? lastOfferCommand;

  _FakeAdminDatasource({
    this.listResponse,
    this.mutationResponse,
    this.mutationError,
  });

  @override
  Future<Object?> list({String query = '', int limit = 100}) async {
    lastQuery = query;
    if (mutationError != null) throw mutationError!;
    return listResponse ?? const [];
  }

  @override
  Future<Object?> upsertOffer(AdminRewardOfferCommand command) async {
    lastOfferCommand = command;
    if (mutationError != null) throw mutationError!;
    return mutationResponse ?? const {'success': true};
  }

  @override
  Future<Object?> importCodes(AdminRewardCodeImportCommand command) async {
    if (mutationError != null) throw mutationError!;
    return mutationResponse ?? const {'success': true};
  }

  @override
  Future<Object?> cancelRedemption({
    required String redemptionId,
    required String reason,
    required String idempotencyKey,
  }) async {
    if (mutationError != null) throw mutationError!;
    return mutationResponse ?? const {'success': true};
  }
}
