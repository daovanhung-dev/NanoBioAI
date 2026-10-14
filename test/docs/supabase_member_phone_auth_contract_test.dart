import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'member login phone remains Auth-owned across profile and snapshots',
    () {
      final canonical = File(
        'docs/supabase/01_build_system.sql',
      ).readAsStringSync();
      final migration = File(
        'supabase/migrations/20261014090000_member_phone_auth_security.sql',
      ).readAsStringSync();
      final loginMigration = File(
        'supabase/migrations/20261014110000_member_phone_login_alias.sql',
      ).readAsStringSync();
      final seed = File('docs/supabase/02_seed_data.sql').readAsStringSync();
      expect(
        canonical,
        isNot(contains("phone = coalesce(nullif(v_user ->> 'phone'")),
      );
      expect(
        canonical,
        contains('revoke update on public.users from anon, authenticated'),
      );
      expect(
        canonical,
        contains('phone = coalesce(new.phone, public.users.phone)'),
      );
      expect(
        migration,
        contains("coalesce(p_snapshot -> 'user', '{}'::jsonb) - 'phone'"),
      );
      expect(
        migration,
        contains('revoke update on public.users from anon, authenticated'),
      );
      expect(migration, contains('MEMBER_PHONE_CLIENT_UPDATE_GRANT_INVALID'));
      expect(migration, contains('MEMBER_PHONE_SNAPSHOT_RPC_GRANT_INVALID'));
      expect(
        canonical,
        contains('create or replace function public.consume_member_phone_signup_rate_limit'),
      );
      expect(
        loginMigration,
        contains('consume_member_phone_signup_rate_limit'),
      );
      expect(loginMigration, contains('MEMBER_PHONE_UNIQUE_INDEX_MISSING'));
      expect(seed, contains('@phone.nanobio.invalid'));
    },
  );
}
