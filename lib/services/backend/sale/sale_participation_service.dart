import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/sale_referral/domain/entities/sale_models.dart';
import 'package:nano_app/sale_referral/domain/repositories/sale_repository.dart';
import 'package:nano_app/sale_referral/providers/sale_providers.dart';

export 'package:nano_app/sale_referral/domain/entities/sale_models.dart';
export 'package:nano_app/sale_referral/domain/services/sale_referral_code_validator.dart';
export 'package:nano_app/sale_referral/providers/sale_providers.dart';

class SaleParticipationService {
  final SaleRepository repository;
  final Future<String> Function() deviceHashResolver;

  const SaleParticipationService({
    required this.repository,
    required this.deviceHashResolver,
  });

  Future<SaleState> fetchState() => repository.fetchSaleState();

  Future<SaleState> requestParticipation({required String termsVersion}) async {
    return repository.requestSaleParticipation(
      termsVersion: termsVersion,
      deviceHash: await deviceHashResolver(),
    );
  }

  Future<SaleReferralAttachment> attachReferralCode(String code) async {
    return repository.attachReferralCode(
      code,
      deviceHash: await deviceHashResolver(),
    );
  }

  Future<SalePayoutProfile?> fetchPayoutProfile() {
    return repository.fetchPayoutProfile();
  }

  Future<SalePayoutProfile> upsertPayoutProfile(
    SalePayoutProfileCommand command,
  ) {
    return repository.upsertPayoutProfile(command);
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
    deviceHashResolver: () => ref.read(saleDeviceHashProvider.future),
  );
});
