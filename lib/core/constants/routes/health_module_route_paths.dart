abstract class HealthModuleRoutePaths {
  static const base = '/v2/health-modules';
  static const detailPattern = '$base/:moduleId';
  static const detailRouteName = 'v2-health-module-detail';

  static String detail(String moduleId) {
    final normalizedModuleId = moduleId.trim().toUpperCase();
    return '$base/${Uri.encodeComponent(normalizedModuleId)}';
  }

  static bool matchesProtectedPrefix(String path) {
    final normalizedPath = path.trim();
    return normalizedPath == base || normalizedPath.startsWith('$base/');
  }
}
