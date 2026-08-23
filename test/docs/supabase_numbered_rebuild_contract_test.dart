import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const componentPaths = [
    'docs/supabase/01_schema_rebuild_local_sandbox.sql',
    'docs/supabase/02_schema_meal_nutrition_v18.sql',
    'docs/supabase/03_schema_daily_health_hub_rewards.sql',
    'docs/supabase/04_schema_auth_account_lock.sql',
    'docs/supabase/05_seed_local_sandbox.sql',
    'docs/supabase/06_schema_runtime_support.sql',
  ];

  const validationPaths = [
    'docs/supabase/90_validate_meal_catalog.sql',
    'docs/supabase/91_validate_meal_nutrition_v18.sql',
    'docs/supabase/92_validate_daily_health_hub_rewards.sql',
    'docs/supabase/93_validate_membership_vietqr.sql',
    'docs/supabase/94_validate_runtime_support.sql',
  ];

  test(
    'numbers the destructive local/sandbox rebuild and generated config',
    () {
      for (final path in componentPaths) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }

      final readme = File('docs/supabase/README.md').readAsStringSync();
      final config = File('docs/supabase/config.sql').readAsStringSync();

      var previousSectionEnd = -1;
      for (final path in componentPaths) {
        final filename = path.split('/').last;
        expect(readme, contains(filename), reason: filename);
        expect(config, contains('-- BEGIN $filename'), reason: filename);
        expect(config, contains('-- END $filename'), reason: filename);

        final section = _markedSection(config, filename);
        expect(section.start, greaterThan(previousSectionEnd), reason: filename);
        expect(
          _normaliseSql(section.body),
          _normaliseSql(File(path).readAsStringSync()),
          reason: '$filename must be copied verbatim into generated config.sql.',
        );
        previousSectionEnd = section.end;
      }
      expect(config, contains('DESTRUCTIVE LOCAL/SANDBOX SCRIPT ONLY'));
      expect(config, contains('do not edit by hand'));
    },
  );

  test('keeps validators ordered after the authoritative rebuild sources', () {
    final readme = File('docs/supabase/README.md').readAsStringSync();
    final runOrder = readme.substring(readme.indexOf('## Thứ tự chạy'));
    var previousReadmeIndex = -1;

    for (final path in [...componentPaths, ...validationPaths]) {
      expect(File(path).existsSync(), isTrue, reason: path);
      final filename = path.split('/').last;
      final index = runOrder.indexOf(filename);
      expect(index, greaterThan(previousReadmeIndex), reason: filename);
      previousReadmeIndex = index;
    }

    final config = File('docs/supabase/config.sql').readAsStringSync();
    for (final path in validationPaths) {
      final filename = path.split('/').last;
      expect(
        config,
        isNot(contains('-- BEGIN $filename')),
        reason: '$filename validates the rebuild and must not define it.',
      );
    }
  });

  test('documents source precedence without claiming sandbox execution', () {
    final readme = File('docs/supabase/README.md').readAsStringSync();

    for (final token in [
      'là nguồn có thẩm quyền',
      '`config.sql` là bản dẫn xuất',
      'không sửa file này bằng tay',
      'không định nghĩa hoặc thay thế schema, RPC hay seed',
      'Sandbox runtime (thực thi 01 → 06 rồi 90 → 94): `UNVERIFIED`',
      'Không suy diễn trạng thái production',
    ]) {
      expect(readme, contains(token), reason: token);
    }
  });

  test('seeds the requested local Plus account server-side', () {
    final seed = File(
      'docs/supabase/05_seed_local_sandbox.sql',
    ).readAsStringSync();

    for (final token in [
      'Thuytien8994@gmail.com',
      "'plus'::public.nb_membership_plan",
      'crypt(',
      'LOCAL_PLUS_SEED_AUTH_INVALID',
      'LOCAL_PLUS_SEED_PLAN_INVALID',
      'LOCAL_PLUS_SEED_AI_CHAT_ENTITLEMENT_INVALID',
      'entitlement_key = \'ai_chat\'',
      "'{\"enabled\":true,\"unlimited\":true}'::jsonb",
    ]) {
      expect(seed, contains(token), reason: token);
    }
  });

  test('keeps VietQR creation server-issued, idempotent, and rollback-only', () {
    final smoke = File(
      'docs/supabase/93_validate_membership_vietqr.sql',
    ).readAsStringSync();

    expect(smoke, startsWith('-- Rollback-only'));
    expect(smoke, contains('create_membership_payment_request'));
    expect(smoke, contains("'^NB[0-9A-F]{12}$'"));
    expect(smoke, contains('VIETQR_IDEMPOTENCY_BROKEN'));
    expect(smoke, contains('VIETQR_OPEN_REQUEST_GUARD_MISSING'));
    expect(smoke.trimRight(), endsWith('rollback;'));
  });

  test('keeps runtime Storage and RPC support separate from fixtures', () {
    final runtime = File(
      'docs/supabase/06_schema_runtime_support.sql',
    ).readAsStringSync();
    final seed = File('docs/supabase/05_seed_local_sandbox.sql')
        .readAsStringSync();
    final smoke = File('docs/supabase/94_validate_runtime_support.sql')
        .readAsStringSync();

    for (final bucket in [
      'schedule-completion-proofs',
      'sale-payout-proofs',
    ]) {
      expect(runtime, contains(bucket), reason: bucket);
      expect(seed, isNot(contains('insert into storage.buckets')));
    }
    expect(runtime, contains('RUNTIME_RPC_MISSING_'));
    expect(runtime, contains('grant execute on function public.%I'));
    expect(smoke, contains('RUNTIME_STORAGE_BUCKET_INVALID_'));
    expect(smoke.trimRight(), endsWith('rollback;'));
  });
}

class _MarkedSection {
  const _MarkedSection({
    required this.start,
    required this.end,
    required this.body,
  });

  final int start;
  final int end;
  final String body;
}

_MarkedSection _markedSection(String source, String filename) {
  final beginToken = '-- BEGIN $filename';
  final endToken = '-- END $filename';
  final begin = source.indexOf(beginToken);
  final end = source.indexOf(endToken, begin + beginToken.length);
  if (begin < 0 || end < 0) {
    throw StateError('Cannot locate generated section for $filename.');
  }
  return _MarkedSection(
    start: begin,
    end: end + endToken.length,
    body: source.substring(begin + beginToken.length, end),
  );
}

String _normaliseSql(String source) {
  return source
      .replaceFirst('\uFEFF', '')
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .trim();
}
