import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/router/v2_router.dart';
import 'package:nano_app/core/constants/routes/health_module_route_paths.dart';

void main() {
  group('HealthModuleRoutePaths', () {
    test('builds one normalized dynamic detail route', () {
      expect(HealthModuleRoutePaths.detail(' m20 '), '/v2/health-modules/M20');
      expect(
        HealthModuleRoutePaths.detailPattern,
        '/v2/health-modules/:moduleId',
      );
    });
  });

  group('V2RouteGuards', () {
    test('protects the dynamic route with a segment boundary', () {
      expect(V2RouteGuards.isProtectedPath('/v2/health-modules/M20'), isTrue);
      expect(V2RouteGuards.isProtectedPath('/v2/health-modules'), isTrue);
      expect(
        V2RouteGuards.isProtectedPath('/v2/health-modules-unsafe/M20'),
        isFalse,
      );
      expect(V2RouteGuards.isProtectedPath('/v2/health-modulesx/M20'), isFalse);
    });
  });
}
