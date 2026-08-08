import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/admin/app/bio_ai_admin_app.dart';
import 'package:nano_app/app_versions/admin/router/admin_route_paths.dart';
import 'package:nano_app/app_versions/admin/router/admin_router.dart';
import 'package:nano_app/app_versions/admin/theme/admin_workspace_theme.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AdminWorkspaceTheme', () {
    test('light theme keeps the independent blue workspace identity', () {
      final theme = AdminWorkspaceTheme.light(AppTheme.lightTheme);
      final colors = theme.extension<AdminWorkspaceColors>();

      expect(theme.brightness, Brightness.light);
      expect(colors, isNotNull);
      expect(colors!.blue, const Color(0xFF3478D4));
      expect(colors.blue, isNot(AppSemanticColors.light.primary));
      expect(theme.colorScheme.primary, colors.blue);
      expect(theme.scaffoldBackgroundColor, colors.canvas);
      expect(theme.textTheme.bodyMedium?.fontFamily, AppTextStyles.fontFamily);
    });

    test('dark theme uses deterministic readable Admin semantic roles', () {
      final theme = AdminWorkspaceTheme.dark(AppTheme.darkTheme);
      final colors = theme.extension<AdminWorkspaceColors>();

      expect(theme.brightness, Brightness.dark);
      expect(colors, same(AdminWorkspaceColors.dark));
      expect(theme.colorScheme.primary, colors!.blue);
      expect(theme.scaffoldBackgroundColor, colors.canvas);
      expect(_contrast(colors.text, colors.canvas), greaterThanOrEqualTo(7));
      expect(
        _contrast(colors.textSecondary, colors.panel),
        greaterThanOrEqualTo(4.5),
      );
      expect(_contrast(colors.blue, colors.panel), greaterThanOrEqualTo(4.5));
      expect(
        _contrast(colors.onDangerContainer, colors.dangerContainer),
        greaterThanOrEqualTo(4.5),
      );
    });

    testWidgets('context palette follows MaterialApp theme mode', (
      tester,
    ) async {
      late AdminWorkspaceColors resolved;

      await tester.pumpWidget(
        MaterialApp(
          theme: AdminWorkspaceTheme.light(AppTheme.lightTheme),
          darkTheme: AdminWorkspaceTheme.dark(AppTheme.darkTheme),
          themeMode: ThemeMode.dark,
          home: Builder(
            builder: (context) {
              resolved = context.adminColors;
              return ColoredBox(
                color: resolved.canvas,
                child: const SizedBox.expand(),
              );
            },
          ),
        ),
      );

      expect(resolved, same(AdminWorkspaceColors.dark));
      expect(
        tester.widget<ColoredBox>(find.byType(ColoredBox).last).color,
        AdminWorkspaceColors.dark.canvas,
      );
    });

    testWidgets('Admin app follows the persisted dark-mode setting', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(const {'theme_mode': 'dark'});
      adminRouter.go(AdminRoutePaths.login);
      addTearDown(() => adminRouter.go(AdminRoutePaths.dashboard));

      await tester.pumpWidget(const ProviderScope(child: BioAIAdminApp()));
      await tester.pumpAndSettle();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
      final scaffoldContext = tester.element(find.byType(Scaffold).first);
      expect(Theme.of(scaffoldContext).brightness, Brightness.dark);
      expect(scaffoldContext.adminColors, same(AdminWorkspaceColors.dark));
    });
  });
}

double _contrast(Color foreground, Color background) {
  final light = foreground.computeLuminance();
  final dark = background.computeLuminance();
  final high = light > dark ? light : dark;
  final low = light > dark ? dark : light;
  return (high + .05) / (low + .05);
}
