import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/providers/membership_entitlement_providers.dart';
import 'package:nano_app/app_versions/v2/features/payments/payments.dart';

void main() {
  test(
    'confirming a transfer moves it to pending review without refreshing access',
    () async {
      final repository = _SequencePaymentRepository(
        currentResponses: [_request(status: 'awaiting_transfer')],
        confirmResponse: _request(status: 'pending_review'),
      );
      final accessRefreshes = _AccessRefreshCounter();
      final container = _container(
        repository: repository,
        accessRefreshes: accessRefreshes,
      );
      addTearDown(container.dispose);

      final subscription = container.listen(effectiveAccessProvider, (_, _) {});
      addTearDown(subscription.close);
      await container.read(effectiveAccessProvider.future);
      await container.read(membershipPaymentControllerProvider.future);

      final request = await container
          .read(membershipPaymentControllerProvider.notifier)
          .confirmTransfer();
      await _flush();

      expect(request.isPendingReview, isTrue);
      expect(repository.confirmCallCount, 1);
      expect(accessRefreshes.count, 1);
    },
  );

  test(
    'refreshes effective access only after the backend returns succeeded',
    () async {
      final repository = _SequencePaymentRepository(
        currentResponses: [
          _request(status: 'awaiting_transfer'),
          _request(status: 'pending_review'),
          _request(status: 'succeeded'),
        ],
        confirmResponse: _request(status: 'pending_review'),
      );
      final accessRefreshes = _AccessRefreshCounter();
      final container = _container(
        repository: repository,
        accessRefreshes: accessRefreshes,
      );
      addTearDown(container.dispose);

      final subscription = container.listen(effectiveAccessProvider, (_, _) {});
      addTearDown(subscription.close);
      await container.read(effectiveAccessProvider.future);
      await container.read(membershipPaymentControllerProvider.future);
      expect(accessRefreshes.count, 1);

      await container
          .read(membershipPaymentControllerProvider.notifier)
          .refresh();
      await _flush();
      expect(accessRefreshes.count, 1);

      await container
          .read(membershipPaymentControllerProvider.notifier)
          .refresh();
      await container.read(effectiveAccessProvider.future);

      expect(accessRefreshes.count, 2);
    },
  );

  test('cancels an awaiting transfer without refreshing paid access', () async {
    final repository = _SequencePaymentRepository(
      currentResponses: [_request(status: 'awaiting_transfer')],
      confirmResponse: _request(status: 'pending_review'),
      cancelResponse: _request(status: 'cancelled'),
    );
    final accessRefreshes = _AccessRefreshCounter();
    final container = _container(
      repository: repository,
      accessRefreshes: accessRefreshes,
    );
    addTearDown(container.dispose);

    final subscription = container.listen(effectiveAccessProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(effectiveAccessProvider.future);
    await container.read(membershipPaymentControllerProvider.future);

    final request = await container
        .read(membershipPaymentControllerProvider.notifier)
        .cancelRequest();
    await _flush();

    expect(request.normalizedStatus, 'cancelled');
    expect(request.canCancel, isFalse);
    expect(repository.cancelCallCount, 1);
    expect(accessRefreshes.count, 1);
  });

  test(
    'opens the server-reported active request after a create race',
    () async {
      final existingRequest = _request(
        status: 'awaiting_transfer',
        id: 'existing-payment',
      );
      final repository = _SequencePaymentRepository(
        currentResponses: [null, existingRequest],
        confirmResponse: _request(status: 'pending_review'),
        createError: StateError('MEMBERSHIP_PAYMENT_REQUEST_ALREADY_OPEN'),
      );
      final accessRefreshes = _AccessRefreshCounter();
      final container = _container(
        repository: repository,
        accessRefreshes: accessRefreshes,
      );
      addTearDown(container.dispose);

      await container.read(membershipPaymentControllerProvider.future);
      final request = await container
          .read(membershipPaymentControllerProvider.notifier)
          .createRequest(planCode: 'plus', billingCycle: 'monthly');

      expect(repository.createCallCount, 1);
      expect(repository.fetchCurrentRequestCallCount, 2);
      expect(request.id, 'existing-payment');
      expect(
        container.read(membershipPaymentControllerProvider).value?.request?.id,
        'existing-payment',
      );
    },
  );
}

ProviderContainer _container({
  required MembershipPaymentRepository repository,
  required _AccessRefreshCounter accessRefreshes,
}) {
  return ProviderContainer(
    overrides: [
      membershipPaymentCurrentUserIdProvider.overrideWithValue('user-1'),
      membershipPaymentRepositoryProvider.overrideWithValue(repository),
      membershipPaymentPayerProfileRepositoryProvider.overrideWithValue(
        const _PayerProfileRepository(),
      ),
      effectiveAccessProvider.overrideWith((ref) async {
        accessRefreshes.count++;
        return null;
      }),
    ],
  );
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

class _AccessRefreshCounter {
  int count = 0;
}

class _PayerProfileRepository
    implements MembershipPaymentPayerProfileRepository {
  const _PayerProfileRepository();

  @override
  Future<String?> readFullName(String userId) async => 'Nguyễn Thanh An';
}

class _SequencePaymentRepository implements MembershipPaymentRepository {
  final List<MembershipPaymentRequest?> currentResponses;
  final MembershipPaymentRequest confirmResponse;
  final MembershipPaymentRequest? cancelResponse;
  final Object? createError;
  int _currentReadIndex = 0;
  int confirmCallCount = 0;
  int cancelCallCount = 0;
  int createCallCount = 0;
  int fetchCurrentRequestCallCount = 0;

  _SequencePaymentRepository({
    required this.currentResponses,
    required this.confirmResponse,
    this.cancelResponse,
    this.createError,
  });

  @override
  Future<MembershipPaymentRequest> confirmTransfer(
    String paymentEventId,
  ) async {
    confirmCallCount++;
    return confirmResponse;
  }

  @override
  Future<MembershipPaymentRequest> cancelRequest(String paymentEventId) async {
    cancelCallCount++;
    return cancelResponse ?? _request(status: 'cancelled', id: paymentEventId);
  }

  @override
  Future<MembershipPaymentRequest> createRequest(
    CreateMembershipPaymentRequestCommand command,
  ) async {
    createCallCount++;
    if (createError != null) throw createError!;
    return _request(
      status: 'awaiting_transfer',
      id: 'created-payment',
      planCode: command.planCode,
      billingCycle: command.billingCycle,
    );
  }

  @override
  Future<MembershipPaymentRequest?> fetchCurrentRequest() async {
    fetchCurrentRequestCallCount++;
    final index = _currentReadIndex;
    _currentReadIndex++;
    return currentResponses[index < currentResponses.length
        ? index
        : currentResponses.length - 1];
  }
}

MembershipPaymentRequest _request({
  required String status,
  String id = 'payment-1',
  String planCode = 'plus',
  String billingCycle = 'monthly',
}) {
  return MembershipPaymentRequest.fromMap({
    'payment_event_id': id,
    'plan_code': planCode,
    'billing_cycle': billingCycle,
    'status': status,
    'amount_cents': 399000,
    'currency': 'VND',
    'transfer_reference': 'NB1234567890',
    'transfer_memo': 'NB1234567890 NGUYEN AN',
    'bank_bin': '970436',
    'bank_account_number': '1026806174',
    'bank_account_name': 'LE PHU THACH',
  });
}
