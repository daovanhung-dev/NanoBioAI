"""Strict push allowlists transcribed from the current sync RPC source.

The lists intentionally exclude server-owned IDs, ownership fields, subjects,
created/updated timestamps, and the read-only wellness point projection.
"""

from __future__ import annotations

CLOUD_COLUMNS: dict[str, frozenset[str]] = {
    "health_profiles": frozenset(
        ("blood_pressure", "blood_sugar", "bmi", "height_cm", "id", "occupation", "weight_kg")
    ),
    "lifestyle_habits": frozenset(
        (
            "activity_level",
            "alcohol",
            "coffee_high",
            "eat_late",
            "eat_oily",
            "eat_sweet",
            "fast_food",
            "id",
            "low_vegetable",
            "low_water",
            "skip_breakfast",
            "sleep_quality",
            "water_per_day",
        )
    ),
    "nutrition_profiles": frozenset(
        (
            "alcohol_frequency",
            "average_sleep_hours",
            "birth_date",
            "coffee_frequency",
            "current_status",
            "id",
            "nocturia_level",
            "schema_version",
            "smoking_amount_note",
            "smoking_status",
            "target_weight_kg",
            "target_weight_source",
            "waist_cm",
            "water_restriction",
            "water_restriction_note",
        )
    ),
    "health_goals": frozenset(("goal_code", "goal_name", "id", "is_active")),
    "health_conditions": frozenset(("condition_code", "condition_name", "id", "severity_level")),
    "food_allergies": frozenset(("allergy_name", "id", "note")),
    "medical_treatments": frozenset(("id", "medication_name", "note", "treatment_name")),
    "survey_answers": frozenset(("answer_value", "id", "question_code")),
    "meal_plans": frozenset(
        (
            "ai_generated",
            "allergen_tags_json",
            "avoid_condition_tags_json",
            "benefits",
            "calories",
            "carbs",
            "catalog_code",
            "cooking_instructions",
            "cooking_steps_json",
            "description",
            "end_time",
            "fat",
            "fiber",
            "health_topic_code",
            "health_topic_name",
            "id",
            "ingredients_json",
            "is_completed",
            "meal_name",
            "meal_order",
            "meal_type",
            "plan_date",
            "protein",
            "replacement_count",
            "serving_size",
            "snapshot_schema_version",
            "source_hash",
            "source_name",
            "source_page",
            "start_time",
            "water_ml",
        )
    ),
    "daily_health_tasks": frozenset(
        (
            "category",
            "current_value",
            "description",
            "encouragement",
            "id",
            "is_completed",
            "sort_order",
            "source",
            "target_value",
            "task_code",
            "task_date",
            "title",
            "unit",
        )
    ),
    "lifestyle_schedule_items": frozenset(
        (
            "ai_generated",
            "category",
            "current_value",
            "description",
            "encouragement",
            "end_time",
            "id",
            "is_completed",
            "schedule_date",
            "sort_order",
            "source_id",
            "source_type",
            "start_time",
            "target_value",
            "title",
            "unit",
        )
    ),
    "notifications": frozenset(
        (
            "action_status",
            "body",
            "id",
            "is_read",
            "notification_id",
            "payload",
            "responded_at",
            "scheduled_at",
            "source_id",
            "source_type",
            "title",
            "type",
        )
    ),
    "health_tracking_logs": frozenset(
        (
            "calories",
            "daily_score",
            "heart_rate_bpm",
            "id",
            "log_date",
            "mood",
            "oxygen_saturation",
            "sleep_hours",
            "steps_count",
            "stress_level",
            "water_ml",
            "weight_kg",
        )
    ),
    "health_score_ledgers": frozenset(
        (
            "breakdown",
            "calculated_at",
            "formula_version",
            "id",
            "idempotency_key",
            "period_end",
            "period_start",
            "score",
        )
    ),
    "nutrition_logs": frozenset(
        ("calories", "carbs", "eaten_at", "fat", "food_name", "id", "meal_type", "protein")
    ),
    "ai_insights": frozenset(("content", "id", "insight_type", "risk_level", "title")),
    "ai_recommendations": frozenset(
        ("action_text", "description", "id", "is_read", "recommendation_type", "title")
    ),
    "health_symptoms": frozenset(
        (
            "body_location",
            "id",
            "impact_note",
            "is_active",
            "note",
            "severity_level",
            "started_at",
            "symptom_type",
            "trigger_note",
        )
    ),
    "medication_records": frozenset(
        (
            "id",
            "is_active",
            "name",
            "note",
            "prescriber_confirmed",
            "product_type",
            "usage_schedule",
        )
    ),
    "food_restrictions": frozenset(
        ("id", "is_active", "item_name", "note", "restriction_type", "severity_level")
    ),
    "lab_results": frozenset(
        (
            "id",
            "measured_at",
            "note",
            "reference_note",
            "test_code",
            "test_name",
            "unit",
            "value_text",
        )
    ),
    "nutrition_goals": frozenset(
        ("goal_code", "goal_name", "id", "is_active", "priority", "target_date", "target_period")
    ),
    "meal_schedule_preferences": frozenset(
        (
            "end_time",
            "id",
            "is_active",
            "meal_type",
            "note",
            "portion_note",
            "start_time",
            "target_calories",
        )
    ),
    "nutrition_preference_rules": frozenset(
        (
            "id",
            "is_active",
            "item_code",
            "item_name",
            "note",
            "preference_level",
            "rule_type",
            "schema_version",
        )
    ),
    "fitness_training_programs": frozenset(
        (
            "active_week",
            "created_at",
            "id",
            "parent_program_id",
            "program_json",
            "quota_committed",
            "request_id",
            "status",
            "updated_at",
        )
    ),
    "personal_schedule_ai_requests": frozenset(
        (
            "actor_mode",
            "completed_at",
            "days",
            "error_code",
            "exercise_count",
            "meal_count",
            "request_id",
            "schedule_item_count",
            "start_date",
            "status",
        )
    ),
    "users": frozenset(
        (
            "avatar_url",
            "birth_year",
            "full_name",
            "gender",
            "onboarding_completed_at",
            "onboarding_status",
        )
    ),
}

PUSH_TABLES = frozenset(name for name in CLOUD_COLUMNS if name != "users")
USER_PROFILE_COLUMNS = CLOUD_COLUMNS["users"]
BOOLEAN_COLUMNS = frozenset(
    {
        "is_active",
        "is_completed",
        "ai_generated",
        "is_read",
        "skip_breakfast",
        "eat_late",
        "eat_sweet",
        "eat_oily",
        "low_vegetable",
        "low_water",
        "fast_food",
        "alcohol",
        "coffee_high",
        "water_restriction",
        "prescriber_confirmed",
        "quota_committed",
    }
)
JSON_COLUMNS = frozenset({"payload", "breakdown", "program_json"})
