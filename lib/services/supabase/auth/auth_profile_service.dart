import 'package:supabase_flutter/supabase_flutter.dart';

/// Read-only Supabase Auth profile helper.
///
/// User-owned profile and onboarding writes are local-first. They are persisted
/// in SQLite, marked dirty by sync triggers, then mirrored to Supabase by the
/// user-data outbox snapshot RPC.
class AuthProfileService {
  final SupabaseClient? clientOverride;

  const AuthProfileService({this.clientOverride});

  SupabaseClient? get _client {
    if (clientOverride != null) return clientOverride;
    try {
      return Supabase.instance.client;
    } on AssertionError {
      return null;
    }
  }

  String? get currentUserId {
    return _client?.auth.currentUser?.id;
  }

  bool get hasAuthenticatedUser {
    return currentUserId != null;
  }
}
