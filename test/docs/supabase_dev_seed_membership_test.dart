import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('numbered seed owns the local membership account contract', () {
    final seed = File(
      'docs/supabase/05_seed_local_sandbox.sql',
    ).readAsStringSync();

    for (final token in [
      'DEV/SANDBOX ONLY',
      'NanoBio@123456',
      'dev.free@nanobio.local',
      'dev.plus@nanobio.local',
      'dev.family@nanobio.local',
      'dev.admin@nanobio.local',
      "'free'::public.nb_membership_plan",
      "'plus'::public.nb_membership_plan",
      "'family_plus'::public.nb_membership_plan",
      'insert into auth.users',
      'insert into auth.identities',
      'insert into public.membership_subscriptions',
      'LOCAL_PLUS_SEED_AUTH_INVALID',
      'LOCAL_PLUS_SEED_PLAN_INVALID',
    ]) {
      expect(seed, contains(token), reason: token);
    }

    expect(seed.toLowerCase(), contains('local/sandbox'));
    expect(seed.toLowerCase(), contains('production'));
  });
}
