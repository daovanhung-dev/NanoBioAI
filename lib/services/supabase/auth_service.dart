import 'package:nano_app/core/utils/logger/app_log_category.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/services/vietnam_phone_number.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class AuthService {
  static const _scope = 'AuthService';

  static Future<AuthResponse> signUp({
    required String phone,
    required String password,
  }) {
    final normalizedPhone = VietnamPhoneNumber.normalize(phone);
    if (normalizedPhone == null) {
      throw const AuthException('Invalid Vietnam phone number.');
    }
    return AppLogger.guardAsync<AuthResponse>(
      category: AppLogCategory.auth,
      scope: _scope,
      operation: 'SIGN_UP',
      action: () => SupabaseService.client.auth.signUp(
        phone: normalizedPhone,
        password: password,
      ),
    );
  }

  static Future<AuthResponse> signIn({
    required String phone,
    required String password,
  }) {
    final normalizedPhone = VietnamPhoneNumber.normalize(phone);
    if (normalizedPhone == null) {
      throw const AuthException('Invalid Vietnam phone number.');
    }
    return AppLogger.guardAsync<AuthResponse>(
      category: AppLogCategory.auth,
      scope: _scope,
      operation: 'SIGN_IN',
      action: () => SupabaseService.client.auth.signInWithPassword(
        phone: normalizedPhone,
        password: password,
      ),
    );
  }

  static Future<void> signOut() {
    return AppLogger.guardAsync<void>(
      category: AppLogCategory.auth,
      scope: _scope,
      operation: 'SIGN_OUT',
      action: SupabaseService.client.auth.signOut,
    );
  }

  static User? get currentUser => SupabaseService.client.auth.currentUser;
}
