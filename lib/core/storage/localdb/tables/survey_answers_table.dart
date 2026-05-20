class SurveyAnswersTable {
  static const tableName = 'survey_answers';

  static const createTable = '''
  CREATE TABLE survey_answers (
    id TEXT PRIMARY KEY,
    user_id TEXT,

    question_code TEXT,
    answer_value TEXT,

    created_at TEXT,

    FOREIGN KEY(user_id) REFERENCES users(id)
    ON DELETE CASCADE
  )
  ''';
}