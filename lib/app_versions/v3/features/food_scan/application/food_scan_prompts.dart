import 'dart:convert';

import '../domain/entities/food_scan_models.dart';

class FoodScanPrompts {
  const FoodScanPrompts._();

  static const visionPromptVersion = 'food_vision_v6_2026_10';
  static const healthPromptVersion = 'food_health_v1_2026_08';

  static String vision() => '''
Analyze the food photo. Return one compact JSON object only, without Markdown. Write text values in Vietnamese. Set input_type to cooked_meal, raw_food, packaged_food, nutrition_label, beverage, mixed, not_food, or unclear. A visible edible item is food even when it is plain bread, a roll, bun, baguette, sandwich, fruit, snack, or drink. A hand or background does not make it not_food. If its exact name is unclear, use a general Vietnamese food name. Keep separate foods separate and mention only visible ingredients. Do not diagnose disease.

For each visible food, estimate its portion weight in grams and calories/macros for that portion. Always include calories_kcal, protein_g, carbohydrates_g, and fat_g as JSON numbers, never text or null. Calories must be greater than zero; macro grams must be zero or greater, and use zero only when appropriate for the visible food. These are approximate estimates. Estimate the actual visible portion; do not invent hidden ingredients. List only visually supported ingredients and plausible allergens in their arrays; never say a food is allergy-safe. Omit optional nutrients you cannot estimate from the image. If the image is not food, set is_food_image=false and foods=[].

Use this short shape and include its required keys:
{"is_food_image":true,"input_type":"cooked_meal","analysis_confidence":0.8,"foods":[{"name":"Bánh mì","normalized_hint":"banh mi","estimated_weight_g":120,"portion_description":"1 ổ bánh mì","ingredients":[],"possible_allergens":[],"fallback_nutrition":{"calories_kcal":320,"protein_g":10,"carbohydrates_g":55,"fat_g":6}}]}
''';

  static String visionNutritionFallback(List<FoodScanItem> items) {
    final foods = items
        .asMap()
        .entries
        .map(
          (entry) => {
            'index': entry.key,
            'name': entry.value.name,
            'estimated_weight_g': entry.value.estimatedWeightGrams,
            'portion_description': entry.value.portionDescription,
          },
        )
        .toList(growable: false);

    return '''
Estimate approximate calories and macros for each already-identified visible food portion below. Use only the listed food and weight; do not add hidden ingredients or extra foods. Keep the same order and index. Return only one compact JSON object, with numeric values (not strings or null) for all four fields. Calories must be greater than zero; macros must be zero or greater. These are estimates, not measured values.
INPUT
${jsonEncode({'foods': foods})}
OUTPUT SHAPE
{"foods":[{"index":0,"calories_kcal":320,"protein_g":10,"carbohydrates_g":55,"fat_g":6}]}
''';
  }

  static String health({
    required Map<String, Object?> healthContext,
    required List<FoodScanItem> items,
    required NutritionEstimate totalNutrition,
    required List<String> deterministicWarnings,
  }) {
    final mealContext = {
      'foods': items.map((item) => item.toJson()).toList(growable: false),
      'total_nutrition': totalNutrition.toJson(),
    };
    return '''
SYSTEM ROLE
Bạn là Nabi Health Meal Review Engine của NanoBio.

NHIỆM VỤ
Đánh giá mức độ phù hợp của bữa ăn với chính hồ sơ sức khỏe đã cung cấp.
Đây là hỗ trợ thông tin sức khỏe, KHÔNG phải chẩn đoán và KHÔNG thay thế bác sĩ.

LANGUAGE
Toàn bộ text trả về phải bằng tiếng Việt.

QUY TẮC BẮT BUỘC
1. Chỉ dùng dữ liệu được cung cấp.
2. Không tự tạo bệnh lý, dị ứng, thuốc hay xét nghiệm mới.
3. Không tự khẳng định tương tác thuốc-thực phẩm nếu input không đủ căn cứ.
4. Deterministic warnings có ưu tiên cao hơn suy luận của bạn.
5. Nếu dữ liệu thiếu, ghi rõ thiếu dữ liệu.
6. Không nói "an toàn tuyệt đối" hoặc "100% an toàn".
7. Không khuyên người dùng tự ngừng/bỏ/dừng thuốc.
8. Không thay đổi phác đồ điều trị.
9. Với dị ứng/ingredient không chắc chắn, dùng diễn đạt "có khả năng chứa".
10. Phân tích riêng từng bệnh lý rồi mới tổng hợp.
11. Không nói một món ăn có thể chữa khỏi bệnh.

USER_HEALTH_CONTEXT
${jsonEncode(healthContext)}

MEAL_CONTEXT
${jsonEncode(mealContext)}

RULE_ENGINE_CONTEXT
${jsonEncode({'deterministic_warnings': deterministicWarnings})}

TASK A — TỔNG THỂ
status chỉ được là:
phu_hop, tuong_doi_phu_hop, can_nhac, nen_han_che, khong_phu_hop, thieu_du_lieu.
Trả suitability_score 0..100 và summary_vi ngắn gọn.

TASK B — THEO TỪNG BỆNH/TÌNH TRẠNG
Với từng condition thực sự có trong context, trả reasons, nutrients_of_concern,
ingredients_of_concern và suggested_adjustments.

TASK C — DỊ ỨNG
status: detected, possible, no_evidence hoặc unknown. Không dùng từ "safe".

TASK D — MỤC TIÊU DINH DƯỠNG
So sánh với mục tiêu/ngữ cảnh ngày nếu input có dữ liệu. Không tự bịa target.

TASK E — GỢI Ý
Đề xuất thay đổi thực tế như giảm khẩu phần, giảm sốt, tăng rau, đổi cách chế biến;
không can thiệp điều trị y khoa.

OUTPUT
Chỉ trả đúng một JSON object, không Markdown, không code fence:
{
  "overall": {
    "status": "can_nhac",
    "suitability_score": 60,
    "summary_vi": ""
  },
  "conditions": [
    {
      "condition_code": "",
      "condition_name": "",
      "status": "can_nhac",
      "reasons": [],
      "nutrients_of_concern": [],
      "ingredients_of_concern": [],
      "suggested_adjustments": []
    }
  ],
  "allergy_review": [
    {
      "allergy": "",
      "status": "possible",
      "reason": ""
    }
  ],
  "daily_goal_review": {
    "summary_vi": "",
    "items": [
      {
        "label": "Năng lượng",
        "current": "",
        "target": "",
        "unit": "",
        "assessment_vi": ""
      }
    ]
  },
  "suggested_adjustments": [],
  "important_assumptions": [],
  "missing_health_data": [],
  "confidence": 0.8
}
''';
  }
}
