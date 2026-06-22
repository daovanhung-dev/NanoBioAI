/// Pure estimator for the Sale screen.
///
/// This never creates commission records or grants payout rights. Actual
/// commission is calculated only by trusted Supabase payment-event logic.
class SaleCommissionCalculator {
  const SaleCommissionCalculator._();

  static const double directRate = 0.10;
  static const double secondLevelRate = 0.05;

  static SaleCommissionEstimate estimate({
    required int planAmountCents,
    required int directSuccessfulPayments,
    required int secondLevelSuccessfulPayments,
    double directCommissionRate = directRate,
    double secondLevelCommissionRate = secondLevelRate,
  }) {
    final safeAmount = planAmountCents < 0 ? 0 : planAmountCents;
    final safeDirect = directSuccessfulPayments < 0
        ? 0
        : directSuccessfulPayments;
    final safeSecond = secondLevelSuccessfulPayments < 0
        ? 0
        : secondLevelSuccessfulPayments;
    final safeDirectRate = directCommissionRate.clamp(0, 1).toDouble();
    final safeSecondRate = secondLevelCommissionRate.clamp(0, 1).toDouble();

    final direct = (safeAmount * safeDirect * safeDirectRate).round();
    final second = (safeAmount * safeSecond * safeSecondRate).round();

    return SaleCommissionEstimate(
      directCommissionCents: direct,
      secondLevelCommissionCents: second,
      totalCommissionCents: direct + second,
    );
  }
}

class SaleCommissionEstimate {
  final int directCommissionCents;
  final int secondLevelCommissionCents;
  final int totalCommissionCents;

  const SaleCommissionEstimate({
    required this.directCommissionCents,
    required this.secondLevelCommissionCents,
    required this.totalCommissionCents,
  });
}
