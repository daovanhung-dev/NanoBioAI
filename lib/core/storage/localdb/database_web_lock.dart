import 'database_web_lock_stub.dart'
    if (dart.library.js_interop) 'database_web_lock_web.dart'
    as platform;

Future<void> acquireWebDatabaseSessionLock() =>
    platform.acquireWebDatabaseSessionLock();
