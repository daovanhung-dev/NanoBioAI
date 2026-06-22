import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/sale_referral/domain/services/sale_commission_calculator.dart';

void main() {
  group('SaleCommissionCalculator', () {
    test('estimates direct and second-level amounts independently', () {
      final estimate = SaleCommissionCalculator.estimate(
        planAmountCents: 99000,
        directSuccessfulPayments: 3,
        secondLevelSuccessfulPayments: 2,
      );

      expect(estimate.directCommissionCents, 29700);
      expect(estimate.secondLevelCommissionCents, 9900);
      expect(estimate.totalCommissionCents, 39600);
    });

    test('clamps invalid negative input instead of producing payout value', () {
      final estimate = SaleCommissionCalculator.estimate(
        planAmountCents: -1,
        directSuccessfulPayments: -4,
        secondLevelSuccessfulPayments: -2,
      );

      expect(estimate.totalCommissionCents, 0);
    });
  });
}
