import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/sale_referral/data/datasources/sale_remote_datasource.dart';
import 'package:nano_app/sale_referral/data/repositories/sale_repository_impl.dart';
import 'package:nano_app/sale_referral/domain/entities/sale_models.dart';

void main() {
  group('SaleRepositoryImpl', () {
    test('maps dashboard and conversion policy from RPC payload', () async {
      final repository = SaleRepositoryImpl(
        datasource: _FakeSaleRemoteDatasource(
          dashboard: {
            'direct_customers': 2,
            'successful_payments': 3,
            'approved_point_cents': 30000,
            'available_point_cents': 20000,
            'currency': 'VND',
            'conversion_enabled': true,
            'conversion_rate': 1,
            'conversion_minimum_point_cents': 10000,
          },
        ),
      );

      final dashboard = await repository.fetchDashboard();

      expect(dashboard.directCustomers, 2);
      expect(dashboard.successfulPayments, 3);
      expect(dashboard.approvedPointCents, 30000);
      expect(dashboard.conversionPolicy.enabled, isTrue);
      expect(dashboard.conversionPolicy.minimumPointCents, 10000);
    });

    test('maps list RPCs without leaking raw map shape', () async {
      final repository = SaleRepositoryImpl(
        datasource: _FakeSaleRemoteDatasource(
          customers: [
            {
              'display_name': 'Nguyen Van A',
              'age': 34,
              'phone': '0900000000',
              'health_condition_summary': 'Tang huyet ap',
              'successful_payments': 1,
              'approved_point_cents': 9900,
            },
          ],
          ledger: [
            {
              'id': 'ledger-1',
              'customer_name': 'Nguyen Van A',
              'plan_code': 'plus',
              'payment_amount_cents': 99000,
              'point_amount_cents': 9900,
              'status': 'approved',
            },
          ],
        ),
      );

      final customers = await repository.fetchDirectCustomers();
      final ledger = await repository.fetchPointLedger();

      expect(customers.single.displayName, 'Nguyen Van A');
      expect(customers.single.age, 34);
      expect(customers.single.phone, '0900000000');
      expect(ledger.single.pointAmountCents, 9900);
      expect(ledger.single.status, 'approved');
    });

    test('returns attach result from RPC payload', () async {
      final repository = SaleRepositoryImpl(
        datasource: _FakeSaleRemoteDatasource(
          attachResult: {
            'success': true,
            'message': 'Da gan ma gioi thieu.',
            'referrer_display_name': 'Sale A',
          },
        ),
      );

      final result = await repository.attachReferralCode(
        'NANO-1234',
        deviceHash: 'sale-device-test',
      );

      expect(result.success, isTrue);
      expect(result.referrerDisplayName, 'Sale A');
    });

    test('passes conversion idempotency key and maps request result', () async {
      final datasource = _FakeSaleRemoteDatasource(
        conversionResult: {
          'id': 'conversion-1',
          'requested_point_cents': 10000,
          'money_amount_cents': 10000,
          'currency': 'VND',
          'status': 'requested',
        },
      );
      final repository = SaleRepositoryImpl(datasource: datasource);

      final result = await repository.requestConversion(
        const SaleConversionCommand(
          pointCents: 10000,
          idempotencyKey: 'stable-key',
        ),
      );

      expect(datasource.requestedPointCents, 10000);
      expect(datasource.requestedIdempotencyKey, 'stable-key');
      expect(result.id, 'conversion-1');
      expect(result.requestedPointCents, 10000);
      expect(result.status, 'requested');
    });
  });
}

class _FakeSaleRemoteDatasource implements SaleRemoteDatasource {
  final Object? dashboard;
  final Object? customers;
  final Object? ledger;
  final Object? attachResult;
  final Object? conversionResult;
  int? requestedPointCents;
  String? requestedIdempotencyKey;

  _FakeSaleRemoteDatasource({
    this.dashboard,
    this.customers,
    this.ledger,
    this.attachResult,
    this.conversionResult,
  });

  @override
  Future<Object?> getSaleState() async => const {};

  @override
  Future<Object?> requestSaleParticipation({
    required String termsVersion,
    required String deviceHash,
  }) async {
    return {'sale_status': 'pending', 'terms_version': termsVersion};
  }

  @override
  Future<Object?> attachReferralCode(
    String code, {
    required String deviceHash,
  }) async {
    return attachResult ?? {'success': false, 'message': 'failed'};
  }

  @override
  Future<Object?> getPayoutProfile() async => const {};

  @override
  Future<Object?> upsertPayoutProfile({
    required String citizenId,
    required String bankBin,
    required String bankName,
    required String bankAccountNumber,
    required String bankAccountName,
  }) async {
    return {
      'citizen_id': citizenId,
      'bank_bin': bankBin,
      'bank_name': bankName,
      'bank_account_number': bankAccountNumber,
      'bank_account_name': bankAccountName,
    };
  }

  @override
  Future<Object?> getDashboard() async => dashboard ?? const {};

  @override
  Future<Object?> getDirectCustomers() async => customers ?? const [];

  @override
  Future<Object?> getPointLedger() async => ledger ?? const [];

  @override
  Future<Object?> getConversions() async => const [];

  @override
  Future<Object?> requestConversion({
    required int pointCents,
    required String idempotencyKey,
  }) async {
    requestedPointCents = pointCents;
    requestedIdempotencyKey = idempotencyKey;
    return conversionResult ??
        {
          'id': 'conversion-1',
          'requested_point_cents': pointCents,
          'money_amount_cents': pointCents,
          'status': 'requested',
        };
  }
}
