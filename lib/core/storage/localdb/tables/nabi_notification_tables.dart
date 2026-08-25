import 'package:sqflite/sqflite.dart';

/// Local-first M30 storage. These tables are deliberately separate from the
/// legacy `notifications` table owned by M09 schedule reminders.
abstract final class NabiNotificationTables {
  static const definitions = 'nabi_notification_definitions_cache';
  static const occurrences = 'nabi_notification_occurrences';
  static const eventOutbox = 'nabi_notification_event_outbox';
  static const preferences = 'nabi_notification_preferences';
  static const carePreferences = 'nabi_health_reminder_preferences';
  static const careSchedules = 'nabi_health_reminder_schedules';

  static const createDefinitions = '''
CREATE TABLE IF NOT EXISTS $definitions (
  notification_id TEXT NOT NULL,
  content_version INTEGER NOT NULL,
  definition_json TEXT NOT NULL,
  effective_from TEXT,
  effective_until TEXT,
  is_active INTEGER NOT NULL DEFAULT 0,
  fetched_at TEXT NOT NULL,
  PRIMARY KEY (notification_id, content_version)
)
''';

  static const createOccurrences = '''
CREATE TABLE IF NOT EXISTS $occurrences (
  id TEXT PRIMARY KEY,
  actor_key TEXT NOT NULL,
  user_id TEXT,
  notification_id TEXT NOT NULL,
  content_version INTEGER NOT NULL,
  source_event_id TEXT NOT NULL,
  source_type TEXT NOT NULL,
  category TEXT NOT NULL,
  priority INTEGER NOT NULL,
  status TEXT NOT NULL CHECK (status IN (
    'eligible', 'queued', 'presented', 'collapsed', 'opened', 'deferred',
    'actioned', 'converted', 'expired', 'cancelled', 'failed'
  )),
  eligible_at TEXT NOT NULL,
  presented_at TEXT,
  opened_at TEXT,
  deferred_until TEXT,
  actioned_at TEXT,
  converted_at TEXT,
  expires_at TEXT,
  last_error_code TEXT,
  display_count INTEGER NOT NULL DEFAULT 0,
  dismiss_count INTEGER NOT NULL DEFAULT 0,
  primary_click_count INTEGER NOT NULL DEFAULT 0,
  secondary_click_count INTEGER NOT NULL DEFAULT 0,
  session_id TEXT,
  screen_instance_id TEXT,
  membership_plan TEXT,
  billing_cycle TEXT,
  snapshot_json TEXT NOT NULL DEFAULT '{}',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  UNIQUE (actor_key, notification_id, source_event_id, content_version)
)
''';

  static const createEventOutbox = '''
CREATE TABLE IF NOT EXISTS $eventOutbox (
  id TEXT PRIMARY KEY,
  occurrence_id TEXT,
  actor_key TEXT NOT NULL,
  user_id TEXT,
  event_name TEXT NOT NULL,
  event_json TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'sending', 'failed', 'acknowledged')),
  attempt_count INTEGER NOT NULL DEFAULT 0,
  next_retry_at TEXT,
  last_error_code TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''';

  static const createPreferences = '''
CREATE TABLE IF NOT EXISTS $preferences (
  actor_key TEXT PRIMARY KEY,
  user_id TEXT,
  proactive_in_app_enabled INTEGER NOT NULL DEFAULT 1,
  push_enabled INTEGER NOT NULL DEFAULT 0,
  analytics_upload_enabled INTEGER NOT NULL DEFAULT 0,
  quiet_start_minutes INTEGER,
  quiet_end_minutes INTEGER,
  last_session_id TEXT,
  last_background_at TEXT,
  updated_at TEXT NOT NULL
)
''';

