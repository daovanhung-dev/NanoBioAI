import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/sale_referral/domain/entities/sale_models.dart';
import 'package:nano_app/sale_referral/domain/repositories/sale_repository.dart';
import 'package:nano_app/sale_referral/presentation/pages/sale_shell_page.dart';
import 'package:nano_app/sale_referral/providers/sale_providers.dart';

void main() {
  testWidgets('shows pending Sale state before Admin approval', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          saleRepositoryProvider.overrideWithValue(
            const _FakeSaleRepository(
              state: SaleState(status: SaleStatus.pending),
            ),
          ),
        ],
        child: const MaterialApp(home: SaleShellPage()),
      ),
    );

    await tester.pump();

    expect(find.text('Ho so Sale dang cho Admin duyet'), findsOneWidget);
  });

  testWidgets('shows active dashboard and disabled conversion state', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          saleRepositoryProvider.overrideWithValue(
            const _FakeSaleRepository(
              state: SaleState(
                status: SaleStatus.active,
                referralCode: 'NANO-1234',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: SaleShellPage()),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('Tong quan Sale'), findsOneWidget);
    expect(find.text('Ma gioi thieu: NANO-1234'), findsOneWidget);
    expect(find.text('Quy doi diem chua mo'), findsOneWidget);
  });
}

class _FakeSaleRepository implements SaleRepository {
  final SaleState state;

  const _FakeSaleRepository({required this.state});

  @override
  Future<SaleState> fetchSaleState() async => state;

  @override
  Future<SaleState> requestSaleParticipation({
    required String termsVersion,
  }) async {
    return const SaleState(status: SaleStatus.pending);
  }

  @override
  Future<SaleReferralAttachment> attachReferralCode(String code) async {
    return const SaleReferralAttachment(success: true, message: 'ok');
  }

  @override
  Future<SaleDashboard> fetchDashboard() async {
    return const SaleDashboard(
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
    return SaleConversionRequest(
      id: 'conversion-1',
      requestedPointCents: command.pointCents,
      moneyAmountCents: command.pointCents,
      currency: 'VND',
      status: 'requested',
    );
  }
}
