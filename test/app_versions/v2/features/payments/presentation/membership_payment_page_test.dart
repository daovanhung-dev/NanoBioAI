import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/payments/payments.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
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
    expect(find.text('NB1234567890 NGUYEN AN'), findsOneWidget);
    expect(find.text('1026806174'), findsOneWidget);
    expect(find.text('Lê Phú Thạch'), findsOneWidget);

    final confirmButton = find.text('Đã chuyển khoản').first;
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
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
}

class _FakeMembershipPaymentRepository implements MembershipPaymentRepository {
  MembershipPaymentRequest? currentRequest;
  int confirmCallCount = 0;

  _FakeMembershipPaymentRepository({this.currentRequest});

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
  Future<MembershipPaymentRequest?> fetchCurrentRequest() async {
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
    'bank_code': 'VCB',
    'bank_name': 'Vietcombank',
    'bank_bin': '970436',
    'bank_account_number': '1026806174',
    'bank_account_name': 'LE PHU THACH',
    'bank_account_display_name': 'Lê Phú Thạch',
  });
}
