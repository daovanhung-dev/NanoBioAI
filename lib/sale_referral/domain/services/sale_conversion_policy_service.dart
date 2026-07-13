import 'package:nano_app/sale_referral/domain/entities/sale_models.dart';

class SaleConversionPolicyService {
  const SaleConversionPolicyService();

  String? validateRequest({
    required SaleConversionPolicy policy,
    required int availablePointCents,
    required int requestedPointCents,
  }) {
    if (!policy.enabled) {
      return 'Tính năng quy đổi điểm cộng tác viên chưa được mở.';
    }
    if (requestedPointCents <= 0) return 'Số điểm quy đổi phải lớn hơn 0.';
    if (requestedPointCents < policy.minimumPointCents) {
      return 'Số điểm chưa đạt mức tối thiểu để quy đổi.';
    }
    if (requestedPointCents > availablePointCents) {
      return 'Số điểm quy đổi vượt quá điểm khả dụng.';
    }
    return null;
  }
}
