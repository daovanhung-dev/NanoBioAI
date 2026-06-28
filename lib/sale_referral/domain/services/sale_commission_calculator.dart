/// Pure estimator for the Sale screen.
///
/// This never creates commission records or grants payout rights. Actual
/// commission is calculated only by trusted Supabase payment-event logic.
class SaleCommissionCalculator {
  const SaleCommissionCalculator._();

  static const double directRate = 0.10;

  static SaleCommissionEstimate estimate({
    required int planAmountCents,
    required int directSuccessfulPayments,
    double directCommissionRate = directRate,
  }) {
    final safeAmount = planAmountCents < 0 ? 0 : planAmountCents;
    final safeDirect = directSuccessfulPayments < 0
        ? 0
        : directSuccessfulPayments;
    final safeDirectRate = directCommissionRate.clamp(0, 1).toDouble();

    final direct = (safeAmount * safeDirect * safeDirectRate).round();

    return SaleCommissionEstimate(
      directCommissionCents: direct,
      totalCommissionCents: direct,
    );
  }
}

class SaleCommissionEstimate {
  final int directCommissionCents;
  final int totalCommissionCents;

  const SaleCommissionEstimate({
    required this.directCommissionCents,
    required this.totalCommissionCents,
  });
}
