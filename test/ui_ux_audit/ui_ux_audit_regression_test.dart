import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String source(String path) {
    final file = File(path);
    expect(file.existsSync(), isTrue, reason: 'Missing source file: $path');
    return file.readAsStringSync();
  }

  group('UI/UX audit regression guards', () {
    test('Quick Care exposes a real local start/stop interaction', () {
      final content = source(
        'lib/app_versions/v1/features/quick_care/presentation/pages/quick_care_page.dart',
      );
      expect(content, contains('void _start()'));
      expect(content, contains('void _stop()'));
      expect(content, contains('Timer'));
    });

    test('Weekly Summary reads real schedule state', () {
      final content = source(
        'lib/app_versions/v1/features/weekly_summary/presentation/pages/weekly_summary_page.dart',
      );
      expect(content, contains('lifestyleScheduleControllerProvider'));
      expect(content, contains('state.summary.items'));
      expect(content, isNot(contains('healthScore = 82')));
    });

    test('Today Tasks reacts to time boundaries and app resume', () {
      final content = source(
        'lib/app_versions/v1/features/today_tasks/presentation/pages/today_tasks_page.dart',
      );
      expect(content, contains('WidgetsBindingObserver'));
      expect(content, contains('_scheduleBoundaryRefresh'));
      expect(content, contains('AppLifecycleState.resumed'));
      expect(content, contains('_boundaryTimer?.cancel()'));
    });

    test('Profile invalidation reaches body metrics', () {
      final content = source(
        'lib/app_versions/v1/features/settings/providers/settings_provider.dart',
      );
      expect(content, contains('bodyMetricsPersonalContextProvider'));
      expect(content, contains('bodyMetricsControllerProvider'));
    });

    test('Gentle Care does not claim that the plan was changed', () {
      final content = source(
        'lib/app_versions/v1/features/gentle_care_mode/presentation/pages/gentle_care_mode_page.dart',
      );
      expect(content, contains('không tự động giảm nhiệm vụ hoặc thay đổi lịch'));
    });

    test('Sale participation preserves trusted error state', () {
      final content = source(
        'lib/sale_referral/presentation/pages/sale_participation_page.dart',
      );
      expect(content, contains('sale-participation-error'));
      expect(content, contains('onRetry'));
    });

    test('Auth gate and account commands are single-flight', () {
      final gate = source(
        'lib/app_versions/v2/features/auth/presentation/pages/auth_gate_page.dart',
      );
      final controller = source(
        'lib/app_versions/v2/features/auth/presentation/controllers/auth_controller.dart',
      );
      expect(gate, contains('_applyingGuestAction'));
      expect(gate, contains('_signingOut'));
      expect(controller, contains('_signUpInFlight'));
      expect(controller, contains('_signInInFlight'));
    });

    test('FamilyPlus and Advanced Tracking mutations are guarded', () {
      final familyProvider = source(
        'lib/app_versions/v3/features/familyplus/providers/familyplus_providers.dart',
      );
      final familyPage = source(
        'lib/app_versions/v3/features/familyplus/presentation/pages/familyplus_page.dart',
      );
      final advanced = source(
        'lib/app_versions/v3/features/advanced_tracking/presentation/pages/advanced_tracking_page.dart',
      );
      expect(familyProvider, contains('_createGroupInFlight'));
      expect(familyProvider, contains('_createGroupIdempotencyKey'));
      expect(familyPage, contains('_creating'));
      expect(advanced, contains('_creating'));
    });

    test('Settings refresh reports partial and total failure', () {
      final content = source(
        'lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart',
      );
      expect(content, contains('_refreshSettings'));
      expect(content, contains('AppFeedbackType.warning'));
      expect(content, contains('AppFeedbackType.error'));
      expect(content, contains('Một vài thông tin chưa cập nhật được'));
    });

    test('AI Chat respects theme system bars and reading position', () {
      final content = source(
        'lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart',
      );
      expect(content, contains('Theme.of(context).brightness'));
      expect(content, contains('_nearBottom'));
      expect(content, contains('Tin nhắn mới'));
    });

    test('Meal Plan uses one replacement picker and visible back action', () {
      final content = source(
        'lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart',
      );
      expect(content, contains('showMealReplacementPicker'));
      expect(content, isNot(contains('class _MealReplacementSheet')));
      expect(content, contains('Navigator.of(context).maybePop'));
      expect(content, contains('MediaQuery.textScalerOf'));
    });

    test('Daily Health route owns daily health UI instead of schedule alias', () {
      final content = source(
        'lib/app_versions/v1/features/daily_health_tracking/presentation/pages/daily_health_tracking_page.dart',
      );
      expect(content, contains('dailyHealthTrackingControllerProvider'));
      expect(content, isNot(contains('LifestyleSchedulePage(')));
    });

    test('Consumer copy does not leak audited implementation terms', () {
      final paths = [
        'lib/app_versions/v1/features/body_metrics/presentation/pages/body_metrics_page.dart',
        'lib/app_versions/v1/features/personal_goals/presentation/pages/personal_goals_page.dart',
        'lib/app_versions/v1/features/water_tracking/presentation/pages/water_tracking_page.dart',
        'lib/sale_referral/presentation/pages/sale_shell_page.dart',
      ];
      final forbidden = [
        'deterministic',
        'Read-only',
        'feature sở hữu',
        'contract tương ứng',
        'giới hạn lưu trữ kỹ thuật',
        'dùng dashboard',
      ];
      for (final path in paths) {
        final content = source(path);
        for (final term in forbidden) {
          expect(
            content,
            isNot(contains(term)),
            reason: '$path leaks internal copy: $term',
          );
        }
      }
    });

    test('Proof gallery memoizes file resolution and bounds thumbnail decode', () {
      final content = source(
        'lib/app_versions/v1/features/lifestyle_schedule/presentation/pages/schedule_proof_gallery_page.dart',
      );
      expect(content, contains('late Future'));
      expect(content, contains('cacheWidth'));
      expect(content, contains('cacheHeight'));
      expect(
        content,
        isNot(contains('future: service.resolveProofFile(proof.localPath)')),
      );
    });

    test('Feature and nutrition grids adapt to width and text scale', () {
      final features = source(
        'lib/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart',
      );
      final nutrition = source(
        'lib/app_versions/v1/features/nutrition/presentation/pages/nutrition_page.dart',
      );
      expect(features, contains('MediaQuery.textScalerOf'));
      expect(features, contains('minTileWidth'));
      expect(nutrition, contains('MediaQuery.textScalerOf'));
      expect(nutrition, contains('Wrap('));
      expect(nutrition, isNot(contains('childAspectRatio')));
    });

    test('Main navigation uses distinct Nabi contexts', () {
      final content = source(
        'lib/app_versions/v1/features/dashboard/presentation/pages/menu_page.dart',
      );
      expect(content, contains("'/features'"));
      expect(content, contains("'/settings'"));
      expect(content, contains("'/health-insights'"));
    });

    test('Admin dialogs scroll and presentation does not upload to Supabase', () {
      final dialogs = source(
        'lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_dialogs.dart',
      );
      final page = source(
        'lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart',
      );
      final datasource = source(
        'lib/app_versions/admin/features/admin_panel/data/datasources/admin_payout_proof_remote_datasource.dart',
      );
      expect(dialogs, contains('SingleChildScrollView'));
      expect(page, isNot(contains('supabase_flutter')));
      expect(page, isNot(contains('Supabase.instance.client.storage')));
      expect(datasource, contains('Supabase.instance.client.storage'));
    });

    test('Health module keeps return stack and Health Score keeps stale data', () {
      final access = source(
        'lib/app_versions/v2/features/health_modules/presentation/pages/health_module_access_page.dart',
      );
      final score = source(
        'lib/app_versions/v2/features/health_scoring/presentation/pages/health_score_habits_page.dart',
      );
      expect(access, isNot(contains('pushReplacement')));
      expect(access, contains('await context.push'));
      expect(score, contains('skipLoadingOnRefresh: true'));
      expect(score, contains('AppFeedbackType.warning'));
    });

    test('Dashboard refresh is gated by active tab', () {
      final content = source(
        'lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart',
      );
      expect(content, contains('mainNavigationIndexProvider'));
      expect(content, contains('_isVisibleInMainShell'));
    });

    test('Onboarding no longer contains a fake default result score', () {
      final result = source(
        'lib/app_versions/v1/features/onboarding/presentation/widgets/result_step.dart',
      );
      final shell = source(
        'lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_page.dart',
      );
      expect(result, isNot(contains('healthScore = 82')));
      expect(result, contains('double? healthScore'));
      expect(shell, isNot(contains("debugPrint('Onboarding build")));
    });

    test('Splash uses an explicit recoverable bootstrap failure state', () {
      final content = source(
        'lib/app_versions/v1/features/splash/presentation/pages/splash_page.dart',
      );
      expect(content, contains('_errorMessage'));
      expect(content, contains('onRetry: _bootstrap'));
      expect(content, isNot(contains('return false; // fail open')));
    });

    test('Settings is registered as a design surface', () {
      final content = source('.codex/design/12_UI_FILE_DESIGN_MATRIX.md');
      expect(content, contains('V1-X11 Settings / Của bạn'));
      expect(content, contains('81 surface registry'));
    });

    test('Nabi Care and AI Voice use canonical consumer naming', () {
      final care = source(
        'lib/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart',
      );
      final voice = source(
        'lib/app_versions/v1/features/ai_voice/presentation/pages/ai_voice_page.dart',
      );
      expect(care, contains("title: 'Nabi Care'"));
      expect(care, isNot(contains("title: 'Nami Care'")));
      expect(voice, isNot(contains('NaBi')));
    });

    test('Admin touch targets are at least 48dp', () {
      final content = source(
        'lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_shell.dart',
      );
      expect(content, isNot(contains('minHeight: 42')));
      expect(content, isNot(contains('minHeight: 44')));
      expect(content, contains('minHeight: 48'));
    });

    test('V1/V2/V3 share canonical route factories', () {
      final factories = source('lib/app/router/shared_route_factories.dart');
      final v1 = source('lib/app_versions/v1/router/v1_router.dart');
      final v2 = source('lib/app_versions/v2/router/v2_router.dart');
      final v3 = source('lib/app_versions/v3/router/v3_router.dart');
      expect(factories, contains('buildLifestyleScheduleRoute'));
      expect(factories, contains('buildV2LoginRoute'));
      expect(factories, contains('buildMembershipPaymentRoute'));
      expect(v1, contains('buildLifestyleScheduleRoute()'));
      expect(v2, contains('buildV2LoginRoute()'));
      expect(v3, contains('buildV2LoginRoute()'));
    });

    test('AI Voice pushes chat so Back can return to Voice', () {
      final content = source(
        'lib/app_versions/v1/features/ai_voice/presentation/pages/ai_voice_page.dart',
      );
      expect(content, contains('context.push(V1RoutePaths.aiChat)'));
      expect(content, isNot(contains('context.go(V1RoutePaths.aiChat)')));
    });
  });
}
