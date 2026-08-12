import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/payments/payments.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  testWidgets('uses a valid initial plan and falls back to Plus', (
    tester,
  ) async {
    Future<void> pumpWithPlan(String? planCode) {
      return tester.pumpWidget(
        ProviderScope(
          overrides: [
            membershipPaymentCurrentUserIdProvider.overrideWithValue('user-1'),
            membershipPaymentRepositoryProvider.overrideWithValue(
              _FakeMembershipPaymentRepository(),
            ),
            membershipPaymentPayerProfileRepositoryProvider.overrideWithValue(
              const _FakePayerProfileRepository('Nguyễn Thanh An'),
            ),
          ],
          child: MaterialApp(
            home: MembershipPaymentPage(initialPlanCode: planCode),
          ),
        ),
      );
    }

    await pumpWithPlan('family_plus');
    await tester.pumpAndSettle();
    final familyPlanSelector = tester
        .widgetList<DropdownButtonFormField<String>>(
          find.byType(DropdownButtonFormField<String>),
        )
        .first;
    expect(familyPlanSelector.initialValue, 'family_plus');

    await pumpWithPlan('vip');
    await tester.pumpAndSettle();
    final fallbackPlanSelector = tester
        .widgetList<DropdownButtonFormField<String>>(
          find.byType(DropdownButtonFormField<String>),
        )
        .first;
    expect(fallbackPlanSelector.initialValue, 'plus');
  });

  testWidgets('shows server-provided VietQR details and confirms a transfer', (
    tester,
  ) async {
    final repository = _FakeMembershipPaymentRepository(
      currentRequest: _request(status: 'awaiting_transfer'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          membershipPaymentCurrentUserIdProvider.overrideWithValue('user-1'),
          membershipPaymentRepositoryProvider.overrideWithValue(repository),
          membershipPaymentPayerProfileRepositoryProvider.overrideWithValue(
            const _FakePayerProfileRepository('Nguyễn Thanh An'),
          ),
        ],
        child: const MaterialApp(home: MembershipPaymentPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('NB1234567890'), findsWidgets);
    expect(find.text('NB1234567890 NGUYEN AN'), findsNothing);
    expect(find.text('1026806174'), findsOneWidget);
    expect(find.text('Lê Phú Thạch'), findsOneWidget);
    expect(find.text('Nguyễn Thanh An'), findsOneWidget);

    String? copiedMemo;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedMemo = (call.arguments as Map<Object?, Object?>)['text']
              ?.toString();
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    final confirmButton = find.text('Đã chuyển khoản').first;
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sao chép nội dung'));
    await tester.pump();
    expect(copiedMemo, 'NB1234567890');
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();
    expect(find.text('Xác nhận đã chuyển khoản'), findsOneWidget);

    await tester.tap(find.text('Đã chuyển khoản').last);
    await tester.pumpAndSettle();

    expect(repository.confirmCallCount, 1);
    expect(find.textContaining('chờ duyệt'), findsWidgets);
  });

  testWidgets('blocks QR creation when the local payer name is blank', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          membershipPaymentCurrentUserIdProvider.overrideWithValue('user-1'),
          membershipPaymentRepositoryProvider.overrideWithValue(
            _FakeMembershipPaymentRepository(),
          ),
          membershipPaymentPayerProfileRepositoryProvider.overrideWithValue(
            const _FakePayerProfileRepository(null),
          ),
        ],
        child: const MaterialApp(home: MembershipPaymentPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Bạn cần cập nhật họ và tên trong hồ sơ trước khi tạo mã thanh toán.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Tạo mã thanh toán'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsNothing);
  });

  testWidgets('allows cancellation only before transfer confirmation', (
    tester,
  ) async {
    final repository = _FakeMembershipPaymentRepository(
      currentRequest: _request(status: 'awaiting_transfer'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          membershipPaymentCurrentUserIdProvider.overrideWithValue('user-1'),
          membershipPaymentRepositoryProvider.overrideWithValue(repository),
          membershipPaymentPayerProfileRepositoryProvider.overrideWithValue(
            const _FakePayerProfileRepository('Nguyễn Thanh An'),
          ),
        ],
        child: const MaterialApp(home: MembershipPaymentPage()),
      ),
    );
    await tester.pumpAndSettle();

    final cancelButton = find.text('Hủy yêu cầu').first;
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.tap(cancelButton);
    await tester.pumpAndSettle();
    expect(find.text('Hủy yêu cầu thanh toán'), findsOneWidget);

    await tester.tap(find.text('Hủy yêu cầu').last);
    await tester.pumpAndSettle();

    expect(repository.cancelCallCount, 1);
    expect(repository.currentRequest?.normalizedStatus, 'cancelled');
    expect(find.textContaining('đã được hủy'), findsWidgets);
  });

  testWidgets('refreshes pending review on app resume and every 30 seconds', (
    tester,
  ) async {
    final repository = _FakeMembershipPaymentRepository(
      currentRequest: _request(status: 'pending_review'),
      fetchResponses: [
        _request(status: 'pending_review'),
        _request(status: 'pending_review'),
        _request(status: 'succeeded'),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          membershipPaymentCurrentUserIdProvider.overrideWithValue('user-1'),
          membershipPaymentRepositoryProvider.overrideWithValue(repository),
          membershipPaymentPayerProfileRepositoryProvider.overrideWithValue(
            const _FakePayerProfileRepository('Nguyễn Thanh An'),
          ),
        ],
        child: const MaterialApp(home: MembershipPaymentPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.fetchCallCount, 1);
    expect(find.text('Hủy yêu cầu'), findsNothing);
    expect(find.byType(QrImageView), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(repository.fetchCallCount, 2);

    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(repository.fetchCallCount, 3);
    expect(find.textContaining('đã được duyệt'), findsWidgets);
  });
}

class _FakeMembershipPaymentRepository implements MembershipPaymentRepository {
  MembershipPaymentRequest? currentRequest;
  final List<MembershipPaymentRequest?>? fetchResponses;
  int confirmCallCount = 0;
  int cancelCallCount = 0;
  int fetchCallCount = 0;
  int _fetchResponseIndex = 0;

  _FakeMembershipPaymentRepository({this.currentRequest, this.fetchResponses});

  @override
  Future<MembershipPaymentRequest> createRequest(
    CreateMembershipPaymentRequestCommand command,
  ) async {
    return currentRequest ??= _request(
      status: 'awaiting_transfer',
      planCode: command.planCode,
      billingCycle: command.billingCycle,
    );
  }

  @override
  Future<MembershipPaymentRequest> confirmTransfer(
    String paymentEventId,
  ) async {
    confirmCallCount++;
    return currentRequest = _request(
      status: 'pending_review',
      id: paymentEventId,
    );
  }

  @override
  Future<MembershipPaymentRequest> cancelRequest(String paymentEventId) async {
    cancelCallCount++;
    return currentRequest = _request(status: 'cancelled', id: paymentEventId);
  }

  @override
  Future<MembershipPaymentRequest?> fetchCurrentRequest() async {
    fetchCallCount++;
    final responses = fetchResponses;
    if (responses != null && responses.isNotEmpty) {
      final index = _fetchResponseIndex;
      _fetchResponseIndex++;
      return currentRequest =
          responses[index < responses.length ? index : responses.length - 1];
    }
    return currentRequest;
  }
}

class _FakePayerProfileRepository
    implements MembershipPaymentPayerProfileRepository {
  final String? fullName;

  const _FakePayerProfileRepository(this.fullName);

  @override
  Future<String?> readFullName(String userId) async => fullName;
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
    'payer_full_name': 'Nguyễn Thanh An',
    'bank_code': 'VCB',
    'bank_name': 'Vietcombank',
    'bank_bin': '970436',
    'bank_account_number': '1026806174',
    'bank_account_name': 'LE PHU THACH',
    'bank_account_display_name': 'Lê Phú Thạch',
  });
}
