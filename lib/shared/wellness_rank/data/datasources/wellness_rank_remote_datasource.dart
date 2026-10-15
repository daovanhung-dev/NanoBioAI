import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class WellnessRankRemoteDatasource {
  Future<Map<String, Object?>> loadSummary();
}

class SupabaseWellnessRankRemoteDatasource
    implements WellnessRankRemoteDatasource {
  final SupabaseClient? clientOverride;

  const SupabaseWellnessRankRemoteDatasource({this.clientOverride});

  @override
  Future<Map<String, Object?>> loadSummary() async {
    final client = clientOverride ?? Supabase.instance.client;
    if (client.auth.currentUser == null) {
      throw const AuthException('auth_required');
    }
    final response = await client.rpc('get_my_wellness_rank_summary');
    if (response is Map) {
      return response.map((key, value) => MapEntry(key.toString(), value));
    }
    if (response is List && response.isNotEmpty && response.first is Map) {
      final map = response.first as Map;
      return map.map((key, value) => MapEntry(key.toString(), value));
    }
    throw const FormatException('wellness_rank_summary_invalid');
  }
}
