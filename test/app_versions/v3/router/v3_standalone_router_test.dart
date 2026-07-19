import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/app_versions/v3/router/v3_router.dart';

void main() {
  test('standalone V3 router includes the V1 lifestyle schedule deep link', () {
    final standalonePaths = v3StandaloneRoutes
        .whereType<GoRoute>()
        .map((route) => route.path)
        .toSet();
    final embeddedV3Paths = v3Routes
        .whereType<GoRoute>()
        .map((route) => route.path)
        .toSet();

    expect(standalonePaths, contains(V1RoutePaths.lifestyleSchedule));
    expect(embeddedV3Paths, isNot(contains(V1RoutePaths.lifestyleSchedule)));
  });
}
