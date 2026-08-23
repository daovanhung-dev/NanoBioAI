-- Expected result for every query below: 0 violating rows.

-- Estimated recipes must have positive energy and a serving label.
select count(*) as estimated_missing_required_fields
from public.meal_catalog
where nutrition_status = 'estimated_from_ingredients'
  and (
    calories <= 0
    or nullif(btrim(serving_size), '') is null
  );

-- No nutrient may be negative. Null means unknown and is allowed for micronutrients.
select count(*) as negative_nutrient_rows
from public.meal_catalog
where calories < 0 or protein < 0 or carbs < 0 or fat < 0 or fiber < 0 or water_ml < 0
   or coalesce(sugar_g, 0) < 0
   or coalesce(saturated_fat_g, 0) < 0
   or coalesce(sodium_mg, 0) < 0
   or coalesce(cholesterol_mg, 0) < 0
   or coalesce(potassium_mg, 0) < 0
   or coalesce(calcium_mg, 0) < 0
   or coalesce(iron_mg, 0) < 0;

-- Estimated rows cannot be a fake all-zero nutrition record.
select count(*) as estimated_all_zero_rows
from public.meal_catalog
where nutrition_status = 'estimated_from_ingredients'
  and calories = 0
  and protein = 0
  and carbs = 0
  and fat = 0
  and fiber = 0
  and coalesce(sugar_g, 0) = 0
  and coalesce(saturated_fat_g, 0) = 0
  and coalesce(sodium_mg, 0) = 0
  and coalesce(cholesterol_mg, 0) = 0
  and coalesce(potassium_mg, 0) = 0
  and coalesce(calcium_mg, 0) = 0
  and coalesce(iron_mg, 0) = 0;

-- Broad sanity check. It is intentionally tolerant because fiber, rounding and
-- recipe preparation can make label calories differ from 4/4/9 macro energy.
select count(*) as macro_calorie_sanity_failures
from public.meal_catalog
where nutrition_status = 'estimated_from_ingredients'
  and calories > 0
  and (protein > 0 or carbs > 0 or fat > 0)
  and (
    (protein * 4 + carbs * 4 + fat * 9) < calories * 0.45
    or (protein * 4 + carbs * 4 + fat * 9) > calories * 1.65
  );

-- Status contract.
select count(*) as unsupported_nutrition_status
from public.meal_catalog
where nutrition_status not in (
  'approved',
  'missing_source_data',
  'estimated_from_ingredients'
);

select
  nutrition_status,
  count(*) as recipe_count,
  round(avg(calories)::numeric, 1) as avg_calories
from public.meal_catalog
group by nutrition_status
order by nutrition_status;
