import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/sale_referral/domain/entities/sale_models.dart';
import 'package:nano_app/sale_referral/domain/repositories/sale_repository.dart';
import 'package:nano_app/sale_referral/presentation/pages/sale_shell_page.dart';
import 'package:nano_app/sale_referral/providers/sale_providers.dart';

void main() {
  testWidgets('shows pending Sale state before Admin approval', (tester) async {
    await _pumpSaleShell(
      tester,
      _FakeSaleRepository(state: const SaleState(status: SaleStatus.pending)),
    );

    expect(find.text('Hồ sơ đang chờ duyệt'), findsOneWidget);
  });

  testWidgets('shows suspended and closed Sale support states', (tester) async {
    await _pumpSaleShell(
      tester,
      _FakeSaleRepository(state: const SaleState(status: SaleStatus.suspended)),
    );

    expect(find.text('Tài khoản cộng tác viên đang tạm dừng'), findsOneWidget);

    await _pumpSaleShell(
      tester,
      _FakeSaleRepository(state: const SaleState(status: SaleStatus.closed)),
    );

    expect(find.text('Tài khoản cộng tác viên đã đóng'), findsOneWidget);
  });

  testWidgets('shows active dashboard and disabled conversion state', (
    tester,
  ) async {
    await _pumpSaleShell(
      tester,
      _FakeSaleRepository(
        state: const SaleState(
          status: SaleStatus.active,
          referralCode: 'NANO-1234',
          payoutProfileComplete: true,
        ),
      ),
    );

    expect(find.text('Tổng quan cộng tác viên'), findsOneWidget);
    expect(find.text('Mã giới thiệu: NANO-1234'), findsOneWidget);
    expect(find.text('Quy đổi điểm chưa mở'), findsOneWidget);

    await tester.tap(find.text('Công cụ'));
    await tester.pump();

    expect(find.text('Ước tính điểm Sale'), findsNothing);
    expect(
      find.text(
        'Quy đổi điểm cộng tác viên chưa được quản trị viên mở cấu hình.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('blocks active Sale dashboard until payout profile is complete', (
    tester,
  ) async {
    await _pumpSaleShell(
      tester,
      _FakeSaleRepository(
        state: const SaleState(
          status: SaleStatus.active,
          referralCode: 'NANO-1234',
        ),
      ),
    );

    expect(find.text('Cập nhật CCCD và ngân hàng'), findsOneWidget);
    expect(find.text('Tổng quan cộng tác viên'), findsNothing);
  });

  testWidgets('does not show health condition summary for direct customers', (
    tester,
  ) async {
    await _pumpSaleShell(
      tester,
      _FakeSaleRepository(
        state: const SaleState(
          status: SaleStatus.active,
          referralCode: 'NANO-1234',
          payoutProfileComplete: true,
        ),
      ),
    );

    await tester.tap(find.text('Khách hàng'));
    await tester.pump();

    expect(find.textContaining('Sức khỏe'), findsNothing);
    expect(find.textContaining('SĐT:'), findsOneWidget);
  });

  testWidgets('submits enabled conversion with trusted RPC values', (
    tester,
  ) async {
    final repository = _FakeSaleRepository(
      state: const SaleState(
        status: SaleStatus.active,
        referralCode: 'NANO-1234',
        payoutProfileComplete: true,
      ),
      dashboard: _enabledDashboard(),
    );
    await _pumpSaleShell(tester, repository);

    await tester.tap(find.text('Công cụ'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '10000');
    await tester.pump();
    await tester.tap(find.text('Gửi yêu cầu quy đổi'));
    await tester.pump();

    expect(repository.commands, hasLength(1));
    expect(repository.commands.single.pointCents, 10000);
    expect(
      repository.commands.single.idempotencyKey,
      startsWith('sale-conversion-NANO-1234-10000-'),
    );
    expect(
      find.text('Đã gửi yêu cầu quy đổi điểm cộng tác viên.'),
      findsOneWidget,
    );
  });

  testWidgets('blocks duplicate conversion submit while request is in flight', (
    tester,
  ) async {
    final blocker = Completer<void>();
    final repository = _FakeSaleRepository(
      state: const SaleState(
        status: SaleStatus.active,
        referralCode: 'NANO-1234',
        payoutProfileComplete: true,
      ),
      dashboard: _enabledDashboard(),
      requestBlocker: blocker,
    );
    await _pumpSaleShell(tester, repository);

    await tester.tap(find.text('Công cụ'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '10000');
    await tester.pump();
    await tester.tap(find.text('Gửi yêu cầu quy đổi'));
    await tester.pump();
    await tester.tap(find.text('Gửi yêu cầu quy đổi'));
    await tester.pump();

    expect(repository.commands, hasLength(1));

    blocker.complete();
    await tester.pump();
  });

  testWidgets('retries failed conversion with same idempotency key', (
    tester,
  ) async {
    final repository = _FakeSaleRepository(
      state: const SaleState(
        status: SaleStatus.active,
        referralCode: 'NANO-1234',
        payoutProfileComplete: true,
      ),
      dashboard: _enabledDashboard(),
      failFirstConversion: true,
    );
    await _pumpSaleShell(tester, repository);

    await tester.tap(find.text('Công cụ'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '10000');
    await tester.pump();
    await tester.tap(find.text('Gửi yêu cầu quy đổi'));
    await tester.pump();

    expect(
      find.text('Chưa gửi được yêu cầu quy đổi. Bạn thử lại sau.'),
      findsOneWidget,
    );
    final failedKey = repository.commands.single.idempotencyKey;

    await tester.tap(find.text('Gửi yêu cầu quy đổi'));
    await tester.pump();

    expect(repository.commands, hasLength(2));
    expect(repository.commands.last.idempotencyKey, failedKey);
  });
}

Future<void> _pumpSaleShell(
  WidgetTester tester,
  _FakeSaleRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [saleRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: SaleShellPage()),
    ),
  );
  await tester.pump();
  await tester.pump();
}

SaleDashboard _enabledDashboard() {
  return const SaleDashboard(
    directCustomers: 2,
    successfulPayments: 3,
    pendingPointCents: 0,
    approvedPointCents: 30000,
    paidPointCents: 0,
    convertedPointCents: 0,
    availablePointCents: 30000,
    currency: 'VND',
    conversionPolicy: SaleConversionPolicy(
      enabled: true,
      pointToMoneyRate: 1,
      minimumPointCents: 10000,
      currency: 'VND',
    ),
  );
}

class _FakeSaleRepository implements SaleRepository {
  final SaleState state;
  final SaleDashboard dashboard;
  final Completer<void>? requestBlocker;
  final bool failFirstConversion;
  final commands = <SaleConversionCommand>[];

  _FakeSaleRepository({
    required this.state,
    this.requestBlocker,
    this.failFirstConversion = false,
    SaleDashboard? dashboard,
  }) : dashboard =
           dashboard ??
           const SaleDashboard(
             directCustomers: 2,
             successfulPayments: 3,
             pendingPointCents: 0,
             approvedPointCents: 30000,
             paidPointCents: 0,
             convertedPointCents: 0,
             availablePointCents: 30000,
             currency: 'VND',
             conversionPolicy: SaleConversionPolicy.disabled(),
           );

  @override
  Future<SaleState> fetchSaleState() async => state;

  @override
  Future<SaleState> requestSaleParticipation({
    required String termsVersion,
    required String deviceHash,
  }) async {
    return const SaleState(status: SaleStatus.pending);
  }

  @override
  Future<SaleReferralAttachment> attachReferralCode(
    String code, {
    required String deviceHash,
  }) async {
    return const SaleReferralAttachment(success: true, message: 'ok');
  }

  @override
  Future<SalePayoutProfile?> fetchPayoutProfile() async {
    return null;
  }

  @override
  Future<SalePayoutProfile> upsertPayoutProfile(
    SalePayoutProfileCommand command,
  ) async {
    return SalePayoutProfile(
      citizenId: command.citizenId,
      bankBin: command.bankBin,
      bankName: command.bankName,
      bankAccountNumber: command.bankAccountNumber,
      bankAccountName: command.bankAccountName,
    );
  }

  @override
  Future<SaleDashboard> fetchDashboard() async {
    return dashboard;
  }

  @override
  Future<List<SaleDirectCustomer>> fetchDirectCustomers() async {
    return const [
      SaleDirectCustomer(
        displayName: 'Nguyen Van A',
        successfulPayments: 1,
        approvedPointCents: 9900,
        currency: 'VND',
      ),
    ];
  }

  @override
  Future<List<SalePointLedgerEntry>> fetchPointLedger() async {
    return const [
      SalePointLedgerEntry(
        id: 'ledger-1',
        customerName: 'Nguyen Van A',
        planCode: 'plus',
        paymentAmountCents: 99000,
        pointAmountCents: 9900,
        currency: 'VND',
        status: 'approved',
      ),
    ];
  }

  @override
  Future<List<SaleConversionRequest>> fetchConversionRequests() async {
    return const [];
  }

  @override
  Future<SaleConversionRequest> requestConversion(
    SaleConversionCommand command,
  ) async {
    commands.add(command);
    if (failFirstConversion && commands.length == 1) {
      throw StateError('network');
    }
    await requestBlocker?.future;
    return SaleConversionRequest(
      id: 'conversion-1',
      requestedPointCents: command.pointCents,
      moneyAmountCents: command.pointCents,
      currency: 'VND',
      status: 'requested',
    );
  }
}
