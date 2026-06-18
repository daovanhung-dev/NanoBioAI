import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRemoteDatasource {
  final supabase = Supabase.instance.client;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
}
