import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_access_state.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/controllers/admin_access_controller.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/controllers/admin_accounts_controller.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/controllers/admin_controller.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/controllers/admin_membership_controller.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/controllers/admin_sales_controller.dart';

export 'admin_dependencies.dart';

final adminAccessControllerProvider =
    AsyncNotifierProvider<AdminAccessController, AdminAccessState>(
      AdminAccessController.new,
    );

// Legacy provider remains for compatibility with source-only legacy admin pages.
final adminControllerProvider =
    AsyncNotifierProvider<AdminController, AdminPanelState>(
      AdminController.new,
    );

final adminAccountsControllerProvider =
    AsyncNotifierProvider<AdminAccountsController, AdminAccountsState>(
      AdminAccountsController.new,
    );

final adminSalesControllerProvider =
    AsyncNotifierProvider<AdminSalesController, AdminSalesState>(
      AdminSalesController.new,
    );

final adminMembershipControllerProvider =
    AsyncNotifierProvider<AdminMembershipController, AdminMembershipReviewState>(
      AdminMembershipController.new,
    );
