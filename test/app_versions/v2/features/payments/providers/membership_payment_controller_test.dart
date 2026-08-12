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
      final projectionRefreshes = _ProjectionRefreshCounter();
      final container = _container(
        repository: repository,
        accessRefreshes: accessRefreshes,
        projectionRefreshes: projectionRefreshes,
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
      expect(projectionRefreshes.count, 0);
    },
  );

  test(
    'refreshes trusted access and local projection only after succeeded',
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
      final projectionRefreshes = _ProjectionRefreshCounter();
      final container = _container(
        repository: repository,
        accessRefreshes: accessRefreshes,
        projectionRefreshes: projectionRefreshes,
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
      expect(projectionRefreshes.count, 0);

      await container
          .read(membershipPaymentControllerProvider.notifier)
          .refresh();
      await container.read(effectiveAccessProvider.future);
      await _flush();

      expect(accessRefreshes.count, 2);
      expect(projectionRefreshes.count, 1);
    },
  );

  test(
    'does not repeat access/projection refresh for the same succeeded payment',
    () async {
      final repository = _SequencePaymentRepository(
        currentResponses: [
          _request(status: 'succeeded'),
          _request(status: 'succeeded'),
        ],
        confirmResponse: _request(status: 'pending_review'),
      );
      final accessRefreshes = _AccessRefreshCounter();
      final projectionRefreshes = _ProjectionRefreshCounter();
      final container = _container(
        repository: repository,
        accessRefreshes: accessRefreshes,
        projectionRefreshes: projectionRefreshes,
      );
      addTearDown(container.dispose);

      final subscription = container.listen(effectiveAccessProvider, (_, _) {});
      addTearDown(subscription.close);
      await container.read(effectiveAccessProvider.future);
      await container.read(membershipPaymentControllerProvider.future);
      await _flush();
      final refreshCountAfterLoad = accessRefreshes.count;
      expect(projectionRefreshes.count, 1);

      await container
          .read(membershipPaymentControllerProvider.notifier)
          .refresh();
      await _flush();

      expect(accessRefreshes.count, refreshCountAfterLoad);
      expect(projectionRefreshes.count, 1);
    },
  );

  test('cancels an awaiting transfer without refreshing paid access', () async {
    final repository = _SequencePaymentRepository(
      currentResponses: [_request(status: 'awaiting_transfer')],
      confirmResponse: _request(status: 'pending_review'),
      cancelResponse: _request(status: 'cancelled'),
    );
    final accessRefreshes = _AccessRefreshCounter();
    final projectionRefreshes = _ProjectionRefreshCounter();
    final container = _container(
      repository: repository,
      accessRefreshes: accessRefreshes,
      projectionRefreshes: projectionRefreshes,
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
    expect(projectionRefreshes.count, 0);
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
      final projectionRefreshes = _ProjectionRefreshCounter();
      final container = _container(
        repository: repository,
        accessRefreshes: accessRefreshes,
        projectionRefreshes: projectionRefreshes,
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
      expect(projectionRefreshes.count, 0);
    },
  );
}

ProviderContainer _container({
  required MembershipPaymentRepository repository,
  required _AccessRefreshCounter accessRefreshes,
  required _ProjectionRefreshCounter projectionRefreshes,
}) {
  return ProviderContainer(
    overrides: [
      membershipPaymentCurrentUserIdProvider.overrideWithValue('user-1'),
      membershipPaymentRepositoryProvider.overrideWithValue(repository),
      membershipPaymentPayerProfileRepositoryProvider.overrideWithValue(
        const _PayerProfileRepository(),
      ),
      membershipPaymentApprovedProjectionRefreshProvider.overrideWithValue(
        () async {
          projectionRefreshes.count++;
        },
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

class _ProjectionRefreshCounter {
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
    'transfer_reference': 'NB12AB34CD56EF',
    'transfer_memo': 'NB12AB34CD56EF',
    'bank_bin': '970436',
    'bank_account_number': '1026806174',
    'bank_account_name': 'LE PHU THACH',
  });
}
