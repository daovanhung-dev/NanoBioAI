import 'package:nano_app/app_versions/admin/features/admin_panel/data/datasources/admin_supabase_datasource.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminSupabaseDatasource datasource;

  const AdminRepositoryImpl({required this.datasource});

  @override
  Stream<void> watchAuthChanges() => datasource.watchAuthChanges();

  @override
  bool get hasValidSession => datasource.hasValidSession;

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) {
    return datasource.signInWithEmail(email: email, password: password);
  }

  @override
  Future<void> signOut() {
    return datasource.signOut();
  }

  @override
  Future<AdminSession> fetchSession() {
    return datasource.fetchSession();
  }

  @override
  Future<List<AdminDashboardMetric>> fetchDashboardSummary({
    required DateTime from,
    required DateTime to,
    required String scope,
    required String timeZone,
  }) {
    return datasource.fetchDashboardSummary(
      from: from,
      to: to,
      scope: scope,
      timeZone: timeZone,
    );
  }

  @override
  Future<List<AdminWorkItem>> fetchSectionItems({
    required AdminPanelSection section,
    required String query,
  }) {
    return datasource.fetchSectionItems(section: section, query: query);
  }

  @override
  Future<List<AdminAuditEvent>> fetchAuditEvents({required String query}) {
    return datasource.fetchAuditEvents(query: query);
  }

  @override
  Future<AdminMutationResult> runMutation(AdminMutationCommand command) {
    return datasource.runMutation(command);
  }
}
