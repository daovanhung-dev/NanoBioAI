import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/sale_referral/domain/services/sale_commission_calculator.dart';

void main() {
  group('SaleCommissionCalculator', () {
    test('estimates direct referral amount at 10 percent', () {
      final estimate = SaleCommissionCalculator.estimate(
        planAmountCents: 99000,
        directSuccessfulPayments: 3,
      );

      expect(estimate.directCommissionCents, 29700);
      expect(estimate.totalCommissionCents, 29700);
    });

    test('clamps invalid negative input instead of producing payout value', () {
      final estimate = SaleCommissionCalculator.estimate(
        planAmountCents: -1,
        directSuccessfulPayments: -4,
      );

      expect(estimate.totalCommissionCents, 0);
    });
  });
}
