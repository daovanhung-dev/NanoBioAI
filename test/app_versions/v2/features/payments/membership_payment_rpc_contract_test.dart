import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('membership payment flow uses versioned self-hosted backend routes', () {
    final datasource = File(
      'lib/app_versions/v2/features/payments/data/datasources/membership_payment_remote_datasource.dart',
    ).readAsStringSync();
    final storeDatasource = File(
      'lib/app_versions/v2/features/payments/data/datasources/membership_store_purchase_remote_datasource.dart',
    ).readAsStringSync();

    expect(datasource, contains("'/api/v1/payments/membership-requests'"));
    expect(datasource, contains("'/api/v1/payments/membership-requests/me'"));
    expect(datasource, contains("'plan_code': planCode"));
    expect(datasource, contains("'billing_cycle': billingCycle"));
    expect(datasource, contains("'payer_full_name': payerFullName"));
    expect(storeDatasource, contains("'/api/v1/payments/google-play/verify'"));
    expect(datasource, isNot(contains('SupabaseClient')));
    expect(storeDatasource, isNot(contains('SupabaseClient')));
  });
}
