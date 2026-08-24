import 'package:nano_app/core/constants/routes/food_scan_route_paths.dart';

abstract class V3RoutePaths {
  static const home = '/v3';
  static const advancedTracking = '/v3/advanced-tracking';
  static const familyPlus = '/v3/familyplus';
  static const foodScan = FoodScanRoutePaths.scan;
  static const foodScanHistory = FoodScanRoutePaths.history;
}
