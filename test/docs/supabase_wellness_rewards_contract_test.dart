import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Supabase wellness rewards migration 16', () {
    late String migration;
    late String config;

    setUpAll(() {
      migration = File(
        'docs/supabase/16-wellness-rewards.sql',
      ).readAsStringSync();
      config = File('docs/supabase/config.sql').readAsStringSync();
    });

    test('is folded into the destructive rebuild config exactly once', () {
      expect(config.split('-- BEGIN 16-wellness-rewards.sql').length - 1, 1);
      expect(config.split('-- END 16-wellness-rewards.sql').length - 1, 1);
      final embedded = _between(
        config,
        '-- BEGIN 16-wellness-rewards.sql',
        '-- END 16-wellness-rewards.sql',
      ).trim();
      expect(embedded, migration.trim());
    });

    test('declares server-owned proof, wallet and voucher tables', () {
      for (final token in [
        'create table if not exists public.guest_schedule_reward_registrations',
        'create table if not exists public.member_schedule_reward_registrations',
        'create table if not exists public.schedule_reward_eligibilities',
        'create table if not exists public.schedule_completion_attempts',
        'create table if not exists public.schedule_completion_proofs',
        'create table if not exists public.wellness_reward_wallets',
        'create table if not exists public.wellness_point_allocations',
        'create table if not exists public.wellness_reward_offers',
        'create table if not exists public.wellness_reward_codes',
        'create table if not exists public.wellness_reward_redemptions',
        'create table if not exists public.wellness_redemption_allocation_usages',
        'wellness_ledger_append_only',
      ]) {
        expect(migration, contains(token), reason: token);
        expect(config, contains(token), reason: 'config.sql: $token');
      }
    });

    test('keeps exact Flutter RPC names and stable schedule contracts', () {
      for (final token in [
        'register_my_schedule_reward_eligibilities',
        'begin_my_schedule_completion',
        'finalize_my_schedule_completion',
        'undo_my_schedule_completion',
        'get_my_wellness_reward_summary',
        'list_my_wellness_point_history',
        'list_my_reward_offers',
        'redeem_my_reward_offer',
        'list_my_reward_redemptions',
        'get_my_reward_code',
        "'storage_path', v_attempt.object_path",
        "'points_delta', v_allocation.original_points",
        "'points_delta', -v_allocation.original_points",
        "v_path := v_user_id::text || '/' || v_eligibility.id::text || '/' || v_attempt_id::text || '.jpg'",
        'v_request.schedule_item_count <> v_request.days * 10',
        'schedule_items_outside_request_range',
      ]) {
        expect(migration, contains(token), reason: token);
      }

      expect(
        _functionBlock(migration, 'begin_my_schedule_completion'),
        allOf(
          contains('p_schedule_item_id uuid'),
          contains("'window_end', v_eligibility.window_end"),
        ),
      );
      final finalize = _functionBlock(
        migration,
        'finalize_my_schedule_completion',
      );
      expect(finalize, contains('p_storage_path text'));
      expect(finalize, contains('storage_path_mismatch'));
      expect(
        finalize,
        contains("v_object.created_at >= v_eligibility.window_end"),
      );
      expect(
        _functionBlock(migration, 'undo_my_schedule_completion'),
        contains('p_schedule_item_id uuid'),
      );
    });

    test(
      'pins one Guest request while allowing only incomplete future subsets',
      () {
        final register = _functionBlock(
          migration,
          'register_my_schedule_reward_eligibilities',
        );
        for (final token in [
          "psar.actor_mode in ('member_new', 'initial_guest')",
          "v_request.actor_mode = 'member_new'",
          "ue.feature_key = 'personal_schedule_generation'",
          "'wellness:guest-register:' || v_user_id::text",
          "'wellness:register-request:' || btrim(p_request_id)",
          'from public.guest_schedule_reward_registrations gsrr',
          'guest_schedule_request_already_registered',
          'guest_schedule_request_ambiguous',
          'guest_schedule_request_changed',
          'guest_schedule_request_claimed',
          'guest_schedule_plan_invalid',
          'guest_schedule_item_not_in_pinned_plan',
          'v_full_item_count <> v_request.schedule_item_count',
          'v_guest_marker.manifest_hash <> v_full_manifest_hash',
          'jsonb_build_array(',
          'v_guest_marker.eligible_item_ids',
          '= any(v_guest_eligible_item_ids)',
          'count(distinct lsi.start_time) <> 10',
          'where lsi.is_completed = false',
          'and lsi.ai_generated = true',
          'schedule_window_must_be_future',
          "on conflict (user_id) do nothing",
        ]) {
          expect(register, contains(token), reason: token);
        }

        expect(
          migration,
          contains(
            'alter table public.guest_schedule_reward_registrations enable row level security',
          ),
        );
        expect(
          migration,
          isNot(
            contains(
              'grant select on public.guest_schedule_reward_registrations',
            ),
          ),
        );
      },
    );

    test('pins one immutable full manifest for every Member request', () {
      final register = _functionBlock(
        migration,
        'register_my_schedule_reward_eligibilities',
      );
      for (final token in [
        'public.member_schedule_reward_registrations%rowtype',
        "digest(string_agg(parsed.schedule_item_id::text",
        "'wellness:register-request:' || btrim(p_request_id)",
        'member_schedule_request_already_registered',
        'member_schedule_request_claimed',
        'member_schedule_plan_invalid',
        'member_schedule_manifest_mismatch',
        'member_schedule_manifest_incomplete',
        'schedule_request_eligibility_limit_exceeded',
        'v_manifest_hash <> v_full_item_id_hash',
        'v_request_eligible_count <> v_request.schedule_item_count',
      ]) {
        expect(register, contains(token), reason: token);
      }
      expect(
        migration,
        contains(
          'alter table public.member_schedule_reward_registrations enable row level security',
        ),
      );
      expect(
        migration,
        isNot(
          contains(
            'grant select on public.member_schedule_reward_registrations',
          ),
        ),
      );
    });

    test('uses private JPEG-only Storage without client update/delete', () {
      for (final token in [
        "'schedule-completion-proofs'",
        '5242880',
        "array['image/jpeg']::text[]",
        'schedule_completion_proofs_storage_select_own',
        'schedule_completion_proofs_storage_insert_own',
        'split_part(name, \'/\', 1) = auth.uid()::text',
        'drop policy if exists schedule_completion_proofs_storage_update_own',
        'drop policy if exists schedule_completion_proofs_storage_delete_own',
      ]) {
        expect(migration, contains(token), reason: token);
      }
      expect(
        migration,
        isNot(
          contains('create policy schedule_completion_proofs_storage_update'),
        ),
      );
      expect(
        migration,
        isNot(
          contains('create policy schedule_completion_proofs_storage_delete'),
        ),
      );
    });

    test('removes wellness ledger from snapshot push/delete whitelist', () {
      final sync = _lastFunctionBlock(config, 'sync_my_mobile_snapshot');
      final collectionTables = _between(
        sync,
        'v_collection_tables text[] := array[',
        'v_singleton_tables text[]',
      );

      expect(collectionTables, isNot(contains('wellness_point_ledgers')));
      expect(sync, isNot(contains("elsif v_table = 'wellness_point_ledgers'")));
      expect(
        migration,
        contains(
          'revoke insert, update, delete on public.wellness_point_ledgers',
        ),
      );
      expect(migration, contains('wellness_point_ledgers_select_own'));
    });

    test('versions +10 pending/available points and 180-day expiry', () {
      for (final token in [
        "'reward_points', 10",
        "'expiry_days', 180",
        "'time_zone', 'Asia/Ho_Chi_Minh'",
        "window_end = window_start + interval '30 minutes'",
        "when now() >= v_eligibility.window_end then 'available'",
        'v_eligibility.window_end + make_interval(days => v_program.expiry_days)',
        "program_code = 'wellness_schedule_v1'",
        "program_code = 'wellness_schedule_legacy_v1'",
        'points_delta = points_delta * 10',
        'is_redeemable = false',
      ]) {
        expect(migration, contains(token), reason: token);
      }
    });

    test('keeps redemption atomic, earliest-expiry-first and idempotent', () {
      final redeem = _functionBlock(migration, 'redeem_my_reward_offer');
      for (final token in [
        'for update skip locked',
        'order by wpa.expires_at',
        'wallet_allocation_mismatch',
        'insufficient_points',
        'offer_out_of_stock',
        'unique (user_id, idempotency_key)',
        "status = 'issued'",
      ]) {
        expect(
          token == 'unique (user_id, idempotency_key)' ? migration : redeem,
          contains(token),
          reason: token,
        );
      }
      expect(
        RegExp('pg_advisory_xact_lock').allMatches(migration).length,
        greaterThanOrEqualTo(8),
      );
      expect(
        migration,
        contains(
          'create unique index if not exists idx_wellness_reward_codes_global_hash',
        ),
      );
      expect(migration, contains('on conflict (code_hash) do nothing'));
    });

    test(
      'keeps exact Admin RPCs, permissions, refund and safe inventory audit',
      () {
        for (final token in [
          'admin_list_wellness_rewards',
          'admin_upsert_reward_offer',
          'admin_import_reward_codes',
          'admin_cancel_reward_redemption',
          "'wellness_rewards.read'",
          "'wellness_rewards.write'",
          "'raw_codes_logged', false",
          'external_revocation_confirmation_required',
          "'code_restocked', false",
          "'admin_refund'",
          'current_wellness_reward_program',
          'invalid_vietnamese_copy',
        ]) {
          expect(migration, contains(token), reason: token);
        }
        final list = _functionBlock(migration, 'admin_list_wellness_rewards');
        expect(list, contains("'offer'::text as item_type"));
        expect(list, contains("'redemption'::text as item_type"));
        expect(list, contains("'••••••'::text as masked_code"));
        expect(list, isNot(contains('code_value')));
      },
    );

    test('documents Storage, RLS and sandbox acceptance', () {
      final readme = File('docs/supabase/README.md').readAsStringSync();
      final storage = File(
        'docs/supabase/16-schedule-proof-storage.md',
      ).readAsStringSync();
      final matrix = File(
        'docs/supabase/06-rls-policy-matrix.md',
      ).readAsStringSync();
      final acceptance = File(
        'docs/supabase/08-acceptance-checks.md',
      ).readAsStringSync();
      final adversarial = File(
        'test/docs/fixtures/supabase_wellness_rewards_adversarial.sql',
      ).readAsStringSync();

      expect(readme, contains('16-wellness-rewards.sql'));
      expect(readme, contains('16-schedule-proof-storage.md'));
      expect(storage, contains('upsert: false'));
      expect(storage, contains('User B'));
      expect(matrix, contains('wellness_rewards.read/write'));
      expect(acceptance, contains('FOR UPDATE SKIP LOCKED'));
      for (final token in [
        'MEMBER_SECOND_BATCH_ACCEPTED',
        'MUTATED_GUEST_PLAN_ACCEPTED',
        'SECOND_GUEST_REQUEST_ACCEPTED',
        'GUEST_MARKER_READ_ALLOWED',
        'MEMBER_MARKER_READ_ALLOWED',
        'GLOBAL_CODE_DUPLICATE_ACCEPTED',
        'rollback;',
      ]) {
        expect(adversarial, contains(token), reason: token);
      }
      expect(
        acceptance,
        contains('PENDING'),
        reason: 'Sandbox is not run here.',
      );
    });
  });
}

String _functionBlock(String sql, String functionName) {
  final start = sql.indexOf('create or replace function public.$functionName');
  if (start < 0) throw StateError('Missing function $functionName');
  final end = sql.indexOf('\n\$\$;', start);
  if (end < 0) throw StateError('Missing function end $functionName');
  return sql.substring(start, end);
}

String _lastFunctionBlock(String sql, String functionName) {
  final start = sql.lastIndexOf(
    'create or replace function public.$functionName',
  );
  if (start < 0) throw StateError('Missing function $functionName');
  final end = sql.indexOf('\n\$\$;', start);
  if (end < 0) throw StateError('Missing function end $functionName');
  return sql.substring(start, end);
}

String _between(String source, String startToken, String endToken) {
  final start = source.indexOf(startToken);
  final end = source.indexOf(endToken, start + startToken.length);
  if (start < 0 || end < 0) {
    throw StateError('Cannot locate block: $startToken -> $endToken');
  }
  return source.substring(start + startToken.length, end);
}
