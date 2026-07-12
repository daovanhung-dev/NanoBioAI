import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_callback_result.dart';

void main() {
  group('authCallbackTypeFromUri', () {
    test('detects password recovery from query and fragment', () {
      expect(
        authCallbackTypeFromUri(
          Uri.parse('nanobio://auth/callback?type=recovery'),
        ),
        AuthCallbackType.passwordRecovery,
      );
      expect(
        authCallbackTypeFromUri(
          Uri.parse('nanobio://auth/callback#access_token=x&type=recovery'),
        ),
        AuthCallbackType.passwordRecovery,
      );
    });

    test('detects email confirmation callback types', () {
      for (final type in ['signup', 'email', 'email_change', 'invite']) {
        expect(
          authCallbackTypeFromUri(
            Uri.parse('nanobio://auth/callback?type=$type'),
          ),
          AuthCallbackType.emailConfirmation,
          reason: type,
        );
      }
    });

    test('returns unknown for missing or malformed callback type', () {
      expect(
        authCallbackTypeFromUri(Uri.parse('nanobio://auth/callback')),
        AuthCallbackType.unknown,
      );
      expect(
        authCallbackTypeFromUri(
          Uri.parse('nanobio://auth/callback#%%%'),
        ),
        AuthCallbackType.unknown,
      );
    });
  });
}
