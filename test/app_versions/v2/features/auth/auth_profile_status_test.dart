import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_profile.dart';

void main() {
  group('AuthProfile admin status', () {
    test('suspended and closed profiles are access blocked', () {
      final suspended = AuthProfile.fromMap(const {
        'id': 'user-1',
        'onboarding_status': 'completed',
        'subscription_tier': 'free',
        'admin_status': 'suspended',
      });
      final closed = AuthProfile.fromMap(const {
        'id': 'user-2',
        'onboarding_status': 'completed',
        'subscription_tier': 'free',
        'admin_status': 'closed',
      });

      expect(suspended.isAccessBlocked, isTrue);
      expect(closed.isAccessBlocked, isTrue);
    });

    test('missing or unknown status remains backward-compatible as active', () {
      final missing = AuthProfile.fromMap(const {
        'id': 'user-1',
        'onboarding_status': 'completed',
      });
      final unknown = AuthProfile.fromMap(const {
        'id': 'user-2',
        'onboarding_status': 'completed',
        'admin_status': 'legacy-value',
      });

      expect(missing.adminStatus, 'active');
      expect(missing.isAccessBlocked, isFalse);
      expect(unknown.adminStatus, 'active');
      expect(unknown.isAccessBlocked, isFalse);
    });
  });
}
