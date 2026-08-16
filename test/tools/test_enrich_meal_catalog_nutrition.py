import importlib.util
from pathlib import Path
import unittest
import sys

MODULE = Path(__file__).resolve().parents[2] / "tools/enrich_meal_catalog_nutrition.py"
spec = importlib.util.spec_from_file_location("nutrition", MODULE)
nutrition = importlib.util.module_from_spec(spec)
assert spec.loader
sys.modules[spec.name] = nutrition
spec.loader.exec_module(nutrition)

class EstimatorTest(unittest.TestCase):
    def test_banana_cashew_smoothie_has_per_serving_nutrition(self):
        value = nutrition.estimate([
            "1 quả chuối chín", "30g hạt điều", "200ml sữa hạnh nhân", "1 thìa mật ong"
        ], "Sinh tố chuối hạt điều")
        self.assertIsNotNone(value)
        self.assertGreater(value["calories"], 250)
        self.assertGreater(value["protein"], 5)
        self.assertEqual(value["nutrition_status"], "estimated_from_ingredients")
        self.assertEqual(value["serving_size"], "1 khẩu phần (ước tính)")

    def test_unquantified_seasoning_is_not_invented(self):
        value = nutrition.estimate(["200g thịt bò", "Gia vị: muối, tiêu, dầu ăn"], "Bò áp chảo")
        self.assertIsNotNone(value)
        self.assertLess(value["sodium_mg"], 200)

    def test_unknown_recipe_stays_missing(self):
        self.assertIsNone(nutrition.estimate(["Gia vị vừa ăn"], "Món thử"))

if __name__ == "__main__":
    unittest.main()
