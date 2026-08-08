import 'package:nano_app/services/supabase/auth/current_auth_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaterTrackingSnapshot {
  final int? targetMl;
  final int amountMl;

  const WaterTrackingSnapshot({required this.targetMl, required this.amountMl});
}

abstract interface class WaterTrackingLocalStore {
  Future<WaterTrackingSnapshot> load(DateTime localDay);

  Future<void> saveTargetMl(int targetMl);

  Future<void> saveAmountMl(DateTime localDay, int amountMl);
}

/// Actor-scoped local storage for non-sensitive hydration wellness values.
///
/// Cloud merge deliberately stays outside this adapter until its DD/RLS contract
/// is approved. The actor is always resolved from the trusted session boundary;
/// callers never supply an actor to a read or write operation.
final class SharedPreferencesWaterTrackingLocalStore
    implements WaterTrackingLocalStore {
  final String? Function() _currentUserId;

  const SharedPreferencesWaterTrackingLocalStore({
    String? Function()? currentUserId,
  }) : _currentUserId = currentUserId ?? currentSupabaseUserIdOrNull;

  static const _keyPrefix = 'wellness.water.v2';
  static const _guestNamespace = 'guest:install';

  @override
  Future<WaterTrackingSnapshot> load(DateTime localDay) async {
    final actorNamespace = _actorNamespace();
    final preferences = await SharedPreferences.getInstance();
    return WaterTrackingSnapshot(
      targetMl: preferences.getInt(_targetKey(actorNamespace)),
      amountMl: preferences.getInt(_amountKey(actorNamespace, localDay)) ?? 0,
    );
  }

  @override
  Future<void> saveTargetMl(int targetMl) async {
    final actorNamespace = _actorNamespace();
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setInt(
      _targetKey(actorNamespace),
      targetMl,
    );
    if (!saved) throw StateError('Unable to persist hydration target.');
  }

  @override
  Future<void> saveAmountMl(DateTime localDay, int amountMl) async {
    final actorNamespace = _actorNamespace();
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setInt(
      _amountKey(actorNamespace, localDay),
      amountMl,
    );
    if (!saved) throw StateError('Unable to persist hydration amount.');
  }

  String _actorNamespace() {
    final userId = _currentUserId()?.trim();
    return userId == null || userId.isEmpty
        ? _guestNamespace
        : 'member:$userId';
  }

  static String _targetKey(String actorNamespace) =>
      '$_keyPrefix.$actorNamespace.target_ml';

  static String _amountKey(String actorNamespace, DateTime day) {
    final year = day.year.toString().padLeft(4, '0');
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '$_keyPrefix.$actorNamespace.amount_ml.$year-$month-$date';
  }
}
