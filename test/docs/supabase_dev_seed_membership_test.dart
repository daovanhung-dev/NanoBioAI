import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dev membership seed contains fixed auth and subscription records', () {
    final source = File(
      'docs/supabase/09-dev-seed-membership-test-accounts.sql',
    ).readAsStringSync();

    expect(source, contains('DEV/SANDBOX ONLY'));
    expect(source, contains('auth.users'));
    expect(source, contains('auth.identities'));
    expect(source, contains('membership_subscriptions'));
    expect(source, contains('dev.free@nanobio.local'));
    expect(source, contains('dev.plus@nanobio.local'));
    expect(source, contains('dev.family@nanobio.local'));
    expect(source, contains("'free'::public.nb_membership_plan"));
    expect(source, contains("'plus'::public.nb_membership_plan"));
    expect(source, contains("'family_plus'::public.nb_membership_plan"));
    expect(source, contains('confirmation_token'));
    expect(source, contains('reauthentication_token'));
    expect(source, contains('update auth.users'));
    expect(source, contains('DEV_AUTH_SEED_TOKEN_COLUMNS_NULL'));
    expect(source, isNot(contains('service_role')));
  });
}
