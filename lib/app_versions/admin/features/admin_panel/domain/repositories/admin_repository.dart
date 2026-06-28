import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart';

abstract class AdminRepository {
  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<AdminSession> fetchSession();

  Future<List<AdminDashboardMetric>> fetchDashboardSummary({
    required DateTime from,
    required DateTime to,
    required String scope,
  });

  Future<List<AdminWorkItem>> fetchSectionItems({
    required AdminPanelSection section,
    required String query,
  });

  Future<List<AdminAuditEvent>> fetchAuditEvents({required String query});

  Future<AdminMutationResult> runMutation(AdminMutationCommand command);
}
