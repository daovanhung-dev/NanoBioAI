import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Supabase single-file rebuild config', () {
    late String sql;

    setUpAll(() {
      sql = File('docs/supabase/config.sql').readAsStringSync();
    });

    test('is destructive sandbox rebuild entrypoint with auth wipe', () {
      expect(sql, contains('DESTRUCTIVE LOCAL/SANDBOX SCRIPT ONLY'));
      expect(sql, contains("truncate table auth.users cascade"));
      expect(sql, contains('drop schema if exists public cascade'));
      expect(sql, contains('create schema public'));
      expect(sql, contains('Flutter anon/authenticated clients'));
    });

    test('declares app tables and RPCs used by Flutter clients', () {
      for (final token in [
        'create table if not exists public.users',
        'create table if not exists public.health_subjects',
        'create table if not exists public.health_profiles',
        'create table if not exists public.meal_plans',
        'create table if not exists public.personal_schedule_ai_requests',
        'create table if not exists public.membership_plans',
        'create table if not exists public.family_groups',
        'create table if not exists public.family_members',
        'create table if not exists public.sale_profiles',
        'create table if not exists public.payment_events',
        'create table if not exists public.commission_records',
        'create table if not exists public.health_score_ledgers',
        'create table if not exists public.wellness_point_ledgers',
        'idx_wellness_point_ledgers_source',
        "'health_score_ledgers'",
        "'wellness_point_ledgers'",
        'create table if not exists public.admin_roles',
        'create table if not exists public.admin_audit_events',
        'create table if not exists public.sale_point_conversions',
        'create table if not exists public.sale_payout_profiles',
        'create table if not exists public.sale_point_adjustments',
        'create table if not exists public.admin_reconciliation_discrepancies',
        'sync_my_mobile_snapshot',
        'check_usage_quota',
        'commit_usage_quota',
        'check_personal_schedule_generation_quota',
        'commit_personal_schedule_generation_quota',
        'get_my_familyplus_context',
        'upsert_my_familyplus_group',
        'upsert_my_familyplus_member',
        'remove_my_familyplus_member',
        'get_my_sale_state',
        'request_sale_participation',
        'attach_my_referral_code',
        'get_my_sale_payout_profile',
        'upsert_my_sale_payout_profile',
        'get_my_sale_dashboard',
        'get_my_sale_direct_customers',
        'get_my_sale_point_ledger',
        'get_my_sale_conversions',
        'request_sale_point_conversion',
        'create_membership_payment_request',
        'get_my_admin_session',
        'get_admin_dashboard_summary',
        'admin_search_users',
        'admin_review_payment',
        'admin_refund_or_cancel_payment',
        'admin_review_sale_profile',
        'admin_adjust_sale_points',
        'admin_list_report_catalog',
        'admin_list_reconciliation_discrepancies',
        'admin_update_reconciliation_discrepancy_status',
        'admin_list_audit_events',
      ]) {
        expect(sql, contains(token), reason: token);
      }
    });

    test('keeps final Sale module behavior pending until Admin approval', () {
      expect(
        RegExp(
          r'create or replace function public\.request_sale_participation',
        ).allMatches(sql),
        hasLength(1),
      );
      expect(sql, contains("'Da gui yeu cau Sale; dang cho Admin duyet.'"));
      expect(sql, contains("status = 'pending'"));
      expect(sql, contains("'NANO-'"));
      expect(sql, isNot(contains("'Nabi-'")));
      expect(sql, contains('public.admin_assert_permission'));
      expect(sql, contains('SALE_REQUIRES_ACTIVE_PAID_PLAN'));
      expect(sql, contains('payout_profile_complete'));
    });

    test('seeds reference data, dev users and super admin bootstrap', () {
      for (final token in [
        "('direct_referral', 0.1000, true)",
        'dev.free@nanobio.local',
        'dev.plus@nanobio.local',
        'dev.family@nanobio.local',
        'dev.admin@nanobio.local',
        'NanoBio@123456',
        'bootstrap_admin_by_email',
        "select public.bootstrap_admin_by_email('dev.admin@nanobio.local', 'super_admin')",
      ]) {
        expect(sql, contains(token), reason: token);
      }
    });

    test('keeps dev auth seed token columns non-null for Supabase login', () {
      for (final token in [
        'confirmation_token',
        'recovery_token',
        'email_change',
        'email_change_token_new',
        'email_change_token_current',
        'phone_change',
        'phone_change_token',
        'reauthentication_token',
        'update auth.users',
        "raise exception 'DEV_AUTH_SEED_TOKEN_COLUMNS_NULL'",
      ]) {
        expect(sql, contains(token), reason: token);
      }
    });

    test('does not grant trusted payment recorder to Flutter roles', () {
      expect(sql, contains('record_trusted_payment_event'));
      expect(sql, contains('p_auto_approve boolean default false'));
      expect(sql, contains('p_list_price_cents integer default null'));
      expect(sql, contains('p_commission_base_cents integer default null'));
      expect(sql, contains("'manual_approval_required'"));
      expect(
        sql,
        contains('from public, anon, authenticated'),
        reason: 'Trusted payment recorder must not be granted to Flutter.',
      );
    });

    test('keeps Admin full-access policy in rebuild file', () {
      for (final token in [
        "('super_admin', '*')",
        "('finance_admin', '*')",
        "('support_admin', '*')",
        "('content_admin', '*')",
        "('operations_admin', '*')",
        "'reconciliation.write'",
        "'points.write'",
        "when p_config_key ilike 'plan%' then 'plans.write'",
        "perform public.admin_assert_permission('config.write')",
      ]) {
        expect(sql, contains(token), reason: token);
      }
    });

    test('qualifies Admin dashboard summary filters in rebuild file', () {
      final block = _adminDashboardSummaryBlock(sql);

      for (final token in [
        'from public.payment_events pe',
        "where pe.status = 'pending'",
        'and pe.created_at between p_from and p_to',
        'from public.sale_profiles sp',
        "where sp.status = 'active'",
        "'onboarding_completed'",
        "'packages_active'",
        "'payments_succeeded'",
        "'revenue_succeeded'",
        "'familyplus_active'",
        "'admin_alerts'",
        'coalesce(sum(cr.amount_cents), 0)::integer',
        'from public.commission_records cr',
        "where cr.status in ('pending', 'approved')",
        'and cr.available_at <= now()',
        'and cr.created_at between p_from and p_to',
      ]) {
        expect(block, contains(token), reason: token);
      }

      expect(
        _hasUnqualifiedDashboardStatusFilter(block),
        isFalse,
        reason:
            'get_admin_dashboard_summary returns a status column, so source '
            'status filters must stay table-qualified in config.sql.',
      );
    });

    test('keeps selected Admin financial policies in rebuild file', () {
      for (final token in [
        'Asia/Ho_Chi_Minh',
        'create_sale_point_reversal_for_payment',
        'negative_adjustment_without_overwriting_commission',
        'commission_base_cents',
        'list_price_cents',
        "available_at timestamptz not null default (now() + interval '24 hours')",
        "available_at <= now()",
        "'approval_count_required'",
        "'manual_approval_required'",
        'manual_adjustment',
        'PAYMENT_REVERSAL_WINDOW_EXPIRED',
        "'grants_access_before_approval'",
        "'membership_payment_prices'",
        "'pending',",
      ]) {
        expect(sql, contains(token), reason: token);
      }
    });

    test('uses Vietnam timezone for quota rules and RPC boundaries', () {
      expect(sql, isNot(contains('Asia/Saigon')));
      for (final token in [
        "reset_timezone text not null default 'Asia/Ho_Chi_Minh'",
        "p_reset_timezone text default 'Asia/Ho_Chi_Minh'",
        "('free', 'ai_chat_message', 'day', 3, 'Asia/Ho_Chi_Minh', true)",
        "('free', 'personal_schedule_generation', 'month', 3, 'Asia/Ho_Chi_Minh', true)",
        "('plus', 'ai_chat_message', 'none', null, 'Asia/Ho_Chi_Minh', true)",
        "('plus', 'personal_schedule_generation', 'none', null, 'Asia/Ho_Chi_Minh', true)",
        "('family_plus', 'ai_chat_message', 'none', null, 'Asia/Ho_Chi_Minh', true)",
        "('family_plus', 'personal_schedule_generation', 'none', null, 'Asia/Ho_Chi_Minh', true)",
        'unique (user_id, feature_key, idempotency_key)',
        'on conflict (user_id, feature_key, idempotency_key) do nothing',
        'revoke insert, update, delete on',
        'public.usage_events',
      ]) {
        expect(sql, contains(token), reason: token);
      }
    });

    test('keeps FamilyPlus runtime RPC contract in rebuild file', () {
      for (final token in [
        'idx_family_groups_owner_active_unique',
        'assert_current_user_familyplus',
        'familyplus_context_for_user',
        "'self_subject_id'",
        "'has_family_plus'",
        'FAMILYPLUS_MEMBER_LIMIT',
        'last_idempotency_key',
        "ms.plan_code = 'family_plus'",
        'revoke insert, update, delete on public.family_groups, public.family_members',
        'grant execute on function public.get_my_familyplus_context()',
      ]) {
        expect(sql, contains(token), reason: token);
      }
    });

    test('keeps personal schedule request ledger in cloud sync contract', () {
      for (final token in [
        'create table if not exists public.personal_schedule_ai_requests',
        'idx_personal_schedule_ai_requests_user_mode',
        'personal_schedule_ai_requests_select_own',
        'revoke insert, update, delete on public.personal_schedule_ai_requests',
        'insert_mobile_snapshot_row',
        'jsonb_to_record(\$1)',
        "coalesce(v_tables -> 'personal_schedule_ai_requests', '[]'::jsonb)",
        "'personal_schedule_ai_requests',",
        'false',
      ]) {
        expect(sql, contains(token), reason: token);
      }
    });

    test('keeps personal schedule quota wrapper strict and idempotent', () {
      final source = File(
        'lib/app_versions/v1/services/ai/personal_schedule_quota_gateway.dart',
      ).readAsStringSync();

      for (final token in [
        "'p_request_id': requestId",
        "'p_reset_timezone': resetTimezone",
        "'p_committed_at': at.toUtc().toIso8601String()",
        "row['allowed'] ?? row['committed']",
        'PersonalScheduleQuotaExceededException(resetAt: decision.resetAt)',
      ]) {
        expect(source, contains(token), reason: token);
      }
    });

    test('does not reintroduce second-level commission markers', () {
      for (final token in [
        'secondLevel',
        'second-level',
        'second_level',
        '0.0500',
        'level = 2',
        '5% tang 2',
      ]) {
        expect(sql, isNot(contains(token)), reason: token);
      }
    });
  });

  group('Codex Supabase context rules', () {
    test(
      'require reading docs/supabase and updating config for DB changes',
      () {
        final sources = [
          File('.codex/AGENTS.md').readAsStringSync(),
          File('.codex/PROJECT_MAP.md').readAsStringSync(),
          File('.codex/workflows/supabase-schema.md').readAsStringSync(),
        ].join('\n');

        for (final token in [
          'docs/supabase/README.md',
          'docs/supabase/config.sql',
          'directly related',
          'schema/RLS/RPC/seed',
          'rebuild-ready',
        ]) {
          expect(sources, contains(token), reason: token);
        }
      },
    );
  });
}

String _adminDashboardSummaryBlock(String sql) {
  const startToken =
      'create or replace function public.get_admin_dashboard_summary';
  const endToken = 'create or replace function public.admin_search_users';
  final start = sql.indexOf(startToken);
  final end = sql.indexOf(endToken, start);
  if (start < 0 || end < 0) {
    throw StateError('Cannot locate Admin dashboard summary SQL block.');
  }
  return sql.substring(start, end);
}

bool _hasUnqualifiedDashboardStatusFilter(String block) {
  final withoutLineComments = block.replaceAll(RegExp(r'--.*'), '');
  return RegExp(
    r'(\bwhere|\band|\bfilter\s*\(\s*where)\s+status\b',
    caseSensitive: false,
  ).hasMatch(withoutLineComments);
}
