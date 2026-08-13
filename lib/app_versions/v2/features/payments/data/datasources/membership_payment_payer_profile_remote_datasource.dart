import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class MembershipPaymentPayerProfileRemoteDatasource {
  Future<String?> readFullName(String userId);
}

class SupabaseMembershipPaymentPayerProfileRemoteDatasource
    implements MembershipPaymentPayerProfileRemoteDatasource {
  final SupabaseClient? clientOverride;

  const SupabaseMembershipPaymentPayerProfileRemoteDatasource({
    this.clientOverride,
  });

  @override
  Future<String?> readFullName(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return null;

    final client = clientOverride ?? Supabase.instance.client;
    final currentUser = client.auth.currentUser;
    if (currentUser == null || currentUser.id != normalizedUserId) {
      return null;
    }

    // The public profile is preferred because it is the server-side business
    // profile used by the payment flow. Profile lookup must never prevent QR
    // creation, so auth metadata/email remain safe display-only fallbacks.
    try {
      final row = await client
          .from('users')
          .select('full_name')
          .eq('id', normalizedUserId)
          .maybeSingle();
      final fullName = _readText(row?['full_name']);
      if (fullName != null) return fullName;
    } catch (_) {
      // Payment reference/amount/bank details are created by the trusted RPC.
      // A profile read failure is not a valid reason to suppress that request.
    }

    final metadata = currentUser.userMetadata;
    return _readText(metadata?['full_name']) ??
        _readText(metadata?['name']) ??
        _readText(currentUser.email);
  }
}

String? _readText(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
