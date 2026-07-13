class ScheduleRewardEligibilityCacheTable {
  static const tableName = 'schedule_reward_eligibility_cache';

  static const createTable =
      '''
  CREATE TABLE IF NOT EXISTS $tableName (
    schedule_item_id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    eligibility_id TEXT,
    request_id TEXT,
    status TEXT NOT NULL DEFAULT 'registered',
    window_start TEXT,
    window_end TEXT,
    synced_at TEXT NOT NULL
  )
  ''';

  static const createUserStatusIndex =
      '''
  CREATE INDEX IF NOT EXISTS idx_schedule_reward_eligibility_user_status
  ON $tableName(user_id, status, window_start)
  ''';

  static const createEligibilityIndex =
      '''
  CREATE UNIQUE INDEX IF NOT EXISTS idx_schedule_reward_eligibility_id
  ON $tableName(eligibility_id)
  WHERE eligibility_id IS NOT NULL AND TRIM(eligibility_id) != ''
  ''';
}

class WellnessRewardSummaryCacheTable {
  static const tableName = 'wellness_reward_summary_cache';

  static const createTable =
      '''
  CREATE TABLE IF NOT EXISTS $tableName (
    user_id TEXT PRIMARY KEY,
    pending_points INTEGER NOT NULL DEFAULT 0,
    available_points INTEGER NOT NULL DEFAULT 0,
    expiring_soon_points INTEGER NOT NULL DEFAULT 0,
    next_expiry_at TEXT,
    synced_at TEXT NOT NULL
  )
  ''';
}

class WellnessRewardOfferCacheTable {
  static const tableName = 'wellness_reward_offer_cache';

  static const createTable =
      '''
  CREATE TABLE IF NOT EXISTS $tableName (
    id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    provider_name TEXT NOT NULL,
    cost_points INTEGER NOT NULL,
    available_codes INTEGER NOT NULL DEFAULT 0,
    eligible_plan_codes TEXT NOT NULL DEFAULT '[]',
    available_from TEXT,
    available_until TEXT,
    voucher_expires_at TEXT,
    is_active INTEGER NOT NULL DEFAULT 1,
    synced_at TEXT NOT NULL,
    PRIMARY KEY(user_id, id)
  )
  ''';

  static const createUserIndex =
      '''
  CREATE INDEX IF NOT EXISTS idx_wellness_reward_offer_user
  ON $tableName(user_id, is_active, cost_points)
  ''';
}

class WellnessRewardPointHistoryCacheTable {
  static const tableName = 'wellness_reward_point_history_cache';

  static const createTable =
      '''
  CREATE TABLE IF NOT EXISTS $tableName (
    id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    points_delta INTEGER NOT NULL,
    event_type TEXT NOT NULL,
    status TEXT NOT NULL,
    title TEXT NOT NULL,
    is_redeemable INTEGER NOT NULL DEFAULT 1,
    available_at TEXT,
    expires_at TEXT,
    created_at TEXT,
    synced_at TEXT NOT NULL,
    PRIMARY KEY(user_id, id)
  )
  ''';

  static const createUserDateIndex =
      '''
  CREATE INDEX IF NOT EXISTS idx_wellness_reward_history_user_date
  ON $tableName(user_id, created_at DESC)
  ''';
}

class WellnessRewardRedemptionCacheTable {
  static const tableName = 'wellness_reward_redemption_cache';

  static const createTable =
      '''
  CREATE TABLE IF NOT EXISTS $tableName (
    id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    offer_id TEXT NOT NULL,
    title TEXT NOT NULL,
    provider_name TEXT NOT NULL,
    points_spent INTEGER NOT NULL,
    status TEXT NOT NULL,
    voucher_expires_at TEXT,
    created_at TEXT,
    cancelled_at TEXT,
    synced_at TEXT NOT NULL,
    PRIMARY KEY(user_id, id)
  )
  ''';

  static const createUserDateIndex =
      '''
  CREATE INDEX IF NOT EXISTS idx_wellness_reward_redemption_user_date
  ON $tableName(user_id, created_at DESC)
  ''';
}

const wellnessRewardCacheSchema = <String>[
  ScheduleRewardEligibilityCacheTable.createTable,
  ScheduleRewardEligibilityCacheTable.createUserStatusIndex,
  ScheduleRewardEligibilityCacheTable.createEligibilityIndex,
  WellnessRewardSummaryCacheTable.createTable,
  WellnessRewardOfferCacheTable.createTable,
  WellnessRewardOfferCacheTable.createUserIndex,
  WellnessRewardPointHistoryCacheTable.createTable,
  WellnessRewardPointHistoryCacheTable.createUserDateIndex,
  WellnessRewardRedemptionCacheTable.createTable,
  WellnessRewardRedemptionCacheTable.createUserDateIndex,
];
