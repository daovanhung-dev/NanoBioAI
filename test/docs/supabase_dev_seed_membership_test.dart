import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy membership-only seed is a no-op redirect to fixture 19', () {
    final source = File(
      'docs/supabase/09-dev-seed-membership-test-accounts.sql',
    ).readAsStringSync();
    final executable = _withoutBlockComments(source);

    for (final token in [
      'DEPRECATED / NO-OP REDIRECT',
      '19-dev-sandbox-comprehensive-seed.sql',
      '19-dev-sandbox-accounts.md',
      'docs/supabase/config.sql',
      'local/sandbox',
      'production',
    ]) {
      expect(source, contains(token), reason: token);
    }

    expect(executable, isNot(contains('begin;')));
    expect(executable, isNot(contains('commit;')));
    expect(executable, isNot(contains('insert into auth.users')));
    expect(executable, isNot(contains('insert into auth.identities')));
    expect(
      executable,
      isNot(contains('insert into public.membership_subscriptions')),
    );

    // The commented historical context intentionally retains the original
    // account names for review, while only config.sql/module 19 can seed data.
    expect(source, contains('dev.free@nanobio.local'));
    expect(source, contains('dev.plus@nanobio.local'));
    expect(source, contains('dev.family@nanobio.local'));
    expect(
      source.toLowerCase(),
      isNot(contains('v2')),
      reason:
          'The deprecated file must not preserve a competing plan-version contract.',
    );
  });
}

String _withoutBlockComments(String source) {
  return source.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
}
