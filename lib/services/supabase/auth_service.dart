import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class AuthService {

  // REGISTER
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {

    return await SupabaseService.client.auth
        .signUp(
      email: email,
      password: password,
    );
  }

  // LOGIN
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {

    return await SupabaseService.client.auth
        .signInWithPassword(
      email: email,
      password: password,
    );
  }

  // LOGOUT
  static Future<void> signOut() async {

    await SupabaseService.client.auth
        .signOut();
  }

  // CURRENT USER
  static User? get currentUser {

    return SupabaseService
        .client
        .auth
        .currentUser;
  }
}