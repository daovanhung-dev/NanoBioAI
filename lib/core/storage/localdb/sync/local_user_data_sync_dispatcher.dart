import 'package:sqflite/sqflite.dart';

/// A version-neutral signal emitted after a user-owned SQLite write commits.
///
/// The local transaction and SQLite outbox remain durable even when no handler
/// is registered. The application entrypoint registers its cloud-sync handler
/// after the backend session has been restored.
typedef LocalUserDataSyncRequest = void Function({Database? database});

class LocalUserDataSyncDispatcher {
  LocalUserDataSyncDispatcher._();

  static LocalUserDataSyncRequest? _request;

  static void register(LocalUserDataSyncRequest request) {
    _request = request;
  }

  static void requestImmediateSync({Database? database}) {
    _request?.call(database: database);
  }
}
