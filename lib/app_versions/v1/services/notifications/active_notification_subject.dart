import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';

typedef ActiveNotificationSubjectReader = Future<String?> Function();

/// Resolves the single subject whose local reminders may act on this device.
///
/// A requested subject is used only by an explicit caller. Otherwise, an
/// authenticated session wins over the pending guest subject so a stale guest
/// reminder cannot act after sign-in.
Future<String?> resolveActiveNotificationSubject({
  String? requestedSubjectUserId,
}) async {
  final requested = _nonEmpty(requestedSubjectUserId);
  if (requested != null) return requested;

  final authenticated = _nonEmpty(currentSupabaseUserIdOrNull());
  if (authenticated != null) return authenticated;

  return _nonEmpty(await AppPrefs.pendingGuestUserId());
}

String? _nonEmpty(String? value) {
  final text = value?.trim();
  return text == null || text.isEmpty ? null : text;
}
