import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_codec;
import 'package:nano_app/app_versions/v1/services/ai/ai_text_client.dart';
import 'package:nano_app/app_versions/v3/features/food_scan/data/datasources/food_scan_ai_datasource.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('food_scan_ai_');
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  test('shrinks only the AI input and uses a compact output budget', () async {
    final source = File('${root.path}/meal.jpg');
    final original = image_codec.Image(width: 1800, height: 1200);
    image_codec.fill(original, color: image_codec.ColorRgb8(190, 120, 60));
    final originalBytes = image_codec.encodeJpg(original);
    await source.writeAsBytes(originalBytes);
    final client = _CapturingAiClient();

    final analysis = await FoodScanAiDatasource(
      clientOverride: client,
    ).analyzeImage(source.path);

    final submittedImage = image_codec.decodeJpg(
      client.message!.images.single.bytes,
    );
    final storedImage = image_codec.decodeJpg(await source.readAsBytes());
    expect(submittedImage, isNotNull);
    expect(submittedImage!.width, foodScanVisionMaxImageDimension);
    expect(submittedImage.height, 683);
    expect(storedImage!.width, 1800);
    expect(await source.readAsBytes(), originalBytes);
    expect(client.generationConfig!.maxOutputTokens, 192);
    expect(analysis.items.single.name, 'Bánh mì');
    expect(analysis.items.single.nutrition.fiberG, isNull);
  });
}

class _CapturingAiClient implements AiTextClient {
  AiMessage? message;
  AiGenerationConfig? generationConfig;

  @override
  Future<String> generateText({
    required String model,
    required List<AiMessage> messages,
    required AiGenerationConfig generationConfig,
    String? systemInstruction,
  }) async {
    message = messages.single;
    this.generationConfig = generationConfig;
    return jsonEncode({
      'is_food_image': true,
      'input_type': 'cooked_meal',
      'image_quality': 'good',
      'image_quality_reason': '',
      'analysis_confidence': 0.8,
      'foods': [
        {
          'name': 'Bánh mì',
          'normalized_hint': 'banh mi',
          'estimated_weight_g': 180,
          'portion_description': '1 ổ',
          'cooking_method': '',
          'ingredients': ['bánh mì'],
          'possible_allergens': ['lúa mì'],
          'confidence': 0.8,
          'fallback_nutrition': {
            'calories_kcal': 420,
            'protein_g': 18,
            'carbohydrates_g': 48,
            'fat_g': 16,
            'fiber_g': null,
            'sugar_g': null,
            'sodium_mg': null,
          },
        },
      ],
      'assumptions': [],
      'warnings': [],
    });
  }

  @override
  Stream<String> streamText({
    required String model,
    required List<AiMessage> messages,
    required AiGenerationConfig generationConfig,
    String? systemInstruction,
  }) async* {
    yield await generateText(
      model: model,
      messages: messages,
      generationConfig: generationConfig,
      systemInstruction: systemInstruction,
    );
  }
}
