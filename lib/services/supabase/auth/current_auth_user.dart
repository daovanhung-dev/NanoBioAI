import 'package:supabase_flutter/supabase_flutter.dart';

String? currentSupabaseUserIdOrNull() {
  try {
    return Supabase.instance.client.auth.currentUser?.id;
  } on AssertionError {
    return null;
  }
}
