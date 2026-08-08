import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/theme/app_experience.dart';
import 'package:nano_app/core/theme/app_semantic_colors.dart';
import 'package:nano_app/core/theme/app_theme.dart';
import 'package:nano_app/core/theme/medical_ui.dart';

void main() {
  testWidgets('shared medical surfaces resolve semantic dark colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const MedicalPageScaffold(
          ambientBackground: false,
          body: Center(
            child: MedicalSurfaceCard(child: Text('Nabi semantic surface')),
          ),
        ),
      ),
    );

    final context = tester.element(find.text('Nabi semantic surface'));
    final colors = context.semanticColors;
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      colors.background,
    );

    final decorations = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((widget) => widget.decoration)
        .whereType<BoxDecoration>();
    expect(
      decorations.any((decoration) => decoration.color == colors.card),
      isTrue,
    );
  });

  testWidgets('app experience backdrop follows the selected theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        builder: AppExperience.builder,
        home: const Text('Dark experience'),
      ),
    );

    final context = tester.element(find.text('Dark experience'));
    final colors = context.semanticColors;
    expect(
      tester
          .widgetList<ColoredBox>(find.byType(ColoredBox))
          .any((box) => box.color == colors.background),
      isTrue,
    );
  });
}
