class ExercisePlanningPreferencesTable {
  static const tableName = 'exercise_planning_preferences';

  static const createTable = '''
  CREATE TABLE IF NOT EXISTS exercise_planning_preferences (
    user_id TEXT PRIMARY KEY,
    equipment_json TEXT NOT NULL DEFAULT '[]',
    limitation_tags_json TEXT NOT NULL DEFAULT '[]',
    updated_at TEXT NOT NULL
  )
  ''';
}
