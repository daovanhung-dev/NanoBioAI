import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mobile payment create contract matches current Supabase rebuild first', () {
    final datasource = File(
      'lib/app_versions/v2/features/payments/data/datasources/membership_payment_remote_datasource.dart',
    ).readAsStringSync();
    final setup = File('docs/supabase/setup.sql').readAsStringSync();

    expect(setup, contains('p_payer_full_name text'));
    expect(datasource, contains("'p_payer_full_name': payerFullName"));
    expect(datasource, contains("error.code == 'PGRST202'"));

    final primaryFourArg = datasource.indexOf(
      "'p_payer_full_name': payerFullName",
    );
    final compatibilityComment = datasource.indexOf(
      'three-argument call as rollout',
    );
    expect(primaryFourArg, greaterThanOrEqualTo(0));
    expect(compatibilityComment, greaterThan(primaryFourArg));

    expect(datasource, isNot(contains('970436')));
    expect(datasource, isNot(contains('1026806174')));
    expect(datasource, isNot(contains('199000')));
  });
}
