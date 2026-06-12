import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// **Validates: Requirements 1.1, 1.2, 2.1, 2.2, 3.1, 4.1, 5.1**
/// 
/// Bug Condition Exploration Tests
/// 
/// **CRITICAL**: These tests MUST FAIL on unfixed code - failure confirms violations exist.
/// **DO NOT attempt to fix the tests or the code when they fail.**
/// **NOTE**: These tests encode expected behavior - they validate the fix when they pass.
/// **GOAL**: Surface counterexamples that demonstrate architecture violations exist.
void main() {
  group('Bug Condition Exploration - Architecture Violations', () {
    
    test('Violation 1: Cross-Feature Dependency - OnboardingController imports DashboardController', () {
      // This test verifies that onboarding_controller.dart imports dashboard_controller.dart
      // EXPECTED: This test FAILS on unfixed code (proving the violation exists)
      
      final file = File('lib/features/onboarding/presentation/controllers/onboarding_controller.dart');
      expect(file.existsSync(), isTrue, reason: 'OnboardingController file should exist');
      
      final content = file.readAsStringSync();
      
      // Check for the cross-feature import
      final hasCrossFeatureImport = content.contains('import') && 
                                     content.contains('dashboard/presentation/controllers/dashboard_controller.dart');
      
      // Check for direct controller call
      final hasDirectCall = content.contains('dashboardControllerProvider');
      
      // ASSERTION: These should be FALSE (no cross-feature dependencies)
      // On UNFIXED code, these will be TRUE, causing the test to FAIL
      expect(hasCrossFeatureImport, isFalse, 
        reason: 'OnboardingController should NOT import DashboardController - violates feature independence');
      
      expect(hasDirectCall, isFalse,
        reason: 'OnboardingController should NOT directly call DashboardController - violates feature independence');
    });

    test('Violation 2: Circular Dependency - AIService imports DashboardEntity while Dashboard imports AIService', () {
      // This test verifies circular dependency between ai_service and dashboard feature
      // EXPECTED: This test FAILS on unfixed code (proving the circular dependency exists)
      
      final aiServiceFile = File('lib/services/ai/ai_service.dart');
      final dashboardControllerFile = File('lib/features/dashboard/presentation/controllers/dashboard_controller.dart');
      
      expect(aiServiceFile.existsSync(), isTrue, reason: 'AIService file should exist');
      expect(dashboardControllerFile.existsSync(), isTrue, reason: 'DashboardController file should exist');
      
      final aiServiceContent = aiServiceFile.readAsStringSync();
      final dashboardContent = dashboardControllerFile.readAsStringSync();
      
      // Check if AIService imports from dashboard feature (service depending on feature - WRONG)
      final aiServiceImportsDashboard = aiServiceContent.contains('import') && 
                                         aiServiceContent.contains('features/dashboard/domain/entities');
      
      // Check if Dashboard imports AIService (feature depending on service - CORRECT)
      final dashboardImportsAI = dashboardContent.contains('import') && 
                                 dashboardContent.contains('services/ai/ai_service.dart');
      
      // ASSERTION: AIService should NOT import dashboard entities
      // On UNFIXED code, this will be TRUE, causing the test to FAIL
      expect(aiServiceImportsDashboard, isFalse,
        reason: 'AIService (core service) should NOT import DashboardEntity (feature entity) - violates dependency direction');
      
      // Dashboard importing AIService is correct (feature -> service)
      expect(dashboardImportsAI, isTrue,
        reason: 'DashboardController correctly imports AIService (feature depends on service)');
    });

    test('Violation 3: Misnamed Datasource - "remote" datasource uses SQLite (local)', () {
      // This test verifies that onboarding_remote_datasource.dart is misnamed (uses SQLite not remote API)
      // EXPECTED: This test FAILS on unfixed code (proving the naming violation exists)
      
      final remoteDatasourceFile = File('lib/features/onboarding/data/datasource/onboarding_remote_datasource.dart');
      final localDatasourceFile = File('lib/features/onboarding/data/datasource/onboarding_local_datasource.dart');
      
      // Check current state
      final remoteExists = remoteDatasourceFile.existsSync();
      final localExists = localDatasourceFile.existsSync();
      
      if (remoteExists) {
        final content = remoteDatasourceFile.readAsStringSync();
        
        // Check if "remote" datasource actually uses SQLite
        final usesSQLite = content.contains('sqflite') || content.contains('DatabaseService');
        
        // ASSERTION: File named "remote" should NOT use SQLite
        // On UNFIXED code, usesSQLite will be TRUE, causing the test to FAIL
        expect(usesSQLite, isFalse,
          reason: 'File named "remote_datasource" should NOT use SQLite - should be renamed to "local_datasource"');
      }
      
      // ASSERTION: Correctly named local_datasource should exist
      // On UNFIXED code, this will be FALSE, causing the test to FAIL
      expect(localExists, isTrue,
        reason: 'Datasource using SQLite should be named "onboarding_local_datasource.dart"');
      
      // ASSERTION: Misnamed remote_datasource should NOT exist
      // On UNFIXED code, this will be TRUE (file exists), causing the test to FAIL
      expect(remoteExists, isFalse,
        reason: 'File "onboarding_remote_datasource.dart" should not exist (should be renamed to local)');
    });

    test('Violation 4: Nested Feature Structure - meal_plan contains nested dashboard folder', () {
      // This test verifies that meal_plan feature has incorrect nested structure
      // EXPECTED: This test FAILS on unfixed code (proving the structure violation exists)
      
      final nestedDashboardDir = Directory('lib/features/meal_plan/dashboard');
      
      // ASSERTION: Nested "dashboard" folder within meal_plan should NOT exist
      // On UNFIXED code, this will be TRUE (directory exists), causing the test to FAIL
      expect(nestedDashboardDir.existsSync(), isFalse,
        reason: 'meal_plan feature should NOT have nested "dashboard" folder - violates flat feature structure');
      
      // Check for correct flat structure
      final mealPlanDataDir = Directory('lib/features/meal_plan/data');
      final mealPlanDomainDir = Directory('lib/features/meal_plan/domain');
      final mealPlanPresentationDir = Directory('lib/features/meal_plan/presentation');
      final mealPlanProvidersDir = Directory('lib/features/meal_plan/providers');
      
      // ASSERTION: Flat structure directories should exist at feature root level
      // On UNFIXED code (with nested structure), these may not exist, causing test to FAIL
      expect(mealPlanDataDir.existsSync() || Directory('lib/features/meal_plan/dashboard/data').existsSync(), 
        isTrue, reason: 'Data layer should exist');
      expect(mealPlanDomainDir.existsSync() || Directory('lib/features/meal_plan/dashboard/domain').existsSync(), 
        isTrue, reason: 'Domain layer should exist');
      expect(mealPlanPresentationDir.existsSync() || Directory('lib/features/meal_plan/dashboard/presentation').existsSync(), 
        isTrue, reason: 'Presentation layer should exist');
        
      // The key assertion: flat structure at root (not nested)
      expect(mealPlanDataDir.existsSync(), isTrue,
        reason: 'Data directory should be at lib/features/meal_plan/data/ (flat structure)');
    });

    test('Violation 5: Misplaced Model - MealPlanModel in core layer instead of feature', () {
      // This test verifies that meal_plan_model.dart is in the wrong layer
      // EXPECTED: This test FAILS on unfixed code (proving the placement violation exists)
      
      final coreModelFile = File('lib/core/storage/localdb/models/meal_plan_model.dart');
      final featureModelFile = File('lib/features/meal_plan/data/models/meal_plan_model.dart');
      
      // ASSERTION: Feature-specific model should NOT be in core layer
      // On UNFIXED code, this will be TRUE (file exists in core), causing the test to FAIL
      expect(coreModelFile.existsSync(), isFalse,
        reason: 'MealPlanModel should NOT be in core layer - it is feature-specific');
      
      // ASSERTION: Feature-specific model should be in its feature's data/models directory
      // On UNFIXED code, this will be FALSE, causing the test to FAIL
      expect(featureModelFile.existsSync(), isTrue,
        reason: 'MealPlanModel should be in lib/features/meal_plan/data/models/meal_plan_model.dart');
    });

    test('Integration: Detect all violations together', () {
      // This test aggregates all violations to provide a comprehensive view
      // EXPECTED: This test FAILS on unfixed code with multiple violation findings
      
      final violations = <String>[];
      
      // Check Violation 1: Cross-feature dependency
      final onboardingFile = File('lib/features/onboarding/presentation/controllers/onboarding_controller.dart');
      if (onboardingFile.existsSync()) {
        final content = onboardingFile.readAsStringSync();
        if (content.contains('dashboard/presentation/controllers/dashboard_controller.dart')) {
          violations.add('Violation 1: OnboardingController imports DashboardController (line ~4)');
        }
        if (content.contains('dashboardControllerProvider')) {
          violations.add('Violation 1: OnboardingController calls dashboardControllerProvider directly (line ~302)');
        }
      }
      
      // Check Violation 2: Circular dependency
      final aiServiceFile = File('lib/services/ai/ai_service.dart');
      if (aiServiceFile.existsSync()) {
        final content = aiServiceFile.readAsStringSync();
        if (content.contains('features/dashboard/domain/entities')) {
          violations.add('Violation 2: AIService imports DashboardEntity from feature (line ~9)');
        }
      }
      
      // Check Violation 3: Misnamed datasource
      final remoteDatasource = File('lib/features/onboarding/data/datasource/onboarding_remote_datasource.dart');
      if (remoteDatasource.existsSync()) {
        final content = remoteDatasource.readAsStringSync();
        if (content.contains('sqflite') || content.contains('DatabaseService')) {
          violations.add('Violation 3: onboarding_remote_datasource.dart uses SQLite but named "remote"');
        }
      }
      
      // Check Violation 4: Nested structure
      if (Directory('lib/features/meal_plan/dashboard').existsSync()) {
        violations.add('Violation 4: Nested "dashboard" folder within meal_plan feature');
      }
      
      // Check Violation 5: Misplaced model
      if (File('lib/core/storage/localdb/models/meal_plan_model.dart').existsSync()) {
        violations.add('Violation 5: MealPlanModel in core layer instead of meal_plan feature');
      }
      
      // Print all violations for debugging
      if (violations.isNotEmpty) {
        print('\n========================================');
        print('ARCHITECTURE VIOLATIONS DETECTED:');
        print('========================================');
        for (var i = 0; i < violations.length; i++) {
          print('${i + 1}. ${violations[i]}');
        }
        print('========================================\n');
      }
      
      // ASSERTION: No violations should exist
      // On UNFIXED code, violations list will be non-empty, causing the test to FAIL
      expect(violations, isEmpty,
        reason: 'Architecture violations detected - see printed list above');
    });
  });
}
