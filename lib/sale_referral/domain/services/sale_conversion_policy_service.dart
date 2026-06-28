import 'package:nano_app/sale_referral/domain/entities/sale_models.dart';

class SaleConversionPolicyService {
  const SaleConversionPolicyService();

  String? validateRequest({
    required SaleConversionPolicy policy,
    required int availablePointCents,
    required int requestedPointCents,
  }) {
    if (!policy.enabled) return 'Tinh nang quy doi diem Sale chua duoc mo.';
    if (requestedPointCents <= 0) return 'So diem quy doi phai lon hon 0.';
    if (requestedPointCents < policy.minimumPointCents) {
      return 'So diem chua dat muc toi thieu de quy doi.';
    }
    if (requestedPointCents > availablePointCents) {
      return 'So diem quy doi vuot qua diem kha dung.';
    }
    return null;
  }
}
