import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dashboard generated plan action appends with an idempotency key', () {
    final source = File(
      'lib/app_versions/v1/features/dashboard/presentation/controllers/'
      'dashboard_controller.dart',
    ).readAsStringSync();

    expect(source, contains('requestId: _memberPlanRequestId(authUserId!)'));
    expect(source, contains('appendAfterExisting: true'));
    expect(source, isNot(contains('appendAfterExisting: false')));
  });
}
