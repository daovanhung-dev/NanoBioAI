class NutritionPrompt {

  static String generateMealPlan({
    required Map<String, dynamic>
        healthData,
  }) {

    return '''
You are an expert nutrition AI.

Generate a personalized 7-day meal plan.

User Health Data:
$healthData

Rules:
- Return ONLY valid JSON
- No markdown
- No explanation
- Healthy Vietnamese meals
- Include calories
- Include macros
- Include hydration
- Focus on user's goal

JSON FORMAT:

{
  "days": [
    {
      "date": "2026-05-23",
      "meals": [
        {
          "meal_type": "breakfast",
          "meal_name": "string",
          "description": "string",
          "calories": 0,
          "protein": 0,
          "carbs": 0,
          "fat": 0,
          "fiber": 0,
          "water_ml": 0,
          "meal_order": 1
        }
      ]
    }
  ]
}
''';

  }

}