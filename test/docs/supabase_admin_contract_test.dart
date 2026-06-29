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

    test(
      'keeps service-role style payment function away from Flutter grants',
      () {
        final sql = File(
          'docs/supabase/11-admin-access-dashboard.sql',
        ).readAsStringSync();

        expect(sql, contains('record_trusted_payment_event'));
        expect(sql, contains('p_auto_approve boolean default false'));
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
        'PACKAGE_REFUND_CANCEL_WINDOW_CLOSED',
        "interval '24 hours'",
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
        'request_sale_participation',
        'attach_my_referral_code',
        'get_my_sale_direct_customers',
        'get_my_sale_point_ledger',
        'get_my_sale_conversions',
        'request_sale_point_conversion',
        'admin_list_sale_point_conversions',
        'admin_review_sale_point_conversion',
        'sale_point_adjustments',
        'manual_adjustment',
        'sale_point_conversions_select_own',
        'available_at <= now()',
        "config_key = 'sale_point_conversion'",
      ]) {
        expect(sql, contains(token), reason: token);
      }
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
    });

    test('documents the Sale SQL update in Supabase run order', () {
      final readme = File('docs/supabase/README.md').readAsStringSync();
      final checks = File(
        'docs/supabase/08-acceptance-checks.md',
      ).readAsStringSync();

      expect(readme, contains('12-sale-module-update.sql'));
      expect(checks, contains('sale_point_conversions'));
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
