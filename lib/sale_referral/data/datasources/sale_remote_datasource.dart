abstract class SaleRemoteDatasource {
  Future<Object?> getSaleState();

  Future<Object?> requestSaleParticipation({required String termsVersion});

  Future<Object?> attachReferralCode(String code);

  Future<Object?> getDashboard();

  Future<Object?> getDirectCustomers();

  Future<Object?> getPointLedger();

  Future<Object?> getConversions();

  Future<Object?> requestConversion({
    required int pointCents,
    required String idempotencyKey,
  });
}
