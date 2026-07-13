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
    description:
        'Lưu lại chỉ số huyết áp và bối cảnh đo để dễ theo dõi theo thời gian.',
    comingSoonEyebrow: 'NHẬT KÝ HUYẾT ÁP',
    comingSoonMessage:
        'Nabi đang hoàn thiện nhật ký giúp bạn ghi lại huyết áp rõ ràng, an toàn và dễ xem lại.',
    icon: Icons.bloodtype_rounded,
    color: AppColors.error,
    minimumAccess: HealthFeatureMinimumAccess.free,
    previewItems: [
      'Ghi giá trị tâm thu và tâm trương',
      'Thêm thời điểm và hoàn cảnh đo',
      'Xem lại lịch sử theo thời gian',
    ],
  ),
  HealthFeatureCatalogItem(
    moduleId: 'M21',
    moduleCode: 'HEART_OXYGEN_TRACKING',
    title: 'Nhịp tim & SpO₂',
    description: 'Theo dõi nhịp tim, SpO₂ và nguồn đo trong cùng một nơi.',
    comingSoonEyebrow: 'NHỊP TIM & SPO₂',
    comingSoonMessage:
        'Nabi đang chuẩn bị không gian giúp bạn lưu và xem lại các chỉ số từ nguồn đo đã chọn.',
    icon: Icons.monitor_heart_rounded,
    color: AppColors.primary,
    minimumAccess: HealthFeatureMinimumAccess.free,
    previewItems: [
      'Ghi nhịp tim và SpO₂',
      'Gắn nguồn và thời điểm đo',
      'Xem lại xu hướng đã ghi nhận',
    ],
  ),
  HealthFeatureCatalogItem(
    moduleId: 'M22',
    moduleCode: 'MEDICATION_ADHERENCE',
    title: 'Lịch dùng thuốc',
    description:
        'Tạo lịch do bạn nhập và đánh dấu mỗi lần đã dùng hoặc bỏ qua.',
    comingSoonEyebrow: 'LỊCH DÙNG THUỐC',
    comingSoonMessage:
        'Nabi đang hoàn thiện lịch cá nhân để bạn chủ động theo dõi việc dùng thuốc đã được hướng dẫn.',
    icon: Icons.medication_rounded,
    color: AppColors.secondary,
    minimumAccess: HealthFeatureMinimumAccess.free,
    previewItems: [
      'Tạo lịch theo hướng dẫn đang có',
      'Đánh dấu đã dùng hoặc bỏ qua',
      'Xem lại lịch sử tuân thủ',
    ],
  ),
  HealthFeatureCatalogItem(
    moduleId: 'M23',
    moduleCode: 'GLUCOSE_TRACKING',
    title: 'Theo dõi đường huyết',
    description:
        'Ghi giá trị, đơn vị và bối cảnh trước hoặc sau ăn để dễ xem lại.',
    comingSoonEyebrow: 'THEO DÕI ĐƯỜNG HUYẾT',
    comingSoonMessage:
        'Nabi đang chuẩn bị nhật ký đường huyết để bạn lưu dữ liệu đo một cách nhất quán.',
    icon: Icons.water_drop_rounded,
    color: AppColors.warning,
    minimumAccess: HealthFeatureMinimumAccess.plus,
    previewItems: [
      'Ghi giá trị và đơn vị đo',
      'Chọn bối cảnh trước hoặc sau ăn',
      'Xem lại lịch sử theo thời gian',
    ],
  ),
  HealthFeatureCatalogItem(
    moduleId: 'M24',
    moduleCode: 'SYMPTOM_PAIN_JOURNAL',
    title: 'Nhật ký triệu chứng & cơn đau',
    description:
        'Ghi lại triệu chứng, mức độ và bối cảnh để chuẩn bị tốt hơn khi đi khám.',
    comingSoonEyebrow: 'NHẬT KÝ TRIỆU CHỨNG',
    comingSoonMessage:
        'Nabi đang xây dựng nhật ký có AI hỗ trợ tóm tắt nội dung bạn đã xác nhận, không thay thế chẩn đoán y khoa.',
    icon: Icons.healing_rounded,
    color: AppColors.tertiary,
    minimumAccess: HealthFeatureMinimumAccess.plus,
    previewItems: [
      'Ghi triệu chứng, mức độ và bối cảnh',
      'AI tóm tắt nhật ký đã xác nhận',
      'Chuẩn bị câu hỏi để trao đổi với bác sĩ',
    ],
  ),
  HealthFeatureCatalogItem(
    moduleId: 'M25',
    moduleCode: 'WOMENS_CYCLE_HEALTH',
    title: 'Chu kỳ & sức khỏe nữ',
    description:
        'Theo dõi chu kỳ và triệu chứng để hiểu những thay đổi của cơ thể.',
    comingSoonEyebrow: 'CHU KỲ & SỨC KHỎE NỮ',
    comingSoonMessage:
        'Nabi đang hoàn thiện công cụ ghi nhận chu kỳ và triệu chứng dành cho việc theo dõi cá nhân.',
    icon: Icons.calendar_month_rounded,
    color: AppColors.error,
    minimumAccess: HealthFeatureMinimumAccess.plus,
    previewItems: [
      'Ghi ngày chu kỳ',
      'Theo dõi triệu chứng đi kèm',
      'Xem lại lịch sử đã ghi nhận',
    ],
  ),
  HealthFeatureCatalogItem(
    moduleId: 'M26',
    moduleCode: 'RESPIRATORY_ALLERGY_TRACKING',
    title: 'Hô hấp & dị ứng',
    description:
        'Ghi triệu chứng, phản ứng và yếu tố phơi nhiễm để dễ đối chiếu.',
    comingSoonEyebrow: 'HÔ HẤP & DỊ ỨNG',
    comingSoonMessage:
        'Nabi đang chuẩn bị nhật ký giúp bạn ghi nhận triệu chứng hô hấp và dị ứng theo thời gian.',
    icon: Icons.air_rounded,
    color: AppColors.info,
    minimumAccess: HealthFeatureMinimumAccess.plus,
    previewItems: [
      'Ghi triệu chứng và phản ứng',
      'Thêm yếu tố phơi nhiễm',
      'Xem lại các lần đã ghi nhận',
    ],
  ),
  HealthFeatureCatalogItem(
    moduleId: 'M27',
    moduleCode: 'LAB_RESULT_TRACKING',
    title: 'Xét nghiệm & chỉ số y khoa',
    description:
        'Lưu kết quả cùng đơn vị và khoảng tham chiếu có trên phiếu xét nghiệm.',
    comingSoonEyebrow: 'KẾT QUẢ XÉT NGHIỆM',
    comingSoonMessage:
        'Nabi đang phát triển công cụ có AI hỗ trợ nhập liệu; mọi kết quả đều cần bạn kiểm tra và xác nhận.',
    icon: Icons.science_rounded,
    color: AppColors.secondary,
    minimumAccess: HealthFeatureMinimumAccess.plus,
    previewItems: [
      'Ghi kết quả, đơn vị và ngày xét nghiệm',
      'AI hỗ trợ trích xuất để bạn xác nhận',
      'Giữ khoảng tham chiếu trên phiếu',
    ],
  ),
  HealthFeatureCatalogItem(
    moduleId: 'M28',
    moduleCode: 'PREVENTIVE_CARE',
    title: 'Lịch chăm sóc dự phòng',
    description:
        'Sắp xếp lịch khám, tiêm chủng và tầm soát do bạn hoặc bác sĩ cung cấp.',
    comingSoonEyebrow: 'CHĂM SÓC DỰ PHÒNG',
    comingSoonMessage:
        'Nabi đang chuẩn bị lịch tổng hợp để bạn chủ động theo dõi các mốc chăm sóc đã được cung cấp.',
    icon: Icons.event_available_rounded,
    color: AppColors.success,
    minimumAccess: HealthFeatureMinimumAccess.plus,
    previewItems: [
      'Thêm lịch khám và tái khám',
      'Lưu mốc tiêm chủng, tầm soát',
      'Kết nối nhắc lịch khi sẵn sàng',
    ],
  ),
  HealthFeatureCatalogItem(
    moduleId: 'M29',
    moduleCode: 'AI_HEALTH_TRENDS',
    title: 'Báo cáo xu hướng sức khỏe AI',
    description:
        'Tổng hợp các thống kê đã xác định và diễn giải thành báo cáo dễ đọc.',
    comingSoonEyebrow: 'XU HƯỚNG SỨC KHỎE AI',
    comingSoonMessage:
        'Nabi đang phát triển báo cáo dùng AI để diễn đạt số liệu đã tính sẵn, không suy đoán nguyên nhân bệnh.',
    icon: Icons.auto_graph_rounded,
    color: AppColors.tertiary,
    minimumAccess: HealthFeatureMinimumAccess.plus,
    previewItems: [
      'Tổng hợp thống kê đã xác định',
      'AI diễn đạt báo cáo dễ đọc',
      'Xem lại xu hướng theo thời gian',
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
