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
        'get_my_admin_session',
        'get_admin_dashboard_summary',
        'admin_search_users',
        'admin_update_user_status',
        'admin_list_payments',
        'admin_review_payment',
        'admin_list_sales',
        'admin_review_sale_profile',
        'admin_upsert_config_version',
        'admin_request_report_export',
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
        expect(
          sql,
          contains('from public, anon, authenticated'),
          reason: 'Trusted payment recorder must not be granted to Flutter.',
        );
      },
    );
  });

  group('Sale direct-only contract', () {
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
