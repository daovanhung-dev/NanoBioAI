import 'package:nano_app/core/utils/logger/app_log_category.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class AuthService {
  static const _scope = 'AuthService';

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return AppLogger.guardAsync<AuthResponse>(
      category: AppLogCategory.auth,
      scope: _scope,
      operation: 'SIGN_UP',
      action: () => SupabaseService.client.auth.signUp(
        email: email,
        password: password,
      ),
    );
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return AppLogger.guardAsync<AuthResponse>(
      category: AppLogCategory.auth,
      scope: _scope,
      operation: 'SIGN_IN',
      action: () => SupabaseService.client.auth.signInWithPassword(
        email: email,
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
