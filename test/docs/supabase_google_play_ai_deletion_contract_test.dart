import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sandbox smoke is rollback-only and covers new server contracts', () {
    final source = File(
      'test/docs/fixtures/supabase_google_play_ai_deletion_smoke.sql',
    ).readAsStringSync();

    expect(
      source,
      startsWith('-- Google Play / AI backend / deletion sandbox smoke.'),
    );
    expect(source, contains('\nbegin;'));
    expect(source.trimRight(), endsWith('rollback;'));
    for (final marker in [
      'NB_P0_PLAY_LEDGER_MISSING',
      'NB_P0_AI_REPORTS_MISSING',
      'NB_P0_PLAY_FINALIZE_RPC_MISSING',
      'NB_P1_DELETION_TRIGGER_MISSING',
      'NB_P1_PLAY_LEDGER_RLS_DISABLED',
      'NB_P0_AI_REPORTS_CLIENT_POLICY_PRESENT',
      'NB_P0_PLAY_LEDGER_CLIENT_WRITE_ALLOWED',
      'two independent SQL/HTTP sessions',
    ]) {
      expect(source, contains(marker), reason: marker);
    }
  });
}
