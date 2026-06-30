import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/sale_referral/domain/entities/sale_models.dart';
import 'package:nano_app/sale_referral/domain/services/sale_conversion_policy_service.dart';
import 'package:nano_app/sale_referral/domain/services/sale_referral_code_validator.dart';

void main() {
  group('SaleState', () {
    test('maps pending_review to pending for BD compatibility', () {
      final state = SaleState.fromMap({
        'sale_status': 'pending_review',
        'referral_code': '',
      });

      expect(state.status, SaleStatus.pending);
      expect(state.isPending, isTrue);
      expect(state.referralCode, isNull);
    });
  });

  group('SaleReferralCodeValidator', () {
    test('normalizes uppercase codes and rejects unsafe characters', () {
      const validator = SaleReferralCodeValidator();

      expect(validator.normalize(' nano-1234 '), 'NANO-1234');
      expect(validator.validate('NANO-1234'), isNull);
      expect(validator.validate('NANO@1234'), isNotNull);
    });
  });

  group('SaleConversionPolicyService', () {
    test('blocks conversion when config is disabled or below minimum', () {
      const service = SaleConversionPolicyService();

      expect(
        service.validateRequest(
          policy: const SaleConversionPolicy.disabled(),
          availablePointCents: 200000,
          requestedPointCents: 100000,
        ),
        isNotNull,
      );

      expect(
        service.validateRequest(
          policy: const SaleConversionPolicy(
            enabled: true,
            pointToMoneyRate: 1,
            minimumPointCents: 100000,
            currency: 'VND',
          ),
          availablePointCents: 200000,
          requestedPointCents: 50000,
        ),
        isNotNull,
      );
    });

    test('keeps 1 point equal 1 VND when conversion is enabled', () {
      const policy = SaleConversionPolicy(
        enabled: true,
        pointToMoneyRate: 1,
        minimumPointCents: 500000,
        currency: 'VND',
      );

      expect(policy.estimateMoneyCents(500000), 500000);
      expect(policy.canRequest(499999), isFalse);
      expect(policy.canRequest(500000), isTrue);
    });
  });
}
