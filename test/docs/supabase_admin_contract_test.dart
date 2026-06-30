import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Supabase Admin SQL contract', () {
    test('declares Admin tables and RPCs used by Flutter Admin', () {
      final sql = File(
        'docs/supabase/11-admin-access-dashboard.sql',
      ).readAsStringSync();

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
        'get_admin_dashboard_summary',
        'admin_search_users',
        'admin_update_user_status',
        'admin_list_payments',
        'admin_review_payment',
        'admin_refund_or_cancel_payment',
        'create_membership_payment_request',
        'admin_list_sales',
        'admin_review_sale_profile',
        'admin_upsert_config_version',
        'admin_request_report_export',
        'admin_adjust_sale_points',
        'admin_create_reconciliation_run',
        'admin_list_reconciliation_discrepancies',
        'admin_update_reconciliation_discrepancy_status',
        'admin_list_audit_events',
      ]) {
        expect(sql, contains(token), reason: token);
      }
    });

    test('qualifies Admin dashboard summary metric filters', () {
      final sql = File(
        'docs/supabase/11-admin-access-dashboard.sql',
      ).readAsStringSync();
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
            'status filters must stay table-qualified.',
      );
    });

    test(
      'keeps service-role style payment function away from Flutter grants',
      () {
        final sql = File(
          'docs/supabase/11-admin-access-dashboard.sql',
        ).readAsStringSync();

        expect(sql, contains('record_trusted_payment_event'));
        expect(sql, contains('p_auto_approve boolean default false'));
        expect(sql, contains('p_list_price_cents integer default null'));
        expect(sql, contains('p_commission_base_cents integer default null'));
        expect(sql, contains("'manual_approval_required'"));
        expect(sql, contains("'pending'"));
        expect(
          sql,
          contains('from public, anon, authenticated'),
          reason: 'Trusted payment recorder must not be granted to Flutter.',
        );
      },
    );

    test('grants all active Admin roles full audited capability', () {
      final sql = File(
        'docs/supabase/11-admin-access-dashboard.sql',
      ).readAsStringSync();

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

    test('documents Admin payment and point policy decisions', () {
      final sql = File(
        'docs/supabase/11-admin-access-dashboard.sql',
      ).readAsStringSync();

      for (final token in [
        'PAYMENT_ALREADY_REVIEWED',
        'PAYMENT_REVERSAL_WINDOW_EXPIRED',
        'create_sale_point_reversal_for_payment',
        'negative_adjustment_without_overwriting_commission',
        "'chargeback'",
        "'approval_count_required'",
        "'admin_adjust_sale_points'",
        "'admin_update_reconciliation_discrepancy_status'",
      ]) {
        expect(sql, contains(token), reason: token);
      }
    });
  });

  group('Sale direct-only contract', () {
    test('declares Sale internal module update RPCs and conversion table', () {
      final sql = File(
        'docs/supabase/12-sale-module-update.sql',
      ).readAsStringSync();

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
        expect(sql, contains(token), reason: token);
      }
      expect(sql, isNot(contains('health_condition_summary')));
    });

    test('keeps Sale conversion review under sales.write permission', () {
      final sql = File(
        'docs/supabase/12-sale-module-update.sql',
      ).readAsStringSync();

      expect(sql, contains("public.admin_assert_permission('sales.write')"));
      expect(sql, contains("public.admin_has_permission('sales.write')"));
      expect(
        sql,
        isNot(contains("public.admin_has_permission('payments.write')")),
      );
    });

    test('revokes direct client writes to Sale financial tables', () {
      final sql = [
        File(
          'docs/supabase/05-sale-referral-commission.sql',
        ).readAsStringSync(),
        File('docs/supabase/12-sale-module-update.sql').readAsStringSync(),
      ].join('\n');

      for (final table in [
        'public.sale_profiles',
        'public.referral_relationships',
        'public.payment_events',
        'public.commission_records',
        'public.sale_point_conversions',
        'public.sale_payout_profiles',
      ]) {
        expect(sql, contains(table), reason: table);
      }

      expect(
        sql,
        contains('revoke insert, update, delete on'),
        reason:
            'Server-owned Sale/payment tables must not be writable by Flutter.',
      );
      expect(sql, contains('from anon, authenticated'));
      expect(sql, contains("'pending',"));
      expect(
        sql,
        contains("coalesce(v_payment.paid_at, now()) + interval '24 hours'"),
      );
      expect(sql, contains("and status = 'active'"));
      expect(sql, contains('commission_base_cents'));
      expect(sql, contains('list_price_cents'));
    });

    test('documents the Sale SQL update in Supabase run order', () {
      final readme = File('docs/supabase/README.md').readAsStringSync();
      final checks = File(
        'docs/supabase/08-acceptance-checks.md',
      ).readAsStringSync();
      final storage = File(
        'docs/supabase/13-sale-payout-storage.md',
      ).readAsStringSync();

      expect(readme, contains('12-sale-module-update.sql'));
      expect(readme, contains('13-sale-payout-storage.md'));
      expect(checks, contains('sale_point_conversions'));
      expect(checks, contains('sale_payout_profiles'));
      expect(storage, contains('sale-payout-proofs'));
      expect(storage, contains('public.admin_has_permission'));
    });

    test(
      'removes second-level commission markers from Supabase and Sale code',
      () {
        final roots = [
          Directory('docs/supabase'),
          Directory('lib/sale_referral'),
          Directory('lib/services/supabase/sale'),
          Directory('test/sale_referral'),
        ];

        final files = roots
            .expand(
              (root) => root.listSync(recursive: true).whereType<File>().where((
                file,
              ) {
                return file.path.endsWith('.sql') ||
                    file.path.endsWith('.md') ||
                    file.path.endsWith('.dart');
              }),
            )
            .toList();

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
        for (final file in files) {
          final content = file.readAsStringSync();
          for (final token in forbidden) {
            if (content.contains(token)) {
              violations.add('${file.path}: $token');
            }
          }
        }

        expect(violations, isEmpty);
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
