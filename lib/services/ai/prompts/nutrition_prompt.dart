import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:nano_app/services/ai/ai_service.dart';
import 'package:nano_app/services/ai/models/ai_meal_response_model.dart';
final nutritionPromptProvider = Provider<NutritionPrompt>((ref) {
  return NutritionPrompt();
});
class NutritionPrompt {
  static String generateMealPlan({required DashboardEntity healthData}) {
    try {
      final prompt =
          '''
      Generate a 7-day personalized meal plan.

      Return ONLY valid JSON.

      Format:

      [
        {
          "id": "uuid",
          "user_id": "1",
          "plan_date": "2026-05-24",
          "meal_type": "breakfast",
          "meal_name": "Oatmeal with Banana",
          "description": "Healthy breakfast",
          "calories": 350,
          "protein": 12.5,
          "carbs": 45.0,
          "fat": 8.0,
          "fiber": 6.0,
          "water_ml": 300,
          "meal_order": 1,
          "is_completed": 0,
          "ai_generated": 1,
          "created_at": "2026-05-24T08:00:00Z",
          "updated_at": "2026-05-24T08:00:00Z"
        }
      ]

      User Health Data:

      Full Name: ${healthData.fullName}

      BMI: ${healthData.bmi}

      Goals:
      ${healthData.goals.join(', ')}

      Conditions:
      ${healthData.conditions.join(', ')}

      Habits:
      ${healthData.habits.join(', ')}

      Sleep:
      ${healthData.sleepQuality}

      Activity:
      ${healthData.activityLevel}

      Water:
      ${healthData.waterPerDay}

      Concern:
      ${healthData.concernText}
      ''';



    return prompt;

    } catch (e) {
      throw Exception('Failed to generate meal plan: $e');
    }
  }
}
