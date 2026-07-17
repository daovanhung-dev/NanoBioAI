import 'package:sqflite/sqflite.dart';

/// Local-first M30 storage. These tables are deliberately separate from the
/// legacy `notifications` table owned by M09 schedule reminders.
abstract final class NabiNotificationTables {
  static const definitions = 'nabi_notification_definitions_cache';
  static const occurrences = 'nabi_notification_occurrences';
  static const eventOutbox = 'nabi_notification_event_outbox';
  static const preferences = 'nabi_notification_preferences';

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

  static const schema = <String>[
    createDefinitions,
    createOccurrences,
    createEventOutbox,
    createPreferences,
    '''CREATE INDEX IF NOT EXISTS idx_nabi_occurrence_actor_status_priority
       ON $occurrences(actor_key, status, priority DESC, eligible_at ASC)''',
    '''CREATE INDEX IF NOT EXISTS idx_nabi_occurrence_actor_notification_time
       ON $occurrences(actor_key, notification_id, presented_at DESC)''',
    '''CREATE INDEX IF NOT EXISTS idx_nabi_event_outbox_status_due
       ON $eventOutbox(status, next_retry_at, created_at)''',
  ];

  static Future<void> create(Database db) async {
    for (final statement in schema) {
      await db.execute(statement);
    }
  }
}
