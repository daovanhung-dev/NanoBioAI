import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_access_state.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/controllers/admin_access_controller.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_providers.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/dashboard_provider.dart';
import 'package:nano_app/app_versions/v1/features/settings/domain/entities/settings_preferences_entity.dart';
import 'package:nano_app/app_versions/v1/features/settings/presentation/pages/settings_page.dart';
import 'package:nano_app/app_versions/v1/features/settings/presentation/widgets/guest_account_access_card.dart';
import 'package:nano_app/app_versions/v1/features/settings/providers/settings_provider.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';
import 'package:nano_app/sale_referral/domain/entities/sale_models.dart';
import 'package:nano_app/sale_referral/providers/sale_providers.dart';

final _testAuthUserIdProvider =
    NotifierProvider<_TestAuthUserIdController, String?>(
      _TestAuthUserIdController.new,
    );

void main() {
  testWidgets(
    'removes the guest account card as soon as auth identity arrives',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          currentAuthUserIdProvider.overrideWith(
            (ref) => ref.watch(_testAuthUserIdProvider),
          ),
          dashboardProvider.overrideWithValue(const AsyncData(_testDashboard)),
          settingsPreferencesControllerProvider.overrideWith(
            _TestSettingsPreferencesController.new,
          ),
          settingsCacheSizeProvider.overrideWithValue(const AsyncData(0)),
          saleStateProvider.overrideWithValue(const AsyncData(SaleState.none)),
          adminAccessControllerProvider.overrideWith(
            _TestAdminAccessController.new,
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SettingsView()),
        ),
      );
      await tester.pump();

      expect(find.byType(GuestAccountAccessCard), findsOneWidget);

      container.read(_testAuthUserIdProvider.notifier).signIn('user-1');
      await tester.pump();

      expect(find.byType(GuestAccountAccessCard), findsNothing);
    },
  );
}

class _TestAuthUserIdController extends Notifier<String?> {
  @override
  String? build() => null;

  void signIn(String userId) {
    state = userId;
  }
}

class _TestSettingsPreferencesController extends SettingsPreferencesController {
  @override
  Future<SettingsPreferencesEntity> build() async {
    return SettingsPreferencesEntity.defaults();
  }
}

class _TestAdminAccessController extends AdminAccessController {
  @override
  Future<AdminAccessState> build() async {
    return const AdminAccessState.unauthorized();
  }
}

const _testDashboard = DashboardEntity(
  userId: 'user-1',
  fullName: 'Nabi Test',
  email: 'nabi@example.com',
  phone: '',
  gender: '',
  birthYear: 1990,
  occupation: '',
  heightCm: 0,
  weightKg: 0,
  bmi: 0,
  goals: [],
  conditions: [],
  habits: [],
  sleepQuality: '',
  activityLevel: '',
  waterPerDay: '',
  allergyName: '',
  allergyNote: '',
  treatmentName: '',
  medicationName: '',
  treatmentNote: '',
  concernText: '',
  surveyAnswers: {},
);
