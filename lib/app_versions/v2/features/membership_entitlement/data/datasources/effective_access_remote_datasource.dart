import 'package:nano_app/app_versions/v2/features/membership_entitlement/domain/entities/effective_access.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class EffectiveAccessRemoteDatasource {
  Future<EffectiveAccess?> fetchCurrentAccess();
}

class SupabaseEffectiveAccessRemoteDatasource
    implements EffectiveAccessRemoteDatasource {
  final SupabaseClient? clientOverride;

  const SupabaseEffectiveAccessRemoteDatasource({this.clientOverride});

  SupabaseClient? get _client {
    if (clientOverride != null) return clientOverride;
    try {
      return Supabase.instance.client;
    } on AssertionError {
      return null;
    }
  }

  @override
  Future<EffectiveAccess?> fetchCurrentAccess() async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return null;

    final row = await client
        .from('effective_user_access')
        .select(
          'user_id,is_anonymous,product_access,membership_plan,'
          'sale_status,onboarding_status,updated_at',
        )
        .eq('user_id', userId)
        .maybeSingle();

    if (row == null) return null;
    return EffectiveAccess.fromMap(Map<String, Object?>.from(row));
  }
}
