import 'package:nano_app/sale_referral/data/datasources/sale_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSaleRemoteDatasource implements SaleRemoteDatasource {
  final SupabaseClient? clientOverride;

  const SupabaseSaleRemoteDatasource({this.clientOverride});

  @override
  Future<Object?> getSaleState() async {
    final client = _clientOrNull();
    if (client == null || client.auth.currentUser == null) return const {};
    return client.rpc('get_my_sale_state');
  }

  @override
  Future<Object?> requestSaleParticipation({
    required String termsVersion,
    required String deviceHash,
  }) {
    return _client().rpc(
      'request_sale_participation',
      params: {'p_terms_version': termsVersion, 'p_device_hash': deviceHash},
    );
  }

  @override
  Future<Object?> attachReferralCode(
    String code, {
    required String deviceHash,
  }) {
    return _client().rpc(
      'attach_my_referral_code',
      params: {'p_referral_code': code, 'p_device_hash': deviceHash},
    );
  }

  @override
  Future<Object?> getPayoutProfile() {
    return _client().rpc('get_my_sale_payout_profile');
  }

  @override
  Future<Object?> upsertPayoutProfile({
    required String citizenId,
    required String bankBin,
    required String bankName,
    required String bankAccountNumber,
    required String bankAccountName,
  }) {
    return _client().rpc(
      'upsert_my_sale_payout_profile',
      params: {
        'p_citizen_id': citizenId,
        'p_bank_bin': bankBin,
        'p_bank_name': bankName,
        'p_bank_account_number': bankAccountNumber,
        'p_bank_account_name': bankAccountName,
      },
    );
  }

  @override
  Future<Object?> getDashboard() {
    return _client().rpc('get_my_sale_dashboard');
  }

  @override
  Future<Object?> getDirectCustomers() {
    return _client().rpc('get_my_sale_direct_customers');
  }

  @override
  Future<Object?> getPointLedger() {
    return _client().rpc('get_my_sale_point_ledger');
  }

  @override
  Future<Object?> getConversions() {
    return _client().rpc('get_my_sale_conversions');
  }

  @override
  Future<Object?> requestConversion({
    required int pointCents,
    required String idempotencyKey,
  }) {
    return _client().rpc(
      'request_sale_point_conversion',
      params: {
        'p_requested_point_cents': pointCents,
        'p_idempotency_key': idempotencyKey,
      },
    );
  }

  SupabaseClient _client() {
    final client = _clientOrNull();
    if (client == null || client.auth.currentUser == null) {
      throw const AuthException('Missing authenticated session.');
    }
    return client;
  }

  SupabaseClient? _clientOrNull() {
    if (clientOverride != null) return clientOverride;
    try {
      return Supabase.instance.client;
    } on AssertionError {
      return null;
    }
  }
}
