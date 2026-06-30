import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/payments/payments.dart';

void main() {
  group('CreateMembershipPaymentRequest', () {
    test(
      'creates pending request through repository without granting access',
      () async {
        final repository = _FakeMembershipPaymentRepository();
        final useCase = CreateMembershipPaymentRequest(repository: repository);

        final result = await useCase.execute(
          const CreateMembershipPaymentRequestCommand(
            planCode: 'family_plus',
            billingCycle: 'monthly',
            idempotencyKey: 'key-1',
          ),
        );

        expect(repository.lastCommand?.planCode, 'family_plus');
        expect(repository.lastCommand?.billingCycle, 'monthly');
        expect(repository.lastCommand?.idempotencyKey, 'key-1');
        expect(result.status, 'pending');
      },
    );

    test('rejects invalid plan, cycle or idempotency key', () {
      final useCase = CreateMembershipPaymentRequest(
        repository: _FakeMembershipPaymentRepository(),
      );

      expect(
        () => useCase.execute(
          const CreateMembershipPaymentRequestCommand(
            planCode: 'free',
            billingCycle: 'monthly',
            idempotencyKey: 'key-1',
          ),
        ),
        throwsA(isA<MembershipPaymentException>()),
      );
    });
  });
}

class _FakeMembershipPaymentRepository implements MembershipPaymentRepository {
  CreateMembershipPaymentRequestCommand? lastCommand;

  @override
  Future<MembershipPaymentRequest> createRequest(
    CreateMembershipPaymentRequestCommand command,
  ) async {
    lastCommand = command;
    return MembershipPaymentRequest.fromMap({
      'payment_event_id': 'payment-1',
      'plan_code': command.planCode,
      'billing_cycle': command.billingCycle,
      'status': 'pending',
      'amount_cents': 399000,
      'currency': 'VND',
    });
  }
}
