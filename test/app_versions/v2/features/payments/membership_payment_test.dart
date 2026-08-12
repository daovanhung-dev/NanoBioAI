import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/payments/payments.dart';

void main() {
  group('CreateMembershipPaymentRequest', () {
    test('sends the local payer name and does not grant access', () async {
      final repository = _FakeMembershipPaymentRepository();
      final useCase = CreateMembershipPaymentRequest(repository: repository);

      final result = await useCase.execute(
        const CreateMembershipPaymentRequestCommand(
          planCode: 'family_plus',
          billingCycle: 'monthly',
          idempotencyKey: 'key-1',
          payerFullName: 'Nguyễn An',
        ),
      );

      expect(repository.lastCommand?.planCode, 'family_plus');
      expect(repository.lastCommand?.billingCycle, 'monthly');
      expect(repository.lastCommand?.idempotencyKey, 'key-1');
      expect(repository.lastCommand?.payerFullName, 'Nguyễn An');
      expect(result.status, 'awaiting_transfer');
      expect(result.isSucceeded, isFalse);
    });

    test('reuses the same request for a retry with the same key', () async {
      final repository = _FakeMembershipPaymentRepository();
      final useCase = CreateMembershipPaymentRequest(repository: repository);
      const command = CreateMembershipPaymentRequestCommand(
        planCode: 'plus',
        billingCycle: 'yearly',
        idempotencyKey: 'retry-key',
        payerFullName: 'Lê Minh',
      );

      final first = await useCase.execute(command);
      final second = await useCase.execute(command);

      expect(repository.createCallCount, 2);
      expect(second.id, first.id);
      expect(second.transferReference, first.transferReference);
    });

    test('rejects invalid plan, cycle, idempotency key or payer name', () {
      final useCase = CreateMembershipPaymentRequest(
        repository: _FakeMembershipPaymentRepository(),
      );

      expect(
        () => useCase.execute(
          const CreateMembershipPaymentRequestCommand(
            planCode: 'free',
            billingCycle: 'monthly',
            idempotencyKey: 'key-1',
            payerFullName: 'Nguyễn An',
          ),
        ),
        throwsA(isA<MembershipPaymentException>()),
      );
      expect(
        () => useCase.execute(
          const CreateMembershipPaymentRequestCommand(
            planCode: 'plus',
            billingCycle: 'monthly',
            idempotencyKey: 'key-1',
            payerFullName: '  ',
          ),
        ),
        throwsA(
          isA<MembershipPaymentException>().having(
            (error) => error.code,
            'code',
            'MISSING_PAYER_NAME',
          ),
        ),
      );
    });
  });

  test('maps server-owned VietQR and review fields safely', () {
    final request = MembershipPaymentRequest.fromMap({
      'payment_event_id': 'payment-1',
      'plan_code': 'plus',
      'billing_cycle': 'monthly',
      'status': 'pending_review',
      'amount_cents': 399000,
      'currency': 'VND',
      'transfer_reference': 'NB12AB34CD56EF',
      'transfer_memo': 'NB12AB34CD56EF',
      'payer_full_name': 'Nguyễn Thanh An',
      'bank_code': 'VCB',
      'bank_name': 'Vietcombank',
      'bank_bin': '970436',
      'bank_account_number': '1026806174',
      'bank_account_name': 'LE PHU THACH',
      'bank_account_display_name': 'Lê Phú Thạch',
      'transfer_confirmed_at': '2026-07-31T10:00:00Z',
      'review_reason': 'Đã nhận đủ thông tin.',
    });

    expect(request.transferReference, 'NB12AB34CD56EF');
    expect(request.transferMemo, 'NB12AB34CD56EF');
    expect(request.transferMemoForPayment, 'NB12AB34CD56EF');
    expect(request.payerFullName, 'Nguyễn Thanh An');
    expect(request.bankName, 'Vietcombank');
    expect(request.bankAccountDisplayName, 'Lê Phú Thạch');
    expect(request.transferConfirmedAt, DateTime.parse('2026-07-31T10:00:00Z'));
    expect(request.isPendingReview, isTrue);
    expect(request.hasTransferDetails, isTrue);
    expect(request.isSucceeded, isFalse);
  });

  test('only succeeded is treated as a paid-access refresh signal', () {
    const approved = MembershipPaymentRequest(
      id: 'payment-1',
      planCode: 'plus',
      billingCycle: 'monthly',
      status: 'approved',
      amountCents: 399000,
      currency: 'VND',
    );
    const succeeded = MembershipPaymentRequest(
      id: 'payment-2',
      planCode: 'plus',
      billingCycle: 'monthly',
      status: 'succeeded',
      amountCents: 399000,
      currency: 'VND',
    );

    expect(approved.isSucceeded, isFalse);
    expect(succeeded.isSucceeded, isTrue);
  });

  test('uses only the canonical NB reference for VietQR content', () {
    final request = MembershipPaymentRequest.fromMap({
      'payment_event_id': 'payment-1',
      'plan_code': 'plus',
      'billing_cycle': 'monthly',
      'status': 'awaiting_transfer',
      'amount_cents': 399000,
      'currency': 'VND',
      'transfer_reference': 'nb12ab34cd56ef',
      'transfer_memo': 'NB12AB34CD56EF NGUYEN THANH AN',
      'bank_bin': '970436',
      'bank_account_number': '1026806174',
      'bank_account_name': 'LE PHU THACH',
    });

    expect(request.transferMemoForPayment, 'NB12AB34CD56EF');
    expect(request.hasTransferDetails, isTrue);
  });

  test('fails closed when the server reference is not exact NB plus 12 hex', () {
    for (final invalidReference in [
      'NBABC',
      'NB12AB34CD56E',
      'NB12AB34CD56EF0',
      'NB12AB34CD56EG',
      'NGUYEN AN PLUS',
    ]) {
      final request = MembershipPaymentRequest.fromMap({
        'payment_event_id': 'payment-1',
        'plan_code': 'plus',
        'billing_cycle': 'monthly',
        'status': 'awaiting_transfer',
        'amount_cents': 399000,
        'currency': 'VND',
        'transfer_reference': invalidReference,
        'transfer_memo': 'NB12AB34CD56EF',
        'bank_bin': '970436',
        'bank_account_number': '1026806174',
        'bank_account_name': 'LE PHU THACH',
      });

      expect(
        request.transferMemoForPayment,
        isNull,
        reason: invalidReference,
      );
      expect(request.hasTransferDetails, isFalse, reason: invalidReference);
    }
  });

  test('normalizes an invalid payment plan selection to Plus', () {
    expect(normalizeMembershipPaymentPlanCode('family_plus'), 'family_plus');
    expect(normalizeMembershipPaymentPlanCode('PLUS'), 'plus');
    expect(normalizeMembershipPaymentPlanCode('vip'), 'plus');
    expect(normalizeMembershipPaymentPlanCode(null), 'plus');
  });

  test(
    'cancels through the payment repository only with a payment id',
    () async {
      final repository = _FakeMembershipPaymentRepository();
      final useCase = CancelMembershipPaymentRequest(repository: repository);

      final result = await useCase.execute('payment-1');

      expect(result.id, 'payment-1');
      expect(result.normalizedStatus, 'cancelled');
      expect(
        () => useCase.execute('  '),
        throwsA(
          isA<MembershipPaymentException>().having(
            (error) => error.code,
            'code',
            'INVALID_CANCELLATION',
          ),
        ),
      );
    },
  );
}

