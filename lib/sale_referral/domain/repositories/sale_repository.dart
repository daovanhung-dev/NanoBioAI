import 'package:nano_app/sale_referral/domain/entities/sale_models.dart';

abstract class SaleRepository {
  Future<SaleState> fetchSaleState();

  Future<SaleState> requestSaleParticipation({
    required String termsVersion,
    required String deviceHash,
  });

  Future<SaleReferralAttachment> attachReferralCode(
    String code, {
    required String deviceHash,
  });

  Future<SalePayoutProfile?> fetchPayoutProfile();

  Future<SalePayoutProfile> upsertPayoutProfile(
    SalePayoutProfileCommand command,
  );

  Future<SaleDashboard> fetchDashboard();

  Future<List<SaleDirectCustomer>> fetchDirectCustomers();

  Future<List<SalePointLedgerEntry>> fetchPointLedger();

  Future<List<SaleConversionRequest>> fetchConversionRequests();

  Future<SaleConversionRequest> requestConversion(
    SaleConversionCommand command,
  );
}
