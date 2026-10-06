import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_dynamic_entity.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/dashboard_dynamic_provider.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/dashboard_provider.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/services/supabase/cloud_sync/cloud_sync.dart';

void main() {
  testWidgets('pending cloud recovery restores the dashboard after retry', (
    tester,
  ) async {
    final harness = _RecoveryHarness(
      initialStatus: UserDataSyncStatus.syncing,
      pendingStatus: UserDataSyncStatus.error,
    );
    await _pumpRecoveryPage(tester, harness);

    expect(find.byKey(const ValueKey('dashboard-error')), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await _pumpRetry(tester);

    expect(harness.refreshCount, 1);
    expect(harness.retryCount, 1);
    expect(find.byKey(const ValueKey('dashboard-ready')), findsOneWidget);
  });

  testWidgets('failed cloud recovery keeps local data and recovery guidance', (
    tester,
  ) async {
    final harness = _RecoveryHarness(
      pendingStatus: UserDataSyncStatus.pendingUpload,
      retrySucceeds: false,
    );
    final retainedProfileData = harness.localProfileData;
    await _pumpRecoveryPage(tester, harness);

    await tester.tap(find.text('Thử lại'));
    await _pumpRetry(tester);

    expect(harness.retryCount, 1);
    expect(harness.localProfileData, same(retainedProfileData));
    expect(
      find.textContaining('Chưa thể khôi phục dữ liệu tài khoản'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('dashboard-error')), findsOneWidget);
  });

  testWidgets('dashboard retry skips cloud when sync is not pending', (
    tester,
  ) async {
    final harness = _RecoveryHarness(pendingStatus: UserDataSyncStatus.idle);
    await _pumpRecoveryPage(tester, harness);

    await tester.tap(find.text('Thử lại'));
    await _pumpRetry(tester);

    expect(harness.refreshCount, 1);
    expect(harness.retryCount, 0);
    expect(find.byKey(const ValueKey('dashboard-error')), findsOneWidget);
  });
}

Future<void> _pumpRecoveryPage(
  WidgetTester tester,
  _RecoveryHarness harness,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dashboardProvider.overrideWith((ref) async {
          harness.dashboardLoadCount++;
          if (harness.retrySucceeded) return _dashboard;
          throw StateError('local dashboard profile unavailable');
        }),
        dashboardDynamicProvider.overrideWith(
          (ref) async => DashboardDynamicEntity.empty(),
        ),
        userDataSyncControllerProvider.overrideWith(
          () => _FakeUserDataSyncController(harness),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const DashboardPage(showStandaloneChatButton: false),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  expect(find.byKey(const ValueKey('dashboard-error')), findsOneWidget);
}

Future<void> _pumpRetry(WidgetTester tester) async {
  for (var index = 0; index < 6; index++) {
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));
}

final _dashboard = DashboardEntity(
  userId: 'qa-user',
  fullName: 'QA User',
  email: '',
  phone: '',
  gender: '',
  birthYear: 1990,
  occupation: '',
  heightCm: 170,
  weightKg: 65,
  bmi: 22.5,
  goals: const [],
  conditions: const [],
  habits: const [],
  sleepQuality: '',
  activityLevel: '',
  waterPerDay: '',
  allergyName: '',
  allergyNote: '',
  treatmentName: '',
  medicationName: '',
  treatmentNote: '',
  concernText: '',
  surveyAnswers: const {},
);

class _RecoveryHarness {
  _RecoveryHarness({
    this.initialStatus = UserDataSyncStatus.idle,
    required this.pendingStatus,
    this.retrySucceeds = true,
  });

  final UserDataSyncStatus initialStatus;
  final UserDataSyncStatus pendingStatus;
  final bool retrySucceeds;
  int refreshCount = 0;
  int retryCount = 0;
  int dashboardLoadCount = 0;
  final Object localProfileData = Object();

  bool get retrySucceeded => retryCount > 0 && retrySucceeds;
}

class _FakeUserDataSyncController extends UserDataSyncController {
  _FakeUserDataSyncController(this.harness);

  final _RecoveryHarness harness;

  @override
  UserDataSyncState build() => UserDataSyncState(status: harness.initialStatus);

  @override
  Future<void> refreshLocalStatus() async {
    harness.refreshCount++;
    state = UserDataSyncState(status: harness.pendingStatus);
  }

  @override
  Future<UserDataSyncOutcome> retry() async {
    harness.retryCount++;
    final status = harness.retrySucceeds
        ? UserDataSyncStatus.success
        : UserDataSyncStatus.error;
    state = UserDataSyncState(status: status);
    return UserDataSyncOutcome(
      userId: 'qa-user',
      reason: AuthSyncReason.manualRetry,
      status: status,
      pushedLocalGuestData: false,
      cloudHasMeaningfulData: true,
      pulledTables: harness.retrySucceeds ? const ['users'] : const [],
      pendingCount: 0,
    );
  }
}