class _FakeMembershipPaymentRepository implements MembershipPaymentRepository {
  final Map<String, MembershipPaymentRequest> _requestsByKey = {};
  CreateMembershipPaymentRequestCommand? lastCommand;
  int createCallCount = 0;

  @override
  Future<MembershipPaymentRequest> createRequest(
    CreateMembershipPaymentRequestCommand command,
  ) async {
    createCallCount++;
    lastCommand = command;
    return _requestsByKey.putIfAbsent(
      command.idempotencyKey,
      () => MembershipPaymentRequest.fromMap({
        'payment_event_id': 'payment-${_requestsByKey.length + 1}',
        'plan_code': command.planCode,
        'billing_cycle': command.billingCycle,
        'status': 'awaiting_transfer',
        'amount_cents': 399000,
        'currency': 'VND',
        'transfer_reference': 'NB12AB34CD56EF',
        'transfer_memo': 'NB12AB34CD56EF NGUYEN AN',
        'bank_bin': '970436',
        'bank_account_number': '1026806174',
        'bank_account_name': 'LE PHU THACH',
      }),
    );
  }

  @override
  Future<MembershipPaymentRequest> confirmTransfer(
    String paymentEventId,
  ) async {
    return MembershipPaymentRequest.fromMap({
      'payment_event_id': paymentEventId,
      'plan_code': 'plus',
      'billing_cycle': 'monthly',
      'status': 'pending_review',
      'amount_cents': 399000,
      'currency': 'VND',
    });
  }

  @override
  Future<MembershipPaymentRequest> cancelRequest(String paymentEventId) async {
    return MembershipPaymentRequest.fromMap({
      'payment_event_id': paymentEventId,
      'plan_code': 'plus',
      'billing_cycle': 'monthly',
      'status': 'cancelled',
      'amount_cents': 399000,
      'currency': 'VND',
    });
  }

  @override
  Future<MembershipPaymentRequest?> fetchCurrentRequest() async => null;
}
