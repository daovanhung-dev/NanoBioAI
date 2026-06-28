import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/sale_referral/domain/entities/sale_models.dart';
import 'package:nano_app/sale_referral/domain/repositories/sale_repository.dart';
import 'package:nano_app/sale_referral/providers/sale_providers.dart';

export 'package:nano_app/sale_referral/domain/entities/sale_models.dart';
export 'package:nano_app/sale_referral/domain/services/sale_referral_code_validator.dart';
export 'package:nano_app/sale_referral/providers/sale_providers.dart';

class SaleParticipationService {
  final SaleRepository repository;

  const SaleParticipationService({required this.repository});

  Future<SaleState> fetchState() => repository.fetchSaleState();

  Future<SaleState> requestParticipation({required String termsVersion}) {
    return repository.requestSaleParticipation(termsVersion: termsVersion);
  }

  Future<SaleReferralAttachment> attachReferralCode(String code) {
    return repository.attachReferralCode(code);
  }

  Future<SaleDashboard> fetchDashboard() => repository.fetchDashboard();

  Future<List<SaleDirectCustomer>> fetchDirectCustomers() {
    return repository.fetchDirectCustomers();
  }

  Future<List<SalePointLedgerEntry>> fetchPointLedger() {
    return repository.fetchPointLedger();
  }

  Future<List<SaleConversionRequest>> fetchConversionRequests() {
    return repository.fetchConversionRequests();
  }

  Future<SaleConversionRequest> requestConversion(
    SaleConversionCommand command,
  ) {
    return repository.requestConversion(command);
  }
}

final saleParticipationServiceProvider = Provider<SaleParticipationService>((
  ref,
) {
  return SaleParticipationService(
    repository: ref.watch(saleRepositoryProvider),
  );
});
