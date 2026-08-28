import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('payment contracts match the current canonical Supabase build script', () {
    final datasource = File(
      'lib/app_versions/v2/features/payments/data/datasources/membership_payment_remote_datasource.dart',
    ).readAsStringSync();
    final setup = File('docs/supabase/01_build_system.sql').readAsStringSync();

    expect(setup, contains('p_payer_full_name text'));
    expect(
      setup,
      contains('create table if not exists public.google_play_purchase_ledger'),
    );
    expect(
      setup,
      contains(
        'create or replace function public.finalize_google_play_purchase',
      ),
    );
    expect(setup, contains("provider = 'google_play'"));
    expect(
      setup,
      contains(
        'grant execute on function public.finalize_google_play_purchase',
      ),
    );
    expect(datasource, contains("'p_payer_full_name': payerFullName"));
    expect(datasource, contains("error.code == 'PGRST202'"));

    expect(datasource, contains("'p_billing_cycle': billingCycle"));

    expect(datasource, isNot(contains('970436')));
    expect(datasource, isNot(contains('1026806174')));
    expect(datasource, isNot(contains('199000')));
    expect(
      File('docs/supabase/README.md').readAsStringSync(),
      contains('01_build_system.sql'),
    );
    expect(
      File('docs/supabase/README.md').readAsStringSync(),
      contains('02_seed_data.sql'),
    );
  });
}
