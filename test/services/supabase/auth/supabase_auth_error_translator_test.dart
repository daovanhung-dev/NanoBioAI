import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/services/supabase/auth/supabase_auth_error_translator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('SupabaseAuthErrorTranslator', () {
    test('classifies invalid credentials', () {
      final details = SupabaseAuthErrorTranslator.fromAuthException(
        const AuthException('Invalid login credentials', statusCode: '400'),
      );

      expect(details.kind, SupabaseAuthErrorKind.invalidCredentials);
      expect(details.fullMessage, contains('Sai thông tin đăng nhập'));
    });

    test('classifies unverified email separately', () {
      final details = SupabaseAuthErrorTranslator.fromAuthException(
        const AuthException('Email not confirmed', statusCode: '400'),
      );

      expect(details.kind, SupabaseAuthErrorKind.emailUnverified);
      expect(details.fullMessage, contains('Email chưa xác thực'));
    });

    test(
      'classifies auth database/schema failures as server-side login errors',
      () {
        final details = SupabaseAuthErrorTranslator.fromAuthException(
          const AuthException(
            'Database error querying schema',
            statusCode: '500',
          ),
        );

        expect(details.kind, SupabaseAuthErrorKind.authServer);
        expect(details.fullMessage, contains('đăng nhập đang lỗi'));
      },
    );

    test('classifies rate limits and network errors', () {
      final rateLimited = SupabaseAuthErrorTranslator.fromAuthException(
        const AuthException('Too many requests', statusCode: '429'),
      );
      final network = SupabaseAuthErrorTranslator.fromObject(
        StateError('network timeout'),
      );

      expect(rateLimited.kind, SupabaseAuthErrorKind.rateLimited);
      expect(network.kind, SupabaseAuthErrorKind.network);
    });
  });
}
