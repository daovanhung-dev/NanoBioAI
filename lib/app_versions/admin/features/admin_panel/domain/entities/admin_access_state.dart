import 'admin_models.dart';

enum AdminAccessStatus { checking, authorized, unauthorized, error }

class AdminAccessState {
  final AdminAccessStatus status;
  final AdminSession? session;
  final String? safeMessage;

  const AdminAccessState({
    required this.status,
    this.session,
    this.safeMessage,
  });

  const AdminAccessState.checking()
    : status = AdminAccessStatus.checking,
      session = null,
      safeMessage = null;

  const AdminAccessState.unauthorized()
    : status = AdminAccessStatus.unauthorized,
      session = null,
      safeMessage = null;

  const AdminAccessState.authorized(AdminSession value)
    : status = AdminAccessStatus.authorized,
      session = value,
      safeMessage = null;

  const AdminAccessState.error(String message)
    : status = AdminAccessStatus.error,
      session = null,
      safeMessage = message;

  bool get isAuthorized => status == AdminAccessStatus.authorized;
}

class AdminAccessFailure implements Exception {
  final String message;

  const AdminAccessFailure(this.message);

  @override
  String toString() => message;
}

class AdminAccessRevokedException implements Exception {
  const AdminAccessRevokedException();
}
