import 'dart:math';

import '../data/datasources/food_scan_ai_datasource.dart';
import '../data/datasources/food_scan_health_context_datasource.dart';
import '../data/repositories/food_scan_local_repository.dart';
import '../domain/entities/food_scan_models.dart';
import '../domain/food_scan_exception.dart';
import 'food_scan_health_rule_engine.dart';
import 'food_scan_nutrition_resolver.dart';

class FoodScanService {
  final FoodScanAiDatasource aiDatasource;
  final FoodScanHealthContextDatasource healthContextDatasource;
  final FoodScanLocalRepository localRepository;
  final FoodScanNutritionResolver nutritionResolver;
  final FoodScanHealthRuleEngine ruleEngine;
  final DateTime Function() now;

  FoodScanService({
    FoodScanAiDatasource? aiDatasource,
    FoodScanHealthContextDatasource? healthContextDatasource,
    FoodScanLocalRepository? localRepository,
    FoodScanNutritionResolver? nutritionResolver,
    FoodScanHealthRuleEngine? ruleEngine,
    DateTime Function()? now,
  }) : aiDatasource = aiDatasource ?? const FoodScanAiDatasource(),
       healthContextDatasource =
           healthContextDatasource ?? const FoodScanHealthContextDatasource(),
       localRepository = localRepository ?? FoodScanLocalRepository(),
       nutritionResolver = nutritionResolver ?? const FoodScanNutritionResolver(),
       ruleEngine = ruleEngine ?? const FoodScanHealthRuleEngine(),
       now = now ?? DateTime.now;

  Future<FoodScanResult> analyze({
    required String userId,
    required String imagePath,
  }) async {
    final vision = await aiDatasource.analyzeImage(imagePath);
    if (!vision.isFoodImage) throw const FoodScanException.notFood();

    final resolved = nutritionResolver.resolve(vision.items);
    if (resolved.items.isEmpty || resolved.total.caloriesKcal <= 0) {
      throw const FoodScanException(
        code: 'NUTRITION_UNAVAILABLE',
        userMessage:
            'Nabi đã nhận diện món nhưng chưa đủ dữ liệu để ước tính dinh dưỡng. Bạn thử ảnh rõ hơn hoặc chỉnh khẩu phần nhé.',
      );
    }

    final healthContext = await healthContextDatasource.load(userId);
    final rules = ruleEngine.evaluate(
      healthContext: healthContext,
      items: resolved.items,
    );

    FoodHealthEvaluation health;
    final warnings = <String>[...vision.warnings];
    try {
      health = await aiDatasource.evaluateHealth(
        healthContext: healthContext,
        items: resolved.items,
        totalNutrition: resolved.total,
        deterministicWarnings: rules.warnings,
      );
    } on FoodScanException catch (error) {
      health = FoodHealthEvaluation.insufficient(
        summary: error.userMessage,
        allergyWarnings: rules.warnings,
      );
      warnings.add(
        'Phần dinh dưỡng đã sẵn sàng nhưng đánh giá sức khỏe cần thử lại.',
      );
    }

    final result = FoodScanResult(
      id: _uuidV4(),
      imageLocalPath: imagePath,
      inputType: vision.inputType,
      isFoodImage: true,
      analysisConfidence: vision.confidence,
      items: resolved.items,
      totalNutrition: resolved.total,
      healthEvaluation: health,
      assumptions: vision.assumptions,
      warnings: warnings,
      createdAt: now(),
    );
    await localRepository.saveAnalysis(userId: userId, result: result);
    return result;
  }

  FoodScanResult updateItem({
    required FoodScanResult result,
    required String itemId,
    required String name,
    required double weightGrams,
    required String portionDescription,
  }) {
    final updatedItems = <FoodScanItem>[];
    for (final item in result.items) {
      if (item.id != itemId) {
        updatedItems.add(item);
        continue;
      }
      final renamed = item.copyWith(
        name: name.trim().isEmpty ? item.name : name.trim(),
        normalizedName: FoodScanNutritionResolver.normalizeFoodName(
          name.trim().isEmpty ? item.name : name.trim(),
        ),
        portionDescription: portionDescription,
      );
      updatedItems.add(nutritionResolver.recalculate(renamed, weightGrams));
    }
    final resolved = nutritionResolver.resolve(updatedItems);
    return result.copyWith(
      items: resolved.items,
      totalNutrition: resolved.total,
      healthEvaluation: const FoodHealthEvaluation.insufficient(
        summary:
            'Khẩu phần vừa thay đổi. Bạn cập nhật đánh giá sức khỏe để Nabi phân tích lại.',
      ),
    );
  }

  FoodScanResult removeItem({
    required FoodScanResult result,
    required String itemId,
  }) {
    final remaining = result.items
        .where((item) => item.id != itemId)
        .toList(growable: false);
    final resolved = nutritionResolver.resolve(remaining);
    return result.copyWith(
      items: resolved.items,
      totalNutrition: resolved.total,
      healthEvaluation: const FoodHealthEvaluation.insufficient(
        summary:
            'Danh sách món vừa thay đổi. Bạn cập nhật đánh giá sức khỏe để Nabi phân tích lại.',
      ),
    );
  }

  Future<FoodScanResult> reevaluateHealth({
    required String userId,
    required FoodScanResult result,
  }) async {
    if (result.items.isEmpty) {
      throw const FoodScanException(
        code: 'NO_FOOD_ITEMS',
        userMessage: 'Bạn cần giữ lại ít nhất một món để đánh giá sức khỏe.',
      );
    }
    final context = await healthContextDatasource.load(userId);
    final rules = ruleEngine.evaluate(healthContext: context, items: result.items);
    final health = await aiDatasource.evaluateHealth(
      healthContext: context,
      items: result.items,
      totalNutrition: result.totalNutrition,
      deterministicWarnings: rules.warnings,
    );
    final updated = result.copyWith(healthEvaluation: health);
    await localRepository.saveAnalysis(userId: userId, result: updated);
    return updated;
  }

  Future<void> persistEditedAnalysis({
    required String userId,
    required FoodScanResult result,
  }) {
    return localRepository.saveAnalysis(userId: userId, result: result);
  }

  Future<FoodScanResult> confirmConsumed({
    required String userId,
    required FoodScanResult result,
  }) {
    return localRepository.confirmConsumed(userId: userId, result: result);
  }

  Future<List<FoodScanResult>> history(String userId) {
    return localRepository.history(userId);
  }

  Future<void> deleteHistory({
    required String userId,
    required FoodScanResult result,
  }) {
    return localRepository.deleteHistory(userId: userId, result: result);
  }
}

String _uuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int value) => value.toRadixString(16).padLeft(2, '0');
  final all = bytes.map(hex).join();
  return '${all.substring(0, 8)}-'
      '${all.substring(8, 12)}-'
      '${all.substring(12, 16)}-'
      '${all.substring(16, 20)}-'
      '${all.substring(20)}';
}
