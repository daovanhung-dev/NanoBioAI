import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/controllers/admin_controller.dart';

export 'admin_dependencies.dart';

final adminControllerProvider =
    AsyncNotifierProvider<AdminController, AdminPanelState>(
      AdminController.new,
    );
