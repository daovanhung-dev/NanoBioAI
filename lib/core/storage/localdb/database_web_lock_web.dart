import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

const _databaseLockName = 'nanobio-local-database';

bool _databaseLockHeld = false;

Future<void> acquireWebDatabaseSessionLock() async {
  if (_databaseLockHeld) return;

  final acquired = Completer<bool>();
  final releaseLock = Completer<JSAny?>();
  JSAny? onLockGranted(web.Lock? lock) {
    if (lock == null) {
      if (!acquired.isCompleted) acquired.complete(false);
      return null;
    }

    if (!acquired.isCompleted) acquired.complete(true);
    return releaseLock.future.toJS;
  }

  try {
    final request = web.window.navigator.locks.request(
      _databaseLockName,
      web.LockOptions(mode: 'exclusive', ifAvailable: true),
      onLockGranted.toJS,
    );
    unawaited(
      request.toDart.then<void>(
        (_) {},
        onError: (Object error, StackTrace stackTrace) {
          if (!acquired.isCompleted) acquired.completeError(error, stackTrace);
        },
      ),
    );

    final hasLock = await acquired.future.timeout(const Duration(seconds: 5));
    if (!hasLock) {
      throw StateError(
        'NanoBio đang mở ở tab khác. Hãy đóng tab kia rồi tải lại trang này.',
      );
    }
    _databaseLockHeld = true;
  } catch (error) {
    if (error is StateError &&
        error.message ==
            'NanoBio đang mở ở tab khác. Hãy đóng tab kia rồi tải lại trang này.') {
      rethrow;
    }
    throw StateError(
      'Trình duyệt này chưa thể mở dữ liệu an toàn. Hãy dùng phiên bản Safari hoặc Chrome mới nhất qua kết nối HTTPS.',
    );
  }
}
