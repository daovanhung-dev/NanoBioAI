import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/services/supabase/auth/account_security_service.dart';

final accountSecurityServiceProvider = Provider<AccountSecurityService>((ref) {
  return AccountSecurityService();
});

final accountSecurityControllerProvider =
    AsyncNotifierProvider<AccountSecurityController, void>(
      AccountSecurityController.new,
    );

class AccountSecurityController extends AsyncNotifier<void> {
  AccountSecurityService get _service =>
      ref.read(accountSecurityServiceProvider);

  @override
  Future<void> build() async {}

  Future<void> updatePassword(String newPassword) {
    return _run(() => _service.updatePassword(newPassword));
  }

  Future<void> signOut() {
    return _run(_service.signOut);
  }

  Future<void> requestAccountDeletion() {
    return _run(_service.requestAccountDeletion);
  }

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncValue.loading();
    try {
      await action();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
