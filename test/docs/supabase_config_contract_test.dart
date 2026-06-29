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
        'create table if not exists public.membership_plans',
        'create table if not exists public.sale_profiles',
        'create table if not exists public.payment_events',
        'create table if not exists public.commission_records',
        'create table if not exists public.admin_roles',
        'create table if not exists public.admin_audit_events',
        'create table if not exists public.sale_point_conversions',
        'sync_my_mobile_snapshot',
        'get_my_sale_state',
        'request_sale_participation',
        'attach_my_referral_code',
        'get_my_sale_dashboard',
        'get_my_sale_direct_customers',
        'get_my_sale_point_ledger',
        'get_my_sale_conversions',
        'request_sale_point_conversion',
        'get_my_admin_session',
        'get_admin_dashboard_summary',
        'admin_search_users',
        'admin_review_payment',
        'admin_review_sale_profile',
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
      expect(sql, isNot(contains("'NAMI-'")));
      expect(sql, contains('public.admin_assert_permission'));
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

    test('does not grant trusted payment recorder to Flutter roles', () {
      expect(sql, contains('record_trusted_payment_event'));
      expect(
        sql,
        contains('from public, anon, authenticated'),
        reason: 'Trusted payment recorder must not be granted to Flutter.',
      );
    });

    test('keeps Admin draft role permission matrix in rebuild file', () {
      for (final token in [
        "('super_admin', '*')",
        "('finance_admin', 'payments.write')",
        "('finance_admin', 'reports.write')",
        "('operations_admin', 'users.write')",
        "('operations_admin', 'sales.write')",
        "when p_config_key ilike 'plan%' then 'plans.write'",
        "perform public.admin_assert_permission('config.write')",
      ]) {
        expect(sql, contains(token), reason: token);
      }

      expect(sql, isNot(contains("('finance_admin', 'sales.write')")));
      expect(sql, isNot(contains("('operations_admin', 'payments.write')")));
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
