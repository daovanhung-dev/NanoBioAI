abstract class SaleRemoteDatasource {
  Future<Object?> getSaleState();

  Future<Object?> requestSaleParticipation({
    required String termsVersion,
    required String deviceHash,
  });

  Future<Object?> attachReferralCode(String code, {required String deviceHash});

  Future<Object?> getPayoutProfile();

  Future<Object?> upsertPayoutProfile({
    required String citizenId,
    required String bankBin,
    required String bankName,
    required String bankAccountNumber,
    required String bankAccountName,
  });

  Future<Object?> getDashboard();

  Future<Object?> getDirectCustomers();

  Future<Object?> getPointLedger();

  Future<Object?> getConversions();

  Future<Object?> requestConversion({
    required int pointCents,
    required String idempotencyKey,
  });
}
