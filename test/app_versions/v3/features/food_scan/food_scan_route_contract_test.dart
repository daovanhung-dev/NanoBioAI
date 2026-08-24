import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v3/router/v3_route_paths.dart';
import 'package:nano_app/core/constants/routes/food_scan_route_paths.dart';

void main() {
  test('V3 Food Scan routes use the shared route contract', () {
    expect(V3RoutePaths.foodScan, FoodScanRoutePaths.scan);
    expect(V3RoutePaths.foodScanHistory, FoodScanRoutePaths.history);
  });
}
