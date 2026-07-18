import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/app_colors.dart';

enum HealthFeatureMinimumAccess { free, plus }

@immutable
class HealthFeatureCatalogItem {
  final String moduleId;
  final String moduleCode;
  final String title;
  final String description;
  final String comingSoonEyebrow;
  final String comingSoonMessage;
  final IconData icon;
  final Color color;
  final HealthFeatureMinimumAccess minimumAccess;
  final List<String> previewItems;

  const HealthFeatureCatalogItem({
    required this.moduleId,
    required this.moduleCode,
    required this.title,
    required this.description,
    required this.comingSoonEyebrow,
    required this.comingSoonMessage,
    required this.icon,
    required this.color,
    required this.minimumAccess,
    required this.previewItems,
  });
}

const List<HealthFeatureCatalogItem> advancedHealthFeatureCatalog = [
  HealthFeatureCatalogItem(
    moduleId: 'M20',
    moduleCode: 'BLOOD_PRESSURE_TRACKING',
    title: 'Nhật ký huyết áp',
    description: 'Ghi huyết áp và bối cảnh đo để xem lại dễ hơn.',
    comingSoonEyebrow: 'NHẬT KÝ HUYẾT ÁP',
    comingSoonMessage: 'Nabi đang hoàn thiện nhật ký huyết áp an toàn.',
    icon: Icons.bloodtype_rounded,
    color: AppColors.error,
    minimumAccess: HealthFeatureMinimumAccess.free,
    previewItems: [
      'Ghi tâm thu/tâm trương',
      'Thêm giờ và bối cảnh',
      'Xem lại lịch sử',
    ],
  ),
  HealthFeatureCatalogItem(
    moduleId: 'M21',
    moduleCode: 'HEART_OXYGEN_TRACKING',
    title: 'Nhịp tim & SpO₂',
    description: 'Ghi nhịp tim, SpO₂ và nguồn đo.',
    comingSoonEyebrow: 'NHỊP TIM & SPO₂',
    comingSoonMessage: 'Nabi đang chuẩn bị nhật ký nhịp tim và SpO₂.',
    icon: Icons.monitor_heart_rounded,
    color: AppColors.primary,
    minimumAccess: HealthFeatureMinimumAccess.free,
    previewItems: ['Ghi nhịp tim và SpO₂', 'Gắn nguồn đo', 'Xem lại xu hướng'],
  ),
  HealthFeatureCatalogItem(
    moduleId: 'M22',
    moduleCode: 'MEDICATION_ADHERENCE',
    title: 'Lịch dùng thuốc',
    description: 'Tạo lịch và đánh dấu đã dùng hoặc bỏ qua.',
    comingSoonEyebrow: 'LỊCH DÙNG THUỐC',
    comingSoonMessage: 'Nabi đang hoàn thiện lịch dùng thuốc cá nhân.',
    icon: Icons.medication_rounded,
    color: AppColors.secondary,
    minimumAccess: HealthFeatureMinimumAccess.free,
    previewItems: [
      'Tạo lịch theo hướng dẫn',
      'Đánh dấu đã dùng hoặc bỏ qua',
      'Xem lại lịch sử tuân thủ',
    ],
  ),
  HealthFeatureCatalogItem(
    moduleId: 'M23',
    moduleCode: 'GLUCOSE_TRACKING',
    title: 'Theo dõi đường huyết',
    description: 'Ghi đường huyết, đơn vị và bối cảnh bữa ăn.',
    comingSoonEyebrow: 'THEO DÕI ĐƯỜNG HUYẾT',
    comingSoonMessage: 'Nabi đang chuẩn bị nhật ký đường huyết.',
    icon: Icons.water_drop_rounded,
    color: AppColors.warning,
    minimumAccess: HealthFeatureMinimumAccess.plus,
    previewItems: [
      'Ghi giá trị và đơn vị đo',
      'Chọn trước/sau ăn',
      'Xem lại lịch sử',
    ],
  ),
  HealthFeatureCatalogItem(
    moduleId: 'M24',
    moduleCode: 'SYMPTOM_PAIN_JOURNAL',
    title: 'Nhật ký triệu chứng & cơn đau',
    description: 'Ghi triệu chứng, mức độ và bối cảnh.',
    comingSoonEyebrow: 'NHẬT KÝ TRIỆU CHỨNG',
    comingSoonMessage: 'AI chỉ tóm tắt nội dung bạn đã xác nhận.',
    icon: Icons.healing_rounded,
    color: AppColors.tertiary,
    minimumAccess: HealthFeatureMinimumAccess.plus,
    previewItems: [
      'Ghi triệu chứng và mức độ',
      'AI tóm tắt nhật ký đã xác nhận',
      'Chuẩn bị câu hỏi đi khám',
    ],
  ),
  HealthFeatureCatalogItem(
    moduleId: 'M25',
    moduleCode: 'WOMENS_CYCLE_HEALTH',
    title: 'Chu kỳ & sức khỏe nữ',
    description: 'Theo dõi chu kỳ và triệu chứng đi kèm.',
    comingSoonEyebrow: 'CHU KỲ & SỨC KHỎE NỮ',
    comingSoonMessage: 'Nabi đang hoàn thiện nhật ký chu kỳ cá nhân.',
    icon: Icons.calendar_month_rounded,
    color: AppColors.error,
    minimumAccess: HealthFeatureMinimumAccess.plus,
    previewItems: [
      'Ghi ngày chu kỳ',
      'Theo dõi triệu chứng',
      'Xem lại lịch sử',
    ],
  ),
  HealthFeatureCatalogItem(
    moduleId: 'M26',
    moduleCode: 'RESPIRATORY_ALLERGY_TRACKING',
    title: 'Hô hấp & dị ứng',
    description: 'Ghi triệu chứng, phản ứng và yếu tố phơi nhiễm.',
    comingSoonEyebrow: 'HÔ HẤP & DỊ ỨNG',
    comingSoonMessage: 'Nabi đang chuẩn bị nhật ký hô hấp và dị ứng.',
    icon: Icons.air_rounded,
    color: AppColors.info,
    minimumAccess: HealthFeatureMinimumAccess.plus,
    previewItems: [
      'Ghi triệu chứng và phản ứng',
      'Thêm yếu tố phơi nhiễm',
      'Xem lại lịch sử',
    ],
  ),
  HealthFeatureCatalogItem(
    moduleId: 'M27',
    moduleCode: 'LAB_RESULT_TRACKING',
    title: 'Xét nghiệm & chỉ số y khoa',
    description: 'Lưu kết quả, đơn vị và khoảng tham chiếu.',
    comingSoonEyebrow: 'KẾT QUẢ XÉT NGHIỆM',
    comingSoonMessage: 'AI chỉ hỗ trợ nhập liệu sau khi bạn xác nhận.',
    icon: Icons.science_rounded,
    color: AppColors.secondary,
    minimumAccess: HealthFeatureMinimumAccess.plus,
    previewItems: [
      'Ghi kết quả và đơn vị',
      'AI hỗ trợ trích xuất để bạn xác nhận',
      'Giữ khoảng tham chiếu',
    ],
  ),
  HealthFeatureCatalogItem(
    moduleId: 'M28',
    moduleCode: 'PREVENTIVE_CARE',
    title: 'Lịch chăm sóc dự phòng',
    description: 'Lưu lịch khám, tiêm chủng và tầm soát.',
    comingSoonEyebrow: 'CHĂM SÓC DỰ PHÒNG',
    comingSoonMessage: 'Nabi đang chuẩn bị lịch chăm sóc dự phòng.',
    icon: Icons.event_available_rounded,
    color: AppColors.success,
    minimumAccess: HealthFeatureMinimumAccess.plus,
    previewItems: [
      'Thêm lịch khám và tái khám',
      'Lưu mốc tiêm chủng',
      'Kết nối nhắc lịch khi sẵn sàng',
    ],
  ),
  HealthFeatureCatalogItem(
    moduleId: 'M29',
    moduleCode: 'AI_HEALTH_TRENDS',
    title: 'Xu hướng sức khỏe AI',
    description: 'Tổng hợp số liệu đã có thành báo cáo dễ đọc.',
    comingSoonEyebrow: 'XU HƯỚNG SỨC KHỎE AI',
    comingSoonMessage: 'AI diễn đạt số liệu, không suy đoán bệnh.',
    icon: Icons.auto_graph_rounded,
    color: AppColors.tertiary,
    minimumAccess: HealthFeatureMinimumAccess.plus,
    previewItems: [
      'Tổng hợp thống kê',
      'AI diễn đạt báo cáo dễ đọc',
      'Xem lại xu hướng',
    ],
  ),
];

HealthFeatureCatalogItem? healthFeatureByModuleId(String moduleId) {
  final normalizedModuleId = moduleId.trim().toUpperCase();

  for (final item in advancedHealthFeatureCatalog) {
    if (item.moduleId == normalizedModuleId) {
      return item;
    }
  }

  return null;
}
