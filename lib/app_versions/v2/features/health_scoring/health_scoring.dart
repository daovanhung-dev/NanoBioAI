export 'application/health_score_habits_fn01.dart';
export 'application/health_score_habits_fn02.dart';
export 'data/datasources/sqlite_health_score_habits_local_datasource.dart';
export 'data/repositories/local_health_score_habits_repository.dart';
export 'domain/entities/health_score_habits_models.dart';
export 'domain/repositories/health_score_habits_repository.dart';
export 'domain/services/health_score_habits_calculator.dart';
export 'presentation/pages/health_score_habits_page.dart';
export 'providers/health_score_habits_providers.dart';

import 'domain/entities/health_score_habits_models.dart';

class V2HealthScoringFeature {
  const V2HealthScoringFeature._();

  static const status = 'official_v1';
  static const accessLayer = 'v2/authenticated-familyplus-aware';
  static const formulaVersion = healthScoreHabitsFormulaVersion;

  static const responsibilities = <String>[
    'Tính điểm sức khỏe từ lịch sử hoàn thành lịch chăm sóc thực tế.',
    'Đọc bữa ăn, nhiệm vụ hằng ngày và nhịp sinh hoạt qua tầng dữ liệu.',
    'Không dùng dữ liệu mẫu trong ứng dụng phát hành.',
    'Giữ điểm chăm sóc tách khỏi công thức tính điểm sức khỏe.',
    'Cho phép FamilyPlus xem thành viên khác theo chính sách dùng chung.',
  ];
  static const disclaimer =
      'Điểm sức khỏe chỉ để theo dõi xu hướng chăm sóc hằng ngày, không thay thế chẩn đoán y khoa.';
}
