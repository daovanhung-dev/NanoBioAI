import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'rank migration records server-owned EXP and private summary contract',
    () {
      final migration = File(
        'supabase/migrations/20261015090000_wellness_rank_experience.sql',
      ).readAsStringSync();
      final canonical = File(
        'docs/supabase/01_build_system.sql',
      ).readAsStringSync();

      expect(canonical, contains(migration.trim()));
      expect(migration, contains("experience_points >= 5200 then 5"));
      expect(migration, contains("experience_points >= 2600 then 4"));
      expect(migration, contains("experience_points >= 1200 then 3"));
      expect(migration, contains("experience_points >= 600 then 2"));
      expect(migration, contains("interval '7 days'"));
      expect(migration, contains('least(v_account.experience_points, 100)'));
      expect(migration, contains('unique (user_id, event_key)'));
      expect(migration, contains('trg_rank_from_schedule_completion_proofs'));
      expect(migration, contains('trg_rank_from_schedule_health_checkins'));
      expect(migration, contains('auth.uid()'));
      expect(migration, contains('get_my_wellness_rank_summary()'));
      expect(
        migration,
        contains(
          'create or replace function public.get_my_wellness_rank_summary()',
        ),
      );
      expect(migration, contains('enable row level security'));
      expect(migration, isNot(contains('wellness_reward_wallets')));
    },
  );
}
