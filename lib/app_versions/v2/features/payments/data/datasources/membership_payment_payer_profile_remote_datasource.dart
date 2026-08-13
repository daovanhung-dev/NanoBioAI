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

    final row = await client
        .from('users')
        .select('full_name')
        .eq('id', normalizedUserId)
        .maybeSingle();
    final fullName = row?['full_name']?.toString().trim();
    return fullName == null || fullName.isEmpty ? null : fullName;
  }
}
