import 'package:sqflite/sqflite.dart';

class NutritionProfileTables {
  NutritionProfileTables._();

  static const nutritionProfiles = 'nutrition_profiles';
  static const healthSymptoms = 'health_symptoms';
  static const medicationRecords = 'medication_records';
  static const foodRestrictions = 'food_restrictions';
  static const labResults = 'lab_results';
  static const nutritionGoals = 'nutrition_goals';
  static const mealSchedulePreferences = 'meal_schedule_preferences';
  static const nutritionPreferenceRules = 'nutrition_preference_rules';

  static const userOwnedTables = <String>[
    nutritionProfiles,
    healthSymptoms,
    medicationRecords,
    foodRestrictions,
    labResults,
    nutritionGoals,
    mealSchedulePreferences,
    nutritionPreferenceRules,
  ];

  static const createStatements = <String>[
    '''
CREATE TABLE IF NOT EXISTS nutrition_profiles (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  birth_date TEXT,
  waist_cm REAL,
  current_status TEXT,
  average_sleep_hours REAL,
  smoking_status TEXT NOT NULL DEFAULT 'not_provided',
  smoking_amount_note TEXT,
  alcohol_frequency TEXT NOT NULL DEFAULT 'not_provided',
  coffee_frequency TEXT NOT NULL DEFAULT 'not_provided',
  target_weight_kg REAL,
  target_weight_source TEXT,
  water_restriction INTEGER NOT NULL DEFAULT 0,
  water_restriction_note TEXT,
  nocturia_level TEXT NOT NULL DEFAULT 'not_provided',
  schema_version INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''',
    '''CREATE UNIQUE INDEX IF NOT EXISTS idx_nutrition_profiles_user ON nutrition_profiles(user_id)''',
    '''
CREATE TABLE IF NOT EXISTS health_symptoms (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  symptom_type TEXT NOT NULL,
  body_location TEXT,
  severity_level INTEGER,
  started_at TEXT,
  trigger_note TEXT,
  impact_note TEXT,
  note TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''',
    '''CREATE INDEX IF NOT EXISTS idx_health_symptoms_user_active ON health_symptoms(user_id, is_active, symptom_type)''',
    '''
CREATE TABLE IF NOT EXISTS medication_records (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  product_type TEXT NOT NULL DEFAULT 'medication',
  usage_schedule TEXT,
  prescriber_confirmed INTEGER NOT NULL DEFAULT 0,
  note TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''',
    '''CREATE INDEX IF NOT EXISTS idx_medication_records_user_active ON medication_records(user_id, is_active, product_type)''',
    '''
CREATE TABLE IF NOT EXISTS food_restrictions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  restriction_type TEXT NOT NULL,
  item_name TEXT NOT NULL,
  severity_level INTEGER,
  note TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''',
    '''CREATE INDEX IF NOT EXISTS idx_food_restrictions_user_type ON food_restrictions(user_id, is_active, restriction_type)''',
    '''
CREATE TABLE IF NOT EXISTS lab_results (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  test_code TEXT,
  test_name TEXT NOT NULL,
  value_text TEXT NOT NULL,
  unit TEXT,
  measured_at TEXT,
  reference_note TEXT,
  note TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''',
    '''CREATE INDEX IF NOT EXISTS idx_lab_results_user_date ON lab_results(user_id, measured_at, test_name)''',
    '''
CREATE TABLE IF NOT EXISTS nutrition_goals (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  goal_code TEXT NOT NULL,
  goal_name TEXT NOT NULL,
  priority INTEGER NOT NULL CHECK (priority BETWEEN 1 AND 3),
  target_period TEXT,
  target_date TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''',
    '''CREATE UNIQUE INDEX IF NOT EXISTS idx_nutrition_goals_user_priority ON nutrition_goals(user_id, priority) WHERE is_active = 1''',
    '''
CREATE TABLE IF NOT EXISTS meal_schedule_preferences (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  meal_type TEXT NOT NULL,
  start_time TEXT,
  end_time TEXT,
  portion_note TEXT,
  target_calories INTEGER,
  note TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''',
    '''CREATE UNIQUE INDEX IF NOT EXISTS idx_meal_schedule_user_type ON meal_schedule_preferences(user_id, meal_type) WHERE is_active = 1''',
    '''
CREATE TABLE IF NOT EXISTS nutrition_preference_rules (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  rule_type TEXT NOT NULL,
  item_code TEXT,
  item_name TEXT NOT NULL,
  preference_level TEXT NOT NULL,
  note TEXT,
  schema_version INTEGER NOT NULL DEFAULT 1,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''',
    '''CREATE INDEX IF NOT EXISTS idx_nutrition_rules_user_type ON nutrition_preference_rules(user_id, is_active, rule_type, preference_level)''',
  ];

  static Future<void> create(DatabaseExecutor database) async {
    for (final statement in createStatements) {
      await database.execute(statement);
    }
  }
}