  /// Additive local preferences for health-care reminders. New reminder
  /// categories intentionally default OFF so existing installs are not spammed
  /// after upgrade. The legacy M09 schedule-reminder preference remains owned by
  /// Settings/M09 and is only mirrored as [master_enabled] at first load.
  static const createCarePreferences = '''
CREATE TABLE IF NOT EXISTS $carePreferences (
  actor_key TEXT PRIMARY KEY,
  master_enabled INTEGER NOT NULL DEFAULT 0,
  schedule_enabled INTEGER NOT NULL DEFAULT 1,
  health_check_in_enabled INTEGER NOT NULL DEFAULT 0,
  health_check_in_interval_minutes INTEGER NOT NULL DEFAULT 60,
  health_check_in_start_minutes INTEGER NOT NULL DEFAULT 480,
  health_check_in_end_minutes INTEGER NOT NULL DEFAULT 1260,
  goal_review_enabled INTEGER NOT NULL DEFAULT 0,
  goal_review_minutes INTEGER NOT NULL DEFAULT 540,
  profile_review_enabled INTEGER NOT NULL DEFAULT 0,
  profile_review_interval_days INTEGER NOT NULL DEFAULT 30,
  profile_review_minutes INTEGER NOT NULL DEFAULT 540,
  water_reminder_enabled INTEGER NOT NULL DEFAULT 0,
  water_reminder_interval_minutes INTEGER NOT NULL DEFAULT 120,
  water_reminder_start_minutes INTEGER NOT NULL DEFAULT 480,
  water_reminder_end_minutes INTEGER NOT NULL DEFAULT 1200,
  voice_enabled INTEGER NOT NULL DEFAULT 0,
  use_personal_quiet_hours INTEGER NOT NULL DEFAULT 1,
  fallback_quiet_start_minutes INTEGER NOT NULL DEFAULT 1260,
  fallback_quiet_end_minutes INTEGER NOT NULL DEFAULT 420,
  last_goal_review_period TEXT,
  last_profile_reviewed_at TEXT,
  last_health_check_in_at TEXT,
  updated_at TEXT NOT NULL,
  CHECK (health_check_in_interval_minutes BETWEEN 60 AND 240),
  CHECK (water_reminder_interval_minutes BETWEEN 60 AND 360),
  CHECK (profile_review_interval_days BETWEEN 7 AND 180),
  CHECK (health_check_in_start_minutes BETWEEN 0 AND 1439),
  CHECK (health_check_in_end_minutes BETWEEN 0 AND 1439),
  CHECK (goal_review_minutes BETWEEN 0 AND 1439),
  CHECK (profile_review_minutes BETWEEN 0 AND 1439),
  CHECK (water_reminder_start_minutes BETWEEN 0 AND 1439),
  CHECK (water_reminder_end_minutes BETWEEN 0 AND 1439),
  CHECK (fallback_quiet_start_minutes BETWEEN 0 AND 1439),
  CHECK (fallback_quiet_end_minutes BETWEEN 0 AND 1439)
)
''';

  /// Reconciliation state for OS notifications owned by the health-care delta.
  /// Keeping it separate from [occurrences] avoids changing the Approved M30
  /// occurrence schema on existing v22 databases while still preserving one
  /// opaque occurrence id in the native payload.
  static const createCareSchedules = '''
CREATE TABLE IF NOT EXISTS $careSchedules (
  occurrence_id TEXT PRIMARY KEY,
  actor_key TEXT NOT NULL,
  category TEXT NOT NULL,
  source_event_id TEXT NOT NULL,
  native_notification_id INTEGER NOT NULL,
  scheduled_at TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'queued'
    CHECK (status IN ('queued', 'opened', 'deferred', 'cancelled', 'failed')),
  deferred_until TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  UNIQUE (actor_key, category, source_event_id)
)
''';

  static const schema = <String>[
    createDefinitions,
    createOccurrences,
    createEventOutbox,
    createPreferences,
    createCarePreferences,
    createCareSchedules,
    '''CREATE INDEX IF NOT EXISTS idx_nabi_occurrence_actor_status_priority
       ON $occurrences(actor_key, status, priority DESC, eligible_at ASC)''',
    '''CREATE INDEX IF NOT EXISTS idx_nabi_occurrence_actor_notification_time
       ON $occurrences(actor_key, notification_id, presented_at DESC)''',
    '''CREATE INDEX IF NOT EXISTS idx_nabi_event_outbox_status_due
       ON $eventOutbox(status, next_retry_at, created_at)''',
    '''CREATE INDEX IF NOT EXISTS idx_nabi_care_schedule_actor_status_time
       ON $careSchedules(actor_key, status, scheduled_at)''',
    '''CREATE INDEX IF NOT EXISTS idx_nabi_care_schedule_native_id
       ON $careSchedules(native_notification_id)''',
  ];

  static Future<void> create(Database db) async {
    for (final statement in schema) {
      await db.execute(statement);
    }
  }

  /// v22 compatibility bridge for the 2026-08-24 additive reminder delta.
  /// The repository calls this before every preferences/schedule access, so an
  /// existing install can adopt the new tables without destructive migration.
  static Future<void> ensureHealthReminderSchema(Database db) async {
    await db.execute(createCarePreferences);
    await db.execute(createCareSchedules);
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_nabi_care_schedule_actor_status_time '
      'ON $careSchedules(actor_key, status, scheduled_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_nabi_care_schedule_native_id '
      'ON $careSchedules(native_notification_id)',
    );
  }
}
