export 'application/health_score_habits_fn01.dart';
export 'application/health_score_habits_fn02.dart';
export 'data/datasources/sqlite_health_score_habits_local_datasource.dart';
export 'data/repositories/local_health_score_habits_repository.dart';
export 'domain/entities/health_score_habits_models.dart';
export 'domain/repositories/health_score_habits_repository.dart';
export 'domain/services/health_score_habits_calculator.dart';
export 'presentation/pages/health_score_habits_page.dart';
export 'providers/health_score_habits_providers.dart';

class V2HealthScoringFeature {
  const V2HealthScoringFeature._();

  static const status = 'local_draft';
  static const accessLayer = 'v2/free-authenticated';
  static const formulaVersion = 'm08_local_draft_2026_06';

  static const responsibilities = <String>[
    'Calculate local draft health score from real schedule completion history.',
    'Read meal, daily task, and lifestyle schedule progress through data layer.',
    'Avoid mock, fake, or sample dashboard data in production.',
    'Keep the v1 local daily care score separate from the official v2 health scoring formula.',
    'Prepare a clear contract for Plus and FamilyPlus scoring extensions.',
  ];

  static const blockedUntil =
      'Q-14 closes the official health formula and Q-15 closes FamilyPlus subject/consent policy.';
}
