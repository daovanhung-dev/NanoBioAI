import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Supabase membership expiration contract', () {
    late String build;
    late String readme;
    late String smoke;

    setUpAll(() {
      build = File('docs/supabase/01_build_system.sql').readAsStringSync();
      readme = File('docs/supabase/README.md').readAsStringSync();
      smoke = File(
        'test/docs/fixtures/supabase_membership_expiration_smoke.sql',
      ).readAsStringSync();
    });

    test('declares the trusted idempotent expiration function', () {
      for (final token in [
        'create or replace function public.expire_membership_subscriptions()',
        'returns integer',
        "v_now timestamptz := now()",
        "status in ('trialing', 'active', 'past_due')",
        'ends_at is not null',
        'ends_at <= v_now',
        "status = 'expired'",
        'get diagnostics v_expired_count = row_count',
        'return v_expired_count',
      ]) {
        expect(build, contains(token), reason: token);
      }

      expect(build, contains('security definer'));
      expect(build, contains('set search_path = public, pg_temp'));
      expect(
        build,
        contains('revoke all on function public.expire_membership_subscriptions()'),
      );
      expect(
        build,
        contains(
          'grant execute on function public.expire_membership_subscriptions()\n'
          'to service_role;',
        ),
      );
    });

    test('registers one rebuild-safe five-minute cron job', () {
      for (final token in [
        'create extension if not exists pg_cron;',
        "jobname = 'nanobio-expire-memberships'",
        'cron.unschedule(v_job_id)',
        "'*/5 * * * *'",
        "'select public.expire_membership_subscriptions();'",
        'perform cron.schedule(',
        'and active',
      ]) {
        expect(build, contains(token), reason: token);
      }

      expect(readme, contains('pg_cron'));
      expect(readme, contains('nanobio-expire-memberships'));
      expect(
        readme,
        contains('test/docs/fixtures/supabase_membership_expiration_smoke.sql'),
      );

      final extensionIndex = build.indexOf(
        'create extension if not exists pg_cron;',
      );
      final transactionIndex = build.indexOf('\nbegin;');
      final unscheduleIndex = build.indexOf('cron.unschedule(v_job_id)');
      expect(extensionIndex, lessThan(transactionIndex));
      expect(unscheduleIndex, lessThan(transactionIndex));
    });

    test('keeps the dynamic effective-access fallback and client boundary', () {
      for (final token in [
        'public.current_plan_for_user(u.id)',
        "ms.ends_at is null or ms.ends_at > now()",
        'MEMBERSHIP_EXPIRY_CRON_EXTENSION_MISSING',
        'MEMBERSHIP_EXPIRY_SERVICE_ROLE_GRANT_MISSING',
        'MEMBERSHIP_EXPIRY_CLIENT_GRANT_INVALID',
        'MEMBERSHIP_EXPIRY_CRON_JOB_INVALID',
      ]) {
        expect(build, contains(token), reason: token);
      }
      expect(
        build,
        isNot(
          contains(
            'grant execute on function '
            'public.expire_membership_subscriptions() to authenticated',
          ),
        ),
      );
    });

    test('provides a rollback-only executable expiration smoke', () {
      expect(
        smoke,
        startsWith('-- Membership expiration rollback-only executable smoke.'),
      );
      expect(smoke, contains('\nbegin;'));
      expect(smoke.trimRight(), endsWith('rollback;'));

      for (final token in [
        'MEMBERSHIP_EXPIRY_USER_MISSING',
        'MEMBERSHIP_EXPIRY_DID_NOT_EXPIRE',
        'MEMBERSHIP_EXPIRY_NOT_IDEMPOTENT',
        'MEMBERSHIP_EXPIRY_USER_NOT_FREE',
        'MEMBERSHIP_EXPIRY_OTHER_ACTIVE_PLAN_LOST',
        'MEMBERSHIP_EXPIRY_PERMANENT_CHANGED',
        'MEMBERSHIP_EXPIRY_CANCELED_RECLASSIFIED',
        'MEMBERSHIP_EXPIRY_NEW_GRANT_NOT_RESTORED',
        'rollback;',
      ]) {
        expect(smoke, contains(token), reason: token);
      }
    });
  });
}
