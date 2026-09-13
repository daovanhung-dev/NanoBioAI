import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _buildPath = 'docs/supabase/01_build_system.sql';
const _seedPath = 'docs/supabase/02_seed_data.sql';

void main() {
  group('Supabase Admin SQL contract', () {
    late String build;
    late String seed;

    setUpAll(() {
      build = File(_buildPath).readAsStringSync();
      seed = File(_seedPath).readAsStringSync();
    });

    test('keeps Auth V2 signup and referral validation atomic', () {
      for (final token in [
        'create or replace function public.handle_auth_user_created()',
        "new.raw_user_meta_data ->> 'referral_code'",
        "new.raw_user_meta_data ->> 'device_fingerprint'",
        "sp.status = 'active'",
        'invalid_referral_code',
        'referral_device_missing',
        'referral_collision',
        'referral_already_used',
        "'policy', 'direct_only'",
        'create trigger on_auth_user_created',
      ]) {
        expect(build, contains(token), reason: token);
      }

      final source = File(
        'lib/app_versions/v2/features/auth/data/datasources/supabase_auth_remote_datasource.dart',
      ).readAsStringSync();
      final registerPage = File(
        'lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart',
      ).readAsStringSync();
      expect(source, contains("'referral_code': referralCode"));
      expect(source, contains("'device_fingerprint': deviceFingerprint"));
      expect(registerPage, isNot(contains('attach_my_referral_code')));
    });

    test('declares Admin tables and RPCs used by Flutter Admin', () {
      for (final token in [
        'create table if not exists public.admin_roles',
        'create table if not exists public.admin_permissions',
        'create table if not exists public.admin_user_roles',
        'create table if not exists public.admin_audit_events',
        'create table if not exists public.system_config_versions',
        'create table if not exists public.report_exports',
        'create table if not exists public.sale_point_adjustments',
        'create table if not exists public.admin_reconciliation_runs',
        'create table if not exists public.admin_reconciliation_discrepancies',
        'get_my_admin_session',
        'app_access_mode',
        'can_use_user_app',
        "app_access_mode in ('user', 'both')",
        'get_admin_dashboard_summary',
        'admin_search_users',
        'admin_adjust_membership_period',
        'admin_update_user_status',
        'admin_list_payments',
        'admin_review_payment',
        'admin_refund_or_cancel_payment',
        'create_membership_payment_request',
        'admin_list_sales',
        'admin_review_sale_profile',
        'admin_upsert_config_version',
        'admin_list_report_catalog',
        'admin_request_report_export',
        'admin_adjust_sale_points',
        'admin_create_reconciliation_run',
        'admin_list_reconciliation_discrepancies',
        'admin_update_reconciliation_discrepancy_status',
        'admin_list_audit_events',
      ]) {
        expect(build, contains(token), reason: token);
      }
    });

    test('keeps the M13 VietQR manual-review and transition hardening', () {
      for (final token in [
        'admin_get_payment_review_alert',
        'pending_review_count integer',
        "where pe.status = 'pending_review';",
        'admin_assert_payment_reviewer',
        'admin_has_payment_reviewer_role',
        "aur.role_code in ('finance_admin', 'super_admin')",
        'transfer_reference text',
        'transfer_memo text',
        'payer_full_name text',
        'billing_cycle text',
        'transfer_confirmed_at timestamptz',
        "v_payment.status not in ('pending_review', 'pending')",
        'p_transfer_verified boolean',
        'PAYMENT_TRANSFER_RECONCILIATION_REQUIRED',
        'cancel_my_membership_payment_request',
        'uq_payment_events_one_open_manual_membership',
        'LEGACY_PAID_SUBSCRIPTION_MISSING_ENDS_AT',
        'same_plan_renewal',
        'plan_switch',
        "at time zone 'Asia/Ho_Chi_Minh'",
        "ms.starts_at + interval '1 microsecond'",
      ]) {
        expect(build, contains(token), reason: token);
      }
      for (final token in [
        'membership_payment_prices',
        'membership_payment_bank',
        '"bank_bin": "970436"',
        '"bank_account_number": "1026806174"',
      ]) {
        expect(seed, contains(token), reason: token);
      }
    });

    test('keeps unified role access and Admin financial policies server-owned', () {
      for (final token in [
        'add column if not exists app_access_mode',
        'users_app_access_mode_check',
        'alter column app_access_mode set not null',
        "app_access_mode = 'both'",
        'revoke update (app_access_mode)',
        'create or replace function public.get_my_admin_session()',
        'grant execute on function public.get_my_admin_session()',
        'record_trusted_payment_event',
        'p_auto_approve boolean default false',
        'p_list_price_cents integer default null',
        'p_commission_base_cents integer default null',
        "'manual_approval_required'",
        "('super_admin', '*')",
        "('finance_admin', '*')",
        "('support_admin', '*')",
        "('content_admin', '*')",
        "('operations_admin', '*')",
        "'reconciliation.write'",
        "'points.write'",
        "when p_config_key ilike 'plan%' then 'plans.write'",
        "perform public.admin_assert_permission('config.write')",
        'PAYMENT_ALREADY_REVIEWED',
        'PAYMENT_REVERSAL_WINDOW_EXPIRED',
        'create_sale_point_reversal_for_payment',
        'negative_adjustment_without_overwriting_commission',
        "'chargeback'",
        "'approval_count_required'",
      ]) {
        expect(build, contains(token), reason: token);
      }
      expect(build, contains('from public, anon, authenticated'));
    });

    test('qualifies Admin dashboard filters and keeps audits privacy-limited', () {
      final dashboard = _adminDashboardSummaryBlock(build);
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
        expect(dashboard, contains(token), reason: token);
      }
      expect(_hasUnqualifiedDashboardStatusFilter(dashboard), isFalse);

      final users = _functionBlock(build, 'admin_search_users');
      expect(
        build,
        contains('drop function if exists public.admin_search_users(text, integer);'),
      );
      for (final token in [
        'subscription_id text',
        'membership_starts_at timestamptz',
        'membership_ends_at timestamptz',
        'public.current_plan_for_user(u.id)',
        'ms.source',
        "ms.ends_at is null or ms.ends_at > now()",
      ]) {
        expect(users, contains(token), reason: token);
      }

      for (final token in [
        'admin_list_report_catalog',
        'membership_summary',
        'sale_points_summary',
        'admin_audit_summary',
        'INVALID_REPORT_TYPE',
        "'privacy', 'no_raw_payloads'",
        "coalesce(p_filters ->> 'time_zone', 'Asia/Ho_Chi_Minh')",
        'grant execute on function public.admin_list_report_catalog',
      ]) {
        expect(build, contains(token), reason: token);
      }
      final audit = _functionBlock(build, 'admin_list_audit_events');
      expect(audit, contains('returns table'));
      for (final forbidden in [
        'metadata jsonb',
        'raw_event',
        'payment_proof',
        'health_payload',
      ]) {
        expect(audit, isNot(contains(forbidden)), reason: forbidden);
      }
    });
  });

  group('Sale direct-only contract', () {
    late String build;

    setUpAll(() {
      build = File(_buildPath).readAsStringSync();
    });

    test('declares Sale internal module and conversion contracts', () {
      for (final token in [
        'create table if not exists public.sale_point_conversions',
        'create table if not exists public.sale_payout_profiles',
        'request_sale_participation',
        'attach_my_referral_code',
        'get_my_sale_payout_profile',
        'upsert_my_sale_payout_profile',
        'get_my_sale_direct_customers',
        'get_my_sale_point_ledger',
        'get_my_sale_conversions',
        'request_sale_point_conversion',
        'admin_list_sale_point_conversions',
        'admin_review_sale_point_conversion',
        'sale_point_adjustments',
        'payout_profile_complete',
        'minimum_point_cents": 500000',
        'p_device_hash',
        'p_payment_proof_path',
        'manual_adjustment',
        'sale_point_conversions_select_own',
        'available_at <= now()',
        "config_key = 'sale_point_conversion'",
      ]) {
        expect(build, contains(token), reason: token);
      }
      expect(build, isNot(contains('health_condition_summary')));
      expect(build, contains("public.admin_assert_permission('sales.write')"));
      expect(build, contains("public.admin_has_permission('sales.write')"));
    });

    test('keeps referral attach registration-only and anti-fraud constrained', () {
      final block = _functionBlock(build, 'attach_my_referral_code');
      for (final token in [
        "and sp.status = 'active'",
        'if v_referrer_id = v_user_id then',
        'where referred_user_id = v_user_id',
        'rr.device_hash = v_device_hash',
        'participation_device_hash = v_device_hash',
        'lower(v_user_email) = lower(coalesce(v_referrer_email',
        'v_user_phone = coalesce(v_referrer_phone',
        'from public.payment_events',
        "status in ('pending', 'succeeded', 'refunded', 'chargeback')",
        "'signup'",
        "'account_registration'",
        "jsonb_build_array('self', 'existing_referral', 'payment_history', 'email', 'phone', 'device')",
      ]) {
        expect(block, contains(token), reason: token);
      }
    });

    test('revokes direct client writes to Sale financial tables', () {
      for (final table in [
        'public.sale_profiles',
        'public.referral_relationships',
        'public.payment_events',
        'public.commission_records',
        'public.sale_point_conversions',
        'public.sale_payout_profiles',
      ]) {
        expect(build, contains(table), reason: table);
      }
      expect(build, contains('revoke insert, update, delete on'));
      expect(build, contains('from anon, authenticated'));
      expect(build, contains("coalesce(v_payment.paid_at, now()) + interval '24 hours'"));
      expect(build, contains('commission_base_cents'));
      expect(build, contains('list_price_cents'));
    });

    test('documents the two-script run order and removes second-level markers', () {
      final readme = File('docs/supabase/README.md').readAsStringSync();
      final buildIndex = readme.indexOf('01_build_system.sql');
      final seedIndex = readme.indexOf('02_seed_data.sql');
      expect(buildIndex, greaterThanOrEqualTo(0));
      expect(seedIndex, greaterThan(buildIndex));
      expect(build, contains('sale-payout-proofs'));

      final roots = [
        Directory('docs/supabase'),
        Directory('lib/sale_referral'),
        Directory('lib/services/supabase/sale'),
        Directory('test/sale_referral'),
      ];
      final forbidden = <String>[
        'secondLevel',
        'second-level',
        'second_level',
        '0.0500',
        'level = 2',
        '5% tang 2',
        '5% tầng 2',
      ];
      final violations = <String>[];
      for (final root in roots) {
        for (final file in root
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) {
              return file.path.endsWith('.sql') ||
                  file.path.endsWith('.md') ||
                  file.path.endsWith('.dart');
            })) {
          final content = file.readAsStringSync();
          for (final token in forbidden) {
            if (content.contains(token)) {
              violations.add('${file.path}: $token');
            }
          }
        }
      }
      expect(violations, isEmpty);
    });
  });

  group('Admin membership period adjustment contract', () {
    late String build;

    setUpAll(() {
      build = File(_buildPath).readAsStringSync();
    });

    test('keeps manual period adjustment transactional and audited', () {
      final block = _functionBlock(build, 'admin_adjust_membership_period');
      for (final token in [
        'p_expected_ends_at timestamptz',
        'p_idempotency_key text',
        "v_subscription.source <> 'manual'",
        "v_subscription.status not in ('trialing', 'active')",
        'for update',
        'MEMBERSHIP_PERIOD_STALE',
        'MEMBERSHIP_ADJUSTMENT_PERMANENT_REQUIRES_END_DATE',
        "when 'add_days' then",
        "when 'subtract_days' then",
        "p_operation not in ('add_days', 'subtract_days', 'set_end_at')",
        "when v_target_ends_at <= v_now then 'expired'",
        'current_period_end = v_target_ends_at',
        "'admin_adjust_membership_period'",
        "'membership_subscription'",
        "'previous_ends_at'",
        'idempotency_key',
      ]) {
        expect(block, contains(token), reason: token);
      }
      expect(
        build,
        contains(
          'grant execute on function public.admin_adjust_membership_period',
        ),
      );
      expect(
        build,
        contains(
          'revoke all on function public.admin_adjust_membership_period',
        ),
      );
      final manifestStart = build.indexOf('foreach v_function_name in array array[');
      final manifestEnd = build.indexOf('  ] loop', manifestStart);
      expect(manifestStart, greaterThanOrEqualTo(0));
      expect(manifestEnd, greaterThan(manifestStart));
      expect(
        build.substring(manifestStart, manifestEnd),
        isNot(contains("'admin_adjust_membership_period'")),
      );
      expect(
        build,
        contains(
          'admin_adjust_membership_period\n'
          '  uuid,\n'
          '  uuid,\n'
          '  uuid,',
        ),
      );
    });
  });
}

String _adminDashboardSummaryBlock(String sql) {
  const startToken = 'create or replace function public.get_admin_dashboard_summary';
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

String _functionBlock(String sql, String functionName) {
  final start = sql.indexOf('create or replace function public.$functionName');
  if (start < 0) {
    throw StateError('Cannot locate SQL function: $functionName');
  }
  final end = sql.indexOf('\n\$\$;', start);
  if (end < 0) {
    throw StateError('Cannot locate SQL function end: $functionName');
  }
  return sql.substring(start, end);
}
