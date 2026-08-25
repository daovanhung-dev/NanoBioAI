import 'package:sqflite/sqflite.dart';

abstract final class SleepSafetyTables {
  static const preferences = 'sleep_safety_preferences';
  static const sessions = 'sleep_safety_sessions';
  static const events = 'sleep_safety_events';
  static const contacts = 'sleep_safety_contacts_cache';
  static const outbox = 'sleep_safety_outbox';
  static const analyses = 'sleep_safety_night_analyses';

  static const analysisSchema = <String>[
    '''CREATE TABLE IF NOT EXISTS $analyses (
      session_id TEXT PRIMARY KEY, user_id TEXT NOT NULL, formula_version TEXT NOT NULL,
      started_at TEXT NOT NULL, ended_at TEXT, metrics_json TEXT NOT NULL DEFAULT '{}',
      event_distribution_json TEXT NOT NULL DEFAULT '{}', trend_json TEXT NOT NULL DEFAULT '{}',
      data_quality_score REAL NOT NULL DEFAULT 0, safety_attention_score REAL NOT NULL DEFAULT 0,
      sleep_wellness_score REAL NOT NULL DEFAULT 0, morning_checkin_json TEXT,
      ai_analysis_json TEXT, ai_model TEXT, ai_generated_at TEXT, ai_request_fingerprint TEXT,
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
      FOREIGN KEY(session_id) REFERENCES $sessions(id) ON DELETE CASCADE
    )''',
    '''CREATE INDEX IF NOT EXISTS idx_sleep_safety_analysis_user_created ON $analyses(user_id, created_at DESC)''',
    '''CREATE INDEX IF NOT EXISTS idx_sleep_safety_analysis_user_ai ON $analyses(user_id, ai_generated_at DESC)''',
  ];

  static const schema = <String>[
    '''CREATE TABLE IF NOT EXISTS $preferences (
      user_id TEXT PRIMARY KEY, enabled INTEGER NOT NULL DEFAULT 1,
      sensitivity TEXT NOT NULL DEFAULT 'balanced', schedule_enabled INTEGER NOT NULL DEFAULT 0,
      schedule_start_minutes INTEGER NOT NULL DEFAULT 1350, schedule_end_minutes INTEGER NOT NULL DEFAULT 390,
      timezone TEXT NOT NULL DEFAULT 'Asia/Ho_Chi_Minh', selected_weekdays_json TEXT NOT NULL DEFAULT '[1,2,3,4,5,6,7]',
      calibration_required INTEGER NOT NULL DEFAULT 1, calibration_noise_floor REAL, calibration_updated_at TEXT,
      cooldown_seconds INTEGER NOT NULL DEFAULT 120, consent_version TEXT NOT NULL DEFAULT 'sleep-safety-v1', updated_at TEXT NOT NULL
    )''',
    '''CREATE TABLE IF NOT EXISTS $sessions (
      id TEXT PRIMARY KEY, user_id TEXT NOT NULL, started_at TEXT NOT NULL, ended_at TEXT,
      scheduled_window_start TEXT, scheduled_window_end TEXT, sensitivity TEXT NOT NULL,
      calibration_noise_floor REAL, status TEXT NOT NULL, start_source TEXT NOT NULL, stop_reason TEXT,
      platform TEXT NOT NULL, app_version TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )''',
    '''CREATE TABLE IF NOT EXISTS $events (
      id TEXT PRIMARY KEY, session_id TEXT NOT NULL, user_id TEXT NOT NULL, detected_at TEXT NOT NULL,
      event_type TEXT NOT NULL, severity TEXT NOT NULL, confidence REAL NOT NULL, relative_energy REAL NOT NULL,
      baseline_delta REAL NOT NULL, repetition_count INTEGER NOT NULL DEFAULT 1, state TEXT NOT NULL,
      response TEXT NOT NULL DEFAULT 'none', response_at TEXT, escalation_required INTEGER NOT NULL DEFAULT 0,
      escalation_status TEXT NOT NULL DEFAULT 'notRequired', created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
      FOREIGN KEY(session_id) REFERENCES $sessions(id) ON DELETE CASCADE
    )''',
    '''CREATE TABLE IF NOT EXISTS $contacts (
      id TEXT PRIMARY KEY, user_id TEXT NOT NULL, name TEXT NOT NULL, relationship TEXT NOT NULL,
      phone_e164 TEXT NOT NULL, priority INTEGER NOT NULL CHECK (priority BETWEEN 1 AND 3),
      verification_status TEXT NOT NULL, verified_at TEXT, active INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL, UNIQUE(user_id, priority), UNIQUE(user_id, phone_e164)
    )''',
    '''CREATE TABLE IF NOT EXISTS $outbox (
      id TEXT PRIMARY KEY, user_id TEXT NOT NULL, event_id TEXT, kind TEXT NOT NULL, payload_json TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','sending','failed','acknowledged')),
      attempt_count INTEGER NOT NULL DEFAULT 0, next_retry_at TEXT, last_error_code TEXT,
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )''',
    ...analysisSchema,
    '''CREATE INDEX IF NOT EXISTS idx_sleep_safety_sessions_user_started ON $sessions(user_id, started_at DESC)''',
    '''CREATE INDEX IF NOT EXISTS idx_sleep_safety_events_user_detected ON $events(user_id, detected_at DESC)''',
    '''CREATE INDEX IF NOT EXISTS idx_sleep_safety_outbox_status_due ON $outbox(status, next_retry_at, created_at)''',
  ];

  static Future<void> create(DatabaseExecutor db) async {
    for (final statement in schema) {
      await db.execute(statement);
    }
  }

  static Future<void> createAnalysis(DatabaseExecutor db) async {
    for (final statement in analysisSchema) {
      await db.execute(statement);
    }
  }
}
