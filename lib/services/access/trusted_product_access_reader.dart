import 'dart:async';

import 'package:nano_app/services/supabase/auth/current_auth_user.dart';
import 'package:nano_app/services/supabase/supabase_service.dart';

import 'product_access_level.dart';
import 'product_access_reader.dart';

/// Reads server-derived effective access. Any unknown/error/timeout fails closed
/// to the free pipeline. Local `users.subscription_tier` is intentionally not a
/// paid entitlement source.
class TrustedProductAccessReader implements ProductAccessReader {
  final Duration timeout;

  const TrustedProductAccessReader({this.timeout = const Duration(seconds: 4)});

  @override
  Future<ProductAccessLevel> read() async {
    final userId = currentSupabaseUserIdOrNull();
    if (userId == null || userId.trim().isEmpty) return ProductAccessLevel.guest;
    try {
      final row = await SupabaseService.client
          .from('effective_user_access')
          .select('user_id, product_access')
          .eq('user_id', userId)
          .maybeSingle()
          .timeout(timeout);
      final value = row?['product_access']?.toString().trim().toLowerCase();
      return switch (value) {
        'plus' => ProductAccessLevel.plus,
        'family_plus' || 'familyplus' => ProductAccessLevel.familyPlus,
        'guest' => ProductAccessLevel.guest,
        _ => ProductAccessLevel.free,
      };
    } catch (_) {
      return ProductAccessLevel.free;
    }
  }
}
