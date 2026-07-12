import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_access_state.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/controllers/admin_access_controller.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/controllers/admin_controller.dart';

export 'admin_dependencies.dart';

final adminAccessControllerProvider =
    AsyncNotifierProvider<AdminAccessController, AdminAccessState>(
      AdminAccessController.new,
    );

final adminControllerProvider =
    AsyncNotifierProvider<AdminController, AdminPanelState>(
      AdminController.new,
    );
