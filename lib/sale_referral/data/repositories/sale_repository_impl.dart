import 'package:nano_app/sale_referral/data/datasources/sale_remote_datasource.dart';
import 'package:nano_app/sale_referral/domain/entities/sale_models.dart';
import 'package:nano_app/sale_referral/domain/repositories/sale_repository.dart';

class SaleRepositoryImpl implements SaleRepository {
  final SaleRemoteDatasource datasource;

  const SaleRepositoryImpl({required this.datasource});

  @override
  Future<SaleState> fetchSaleState() async {
    final response = await datasource.getSaleState();
    return SaleState.fromMap(_firstMap(response));
  }

  @override
  Future<SaleState> requestSaleParticipation({
    required String termsVersion,
    required String deviceHash,
  }) async {
    final response = await datasource.requestSaleParticipation(
      termsVersion: termsVersion,
      deviceHash: deviceHash,
    );
    return SaleState.fromMap(_firstMap(response));
  }

  @override
  Future<SaleReferralAttachment> attachReferralCode(
    String code, {
    required String deviceHash,
  }) async {
    final response = await datasource.attachReferralCode(
      code,
      deviceHash: deviceHash,
    );
    return SaleReferralAttachment.fromMap(_firstMap(response));
  }

  @override
  Future<SalePayoutProfile?> fetchPayoutProfile() async {
    final response = await datasource.getPayoutProfile();
    final map = _firstMap(response);
    if (map.isEmpty) return null;
    return SalePayoutProfile.fromMap(map);
  }

  @override
  Future<SalePayoutProfile> upsertPayoutProfile(
    SalePayoutProfileCommand command,
  ) async {
    final response = await datasource.upsertPayoutProfile(
      citizenId: command.citizenId,
      bankBin: command.bankBin,
      bankName: command.bankName,
      bankAccountNumber: command.bankAccountNumber,
      bankAccountName: command.bankAccountName,
    );
    return SalePayoutProfile.fromMap(_firstMap(response));
  }

  @override
  Future<SaleDashboard> fetchDashboard() async {
    final response = await datasource.getDashboard();
    return SaleDashboard.fromMap(_firstMap(response));
  }

  @override
  Future<List<SaleDirectCustomer>> fetchDirectCustomers() async {
    final response = await datasource.getDirectCustomers();
    return _maps(response).map(SaleDirectCustomer.fromMap).toList();
  }

  @override
  Future<List<SalePointLedgerEntry>> fetchPointLedger() async {
    final response = await datasource.getPointLedger();
    return _maps(response).map(SalePointLedgerEntry.fromMap).toList();
  }

  @override
  Future<List<SaleConversionRequest>> fetchConversionRequests() async {
    final response = await datasource.getConversions();
    return _maps(response).map(SaleConversionRequest.fromMap).toList();
  }

  @override
  Future<SaleConversionRequest> requestConversion(
    SaleConversionCommand command,
  ) async {
    final response = await datasource.requestConversion(
      pointCents: command.pointCents,
      idempotencyKey: command.idempotencyKey,
    );
    return SaleConversionRequest.fromMap(_firstMap(response));
  }
}

Map<String, Object?> _firstMap(Object? response) {
  if (response is Map) return _copyMap(response);
  if (response is List && response.isNotEmpty) {
    final first = response.first;
    if (first is Map) return _copyMap(first);
  }

  return const {};
}

List<Map<String, Object?>> _maps(Object? response) {
  if (response is! List) return const [];
  return response.whereType<Map>().map(_copyMap).toList(growable: false);
}

Map<String, Object?> _copyMap(Map<dynamic, dynamic> map) {
  return map.map((key, value) => MapEntry(key.toString(), value));
}
