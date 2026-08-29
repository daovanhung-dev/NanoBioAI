import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ships the required authenticated delete-account Edge Function', () {
    final config = File('supabase/config.toml').readAsStringSync();
    final handler = File(
      'supabase/functions/delete-account/handler.ts',
    ).readAsStringSync();
    final index = File(
      'supabase/functions/delete-account/index.ts',
    ).readAsStringSync();
    final client = File(
      'lib/services/supabase/auth/account_security_service.dart',
    ).readAsStringSync();

    expect(config, contains('[functions.delete-account]'));
    expect(config, contains('verify_jwt = true'));
    expect(handler, contains('confirmation_required'));
    expect(handler, contains('account_deletion_unavailable'));
    expect(index, contains('auth.getUser()'));
    expect(index, contains('auth.admin.deleteUser(userId)'));
    expect(index, contains('SUPABASE_SERVICE_ROLE_KEY'));
    expect(index, contains('schedule-completion-proofs'));
    expect(index, contains('deleteOwnedStorage'));
    expect(index, contains('.remove('));
    expect(client, contains("body: const {'confirm': true}"));
  });
}
