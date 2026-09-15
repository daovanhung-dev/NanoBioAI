import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_access_state.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/controllers/admin_access_controller.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_providers.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/dashboard_provider.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/main_navigation_state_provider.dart';
import 'package:nano_app/app_versions/v1/features/settings/domain/entities/settings_preferences_entity.dart';
import 'package:nano_app/app_versions/v1/features/settings/presentation/pages/notification_settings_page.dart';
import 'package:nano_app/app_versions/v1/features/settings/presentation/pages/settings_page.dart';
import 'package:nano_app/app_versions/v1/features/settings/providers/notification_settings_provider.dart';
import 'package:nano_app/app_versions/v1/features/settings/providers/settings_provider.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/app_versions/v1/router/v1_router.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';
import 'package:nano_app/sale_referral/domain/entities/sale_models.dart';
import 'package:nano_app/sale_referral/providers/sale_providers.dart';
import 'package:nano_app/features/nabi/domain/notifications/nabi_health_reminder_preferences.dart';

void main() {
  testWidgets('settings exposes a separate button into notification manager', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsView(),
        ),
        GoRoute(
          path: V1RoutePaths.notificationSettings,
          builder: (context, state) => const NotificationSettingsPage(),
        ),
      ],
    );
    final container = _createContainer();
    addTearDown(() {
      router.dispose();
      container.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('settings_manage_notifications')),
      findsOneWidget,
    );
    expect(find.text('Thông báo'), findsOneWidget);
    expect(
      find.byKey(const Key('settings_notifications_switch')),
      findsOneWidget,
    );

    final manageButton = find.byKey(const Key('settings_manage_notifications'));
    await tester.ensureVisible(manageButton);
    await tester.pump();
    await tester.tap(manageButton);
    await tester.pumpAndSettle();

    expect(find.byType(NotificationSettingsPage), findsOneWidget);
    expect(
      find.byKey(const Key('notification_settings_back_button')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('notification_settings_back_button')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SettingsView), findsOneWidget);
  });

  testWidgets('direct notification deep link falls back to settings tab', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: V1RoutePaths.notificationSettings,
      routes: v1Routes,
    );
    final container = _createContainer();
    addTearDown(() {
      router.dispose();
      container.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const Key('notification_settings_back_button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(router.routeInformationProvider.value.uri.path, V1RoutePaths.menu);
    expect(
      router.routeInformationProvider.value.uri.queryParameters['tab'],
      'settings',
    );
    expect(container.read(mainNavigationIndexProvider), 3);
  });

  testWidgets('menu settings query starts on the Của bạn tab', (tester) async {
    final router = GoRouter(
      initialLocation: '${V1RoutePaths.menu}?tab=settings',
      routes: v1Routes,
    );
    final container = _createContainer();
    addTearDown(() {
      router.dispose();
      container.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    expect(container.read(mainNavigationIndexProvider), 3);
    expect(find.byType(SettingsView), findsOneWidget);
    expect(find.text('Tài khoản'), findsOneWidget);
  });
}

ProviderContainer _createContainer() {
  return ProviderContainer(
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
      notificationSettingsControllerProvider.overrideWith(
        _TestNotificationSettingsController.new,
      ),
    ],
  );
}

final _testAuthUserIdProvider =
    NotifierProvider<_TestAuthUserIdController, String?>(
      _TestAuthUserIdController.new,
    );

class _TestAuthUserIdController extends Notifier<String?> {
  @override
  String? build() => null;
}

class _TestSettingsPreferencesController extends SettingsPreferencesController {
  @override
  Future<SettingsPreferencesEntity> build() async {
    return SettingsPreferencesEntity.defaults();
  }
}

class _TestNotificationSettingsController
    extends NotificationSettingsController {
  @override
  Future<NabiHealthReminderPreferences> build() async {
    return NabiHealthReminderPreferences.defaults(
      actorKey: 'test-actor',
      legacyPushEnabled: false,
    );
  }
}

class _TestAdminAccessController extends AdminAccessController {
  @override
  Future<AdminAccessState> build() async {
    return const AdminAccessState.unauthorized();
  }
}

const _testDashboard = DashboardEntity(
  userId: 'test-user',
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
