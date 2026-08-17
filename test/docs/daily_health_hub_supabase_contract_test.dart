import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String sql;

  setUpAll(() {
    sql = File(
      'docs/supabase/20260816_daily_health_hub_rewards.sql',
    ).readAsStringSync();
  });

  test('daily health rewards stay server-authoritative and weighted', () {
    expect(sql, contains('finalize_my_schedule_health_checkin'));
    expect(sql, contains('undo_my_schedule_health_checkin'));
    expect(sql, contains("when 'hydration' then 4"));
    expect(sql, contains("when 'mood_stress' then 5"));
    expect(sql, contains("when 'sleep_checkin' then 6"));
    expect(sql, contains("when 'weight_checkin' then 4"));
    expect(sql, contains("when 'quick_complete' then 5"));
    expect(sql, contains('manual_reward_daily_limit'));
    expect(sql, contains('v_manual_count >= 4'));
    expect(sql, contains("v_item.source_type in ('meal_plan', 'exercise_task')"));
    expect(sql, contains('photo_proof_required'));
    expect(sql, contains('security definer'));
    expect(
      sql,
      contains('grant select on public.schedule_health_checkins to authenticated'),
    );
    expect(
      sql,
      isNot(
        contains(
          'grant insert on public.schedule_health_checkins to authenticated',
        ),
      ),
    );
  });

  test('manual tasks never mint generated schedule eligibility', () {
    expect(sql, contains('eligibility_id uuid unique'));
    expect(sql, contains('alter column eligibility_id drop not null'));
    expect(
      sql,
      contains("v_item.source_type <> 'manual_health_task'"),
    );
    expect(
      sql,
      contains("then null else v_eligibility.id end"),
    );
    expect(
      sql,
      isNot(
        contains(
          "'manual:' || v_item.id::text",
        ),
      ),
    );
  });

  test('structured check-ins do not weaken JPEG proof contract', () {
    expect(sql, isNot(contains('schedule_completion_proofs_content_type_check')));
    expect(sql, isNot(contains('application/vnd.nanobio.health-checkin')));
    expect(sql, isNot(contains('insert into public.schedule_completion_proofs')));
    expect(sql, isNot(contains('insert into public.schedule_completion_attempts')));
  });

  test('mobile snapshot wrapper overlays structured server evidence', () {
    expect(
      sql,
      contains('sync_my_mobile_snapshot_before_daily_health_hub'),
    );
    expect(sql, contains('rename to sync_my_mobile_snapshot_before_daily_health_hub'));
    expect(sql, contains("shc.source_type_snapshot = 'manual_health_task'"));
    expect(sql, contains("is_completed = (l.status = 'active')"));
    expect(sql, contains("'daily_health_hub_overlay'"));
    expect(
      sql,
      contains(
        'revoke all on function public.sync_my_mobile_snapshot_before_daily_health_hub(jsonb)',
      ),
    );
  });

  test('reward RPC leaves health metrics local-first', () {
    expect(sql, isNot(contains('insert into public.health_tracking_logs')));
    expect(sql, contains('user-data outbox'));
  });
}
