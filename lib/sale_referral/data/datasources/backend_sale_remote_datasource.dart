import 'package:nano_app/core/network/backend_api_client.dart';
import 'package:nano_app/sale_referral/data/datasources/sale_remote_datasource.dart';

class BackendSaleRemoteDatasource implements SaleRemoteDatasource {
  final BackendApiClient? clientOverride;

  const BackendSaleRemoteDatasource({this.clientOverride});

  BackendApiClient get _client => clientOverride ?? BackendApiClient.shared;

  @override
  Future<Object?> getSaleState() =>
      _client.requestMap('GET', '/api/v1/sale/me');

  @override
  Future<Object?> requestSaleParticipation({
    required String termsVersion,
    required String deviceHash,
  }) => _client.requestMap(
    'POST',
    '/api/v1/sale/participation',
    body: {'terms_version': termsVersion, 'device_hash': deviceHash},
  );

  @override
  Future<Object?> attachReferralCode(
    String code, {
    required String deviceHash,
  }) => _client.requestMap(
    'POST',
    '/api/v1/sale/referrals/attach',
    body: {'referral_code': code, 'device_hash': deviceHash},
  );

  @override
  Future<Object?> getPayoutProfile() =>
      _client.request('GET', '/api/v1/sale/payout-profile');

  @override
  Future<Object?> upsertPayoutProfile({
    required String citizenId,
    required String bankBin,
    required String bankName,
    required String bankAccountNumber,
    required String bankAccountName,
  }) => _client.requestMap(
    'PUT',
    '/api/v1/sale/payout-profile',
    body: {
      'citizen_id': citizenId,
      'bank_bin': bankBin,
      'bank_name': bankName,
      'bank_account_number': bankAccountNumber,
      'bank_account_name': bankAccountName,
    },
  );

  @override
  Future<Object?> getDashboard() =>
      _client.requestMap('GET', '/api/v1/sale/dashboard');

  @override
  Future<Object?> getDirectCustomers() =>
      _client.request('GET', '/api/v1/sale/customers');

  @override
  Future<Object?> getPointLedger() =>
      _client.request('GET', '/api/v1/sale/point-ledger');

  @override
  Future<Object?> getConversions() =>
      _client.request('GET', '/api/v1/sale/conversions');

  @override
  Future<Object?> requestConversion({
    required int pointCents,
    required String idempotencyKey,
  }) => _client.requestMap(
    'POST',
    '/api/v1/sale/conversions',
    body: {
      'requested_point_cents': pointCents,
      'idempotency_key': idempotencyKey,
    },
  );
}
