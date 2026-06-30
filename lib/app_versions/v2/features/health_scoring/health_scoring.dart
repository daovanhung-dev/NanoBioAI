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
    'Tinh diem suc khoe v1 tu lich su hoan thanh lich cham soc that.',
    'Doc bua an, nhiem vu hang ngay va nhip sinh hoat qua data layer.',
    'Khong dung mock, fake hoac sample dashboard data trong production.',
    'Giu diem cham soc v1 local tach khoi cong thuc health scoring v2.',
    'Cho phep FamilyPlus xem subject khac qua policy dung chung.',
  ];
  static const disclaimer =
      'Diem suc khoe chi de theo doi xu huong cham soc hang ngay, khong thay the chan doan y khoa.';
}
