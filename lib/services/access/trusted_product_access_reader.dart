import 'dart:async';

import 'package:nano_app/core/network/backend_api_client.dart';
import 'package:nano_app/services/backend/auth/current_backend_user.dart';

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
    final userId = currentBackendUserIdOrNull();
    if (userId == null || userId.trim().isEmpty) {
      return ProductAccessLevel.guest;
    }
    try {
      final row = await BackendApiClient.shared
          .requestMap('GET', '/api/v1/membership/me')
          .timeout(timeout);
      final value = (row['product_access'] ?? row['membership_plan'])
          ?.toString()
          .trim()
          .toLowerCase();
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
