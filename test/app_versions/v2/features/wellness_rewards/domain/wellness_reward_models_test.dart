import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/wellness_rewards/domain/entities/wellness_reward_models.dart';

void main() {
  group('Wellness reward models', () {
    test('summary parses numeric strings and ISO timestamps safely', () {
      final summary = WellnessRewardSummary.fromMap({
        'pending_points': '20',
        'available_points': 35.9,
        'expiring_soon_points': null,
        'next_expiry_at': '2026-12-31T17:00:00Z',
        'synced_at': '2026-07-13T03:04:05Z',
      });

      expect(summary.pendingPoints, 20);
      expect(summary.availablePoints, 35);
      expect(summary.expiringSoonPoints, 0);
      expect(summary.nextExpiryAt, DateTime.utc(2026, 12, 31, 17));
      expect(summary.syncedAt, DateTime.utc(2026, 7, 13, 3, 4, 5));
    });

    test('offer accepts RPC aliases and normalizes plan codes', () {
      final offer = WellnessRewardOffer.fromMap({
        'offer_id': 'offer-1',
        'title': 'Ưu đãi chăm sóc',
        'description': 'Giảm giá dịch vụ',
        'provider_name': 'Đối tác A',
        'cost_points': '30',
        'stock_count': 2.8,
        'eligible_plan_codes': ['free', 'plus', '', ' family_plus '],
        'is_active': 'false',
      });

      expect(offer.id, 'offer-1');
      expect(offer.costPoints, 30);
      expect(offer.availableCodes, 2);
      expect(offer.eligiblePlanCodes, ['free', 'plus', 'family_plus']);
      expect(offer.isActive, isFalse);
      expect(offer.isInStock, isTrue);
    });

    test('history defaults remain redeemable and parse legacy values', () {
      final entry = WellnessPointHistoryEntry.fromMap({
        'id': 'history-1',
        'points_delta': '-10',
        'is_redeemable': '0',
        'created_at': 'not-a-date',
      });

      expect(entry.pointsDelta, -10);
      expect(entry.eventType, 'award');
      expect(entry.status, 'available');
      expect(entry.isRedeemable, isFalse);
      expect(entry.createdAt, isNull);
    });

    test('redemption reads code aliases without exposing blank codes', () {
      final issued = WellnessRewardRedemption.fromMap({
        'redemption_id': 'redemption-1',
        'offer_id': 'offer-1',
        'cost_points': '40',
        'assigned_code': ' CODE-123 ',
        'status': 'issued',
      });
      final cancelled = WellnessRewardRedemption.fromMap({
        'id': 'redemption-2',
        'offer_id': 'offer-1',
        'points_spent': 40,
        'voucher_code': '   ',
        'status': 'CANCELLED',
      });

      expect(issued.voucherCode, 'CODE-123');
      expect(issued.pointsSpent, 40);
      expect(issued.isCancelled, isFalse);
      expect(cancelled.voucherCode, isNull);
      expect(cancelled.isCancelled, isTrue);
    });
  });

  group('WellnessRewardException', () {
    test('maps every stable user error to the canonical code', () {
      const cases = <String, String>{
        'auth_required': 'auth_required',
        'member_account_required': 'auth_required',
        'insufficient_points': 'insufficient_points',
        'offer_out_of_stock': 'offer_out_of_stock',
        'out_of_stock': 'offer_out_of_stock',
        'offer_ineligible': 'offer_ineligible',
        'offer_unavailable': 'offer_unavailable',
        'offer_expired': 'offer_unavailable',
        'offer_not_found': 'offer_unavailable',
        'offer_required': 'offer_unavailable',
        'offer_window_invalid': 'offer_unavailable',
        'redemption_not_found': 'redemption_unavailable',
        'redemption_required': 'redemption_unavailable',
        'wellness_rewards_disabled': 'program_unavailable',
        'reward_program_invalid': 'program_unavailable',
        'reward_program_not_configured': 'program_unavailable',
        'duplicate_request': 'duplicate_request',
        'idempotency_conflict': 'duplicate_request',
        'secure_storage_unavailable': 'secure_storage_unavailable',
      };

      for (final entry in cases.entries) {
        final exception = WellnessRewardException.fromCode(entry.key);
        expect(exception.code, entry.value, reason: entry.key);
        expect(exception.safeMessage.trim(), isNotEmpty, reason: entry.key);
        expect(
          exception.safeMessage.toLowerCase(),
          isNot(contains(entry.key)),
          reason: 'Không được hiển thị mã lỗi ${entry.key} lên giao diện.',
        );
      }
    });

    test('unknown backend content uses a safe Vietnamese fallback', () {
      final exception = WellnessRewardException.fromCode(
        'relation wellness_wallet does not exist',
      );

      expect(exception.code, 'unknown');
      expect(exception.safeMessage, contains('Nabi'));
      expect(exception.safeMessage, isNot(contains('wellness_wallet')));
      expect(exception.toString(), 'unknown');
    });
  });
}
