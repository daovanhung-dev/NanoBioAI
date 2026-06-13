import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/theme/primitives/button.dart';
import 'package:nano_app/core/theme/tokens/color_tokens.dart';
import 'package:nano_app/core/theme/tokens/spacing_tokens.dart';
import 'package:nano_app/core/theme/tokens/component_tokens.dart';

void main() {
  group('AppButton', () {
    testWidgets('primary variant renders with correct styling',
        (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              variant: ButtonVariant.primary,
              onPressed: () => pressed = true,
              child: const Text('Primary Button'),
            ),
          ),
        ),
      );

      // Verify button exists
      expect(find.text('Primary Button'), findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);

      // Verify button is tappable
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();
      expect(pressed, isTrue);

      // Verify minimum height constraint
      final container = tester.widget<AnimatedContainer>(
        find.ancestor(
          of: find.byType(Material),
          matching: find.byType(AnimatedContainer),
        ).first,
      );
      expect(
        container.constraints?.minHeight,
        equals(AppSpacingTokens.buttonMinHeight),
      );
    });

    testWidgets('secondary variant renders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              variant: ButtonVariant.secondary,
              onPressed: () {},
              child: const Text('Secondary Button'),
            ),
          ),
        ),
      );

      expect(find.text('Secondary Button'), findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);
    });

    testWidgets('text variant renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              variant: ButtonVariant.text,
              onPressed: () {},
              child: const Text('Text Button'),
            ),
          ),
        ),
      );

      expect(find.text('Text Button'), findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);
    });

    testWidgets('icon variant renders with icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              variant: ButtonVariant.icon,
              onPressed: () {},
              icon: Icons.favorite,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);

      // Verify touch target size
      final container = tester.widget<AnimatedContainer>(
        find.ancestor(
          of: find.byType(Material),
          matching: find.byType(AnimatedContainer),
        ).first,
      );
      expect(
        container.constraints?.minWidth,
        equals(AppSpacingTokens.touchTargetMin),
      );
      expect(
        container.constraints?.minHeight,
        equals(AppSpacingTokens.touchTargetMin),
      );
    });

    testWidgets('outlined variant renders with border',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              variant: ButtonVariant.outlined,
              onPressed: () {},
              child: const Text('Outlined Button'),
            ),
          ),
        ),
      );

      expect(find.text('Outlined Button'), findsOneWidget);

      // Verify border decoration exists
      final decoratedBox = tester.widget<Container>(
        find.descendant(
          of: find.byType(InkWell),
          matching: find.byType(Container),
        ),
      );
      expect(decoratedBox.decoration, isA<BoxDecoration>());
      final decoration = decoratedBox.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    testWidgets('loading state shows loading indicator',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              variant: ButtonVariant.primary,
              onPressed: () {},
              loading: true,
              child: const Text('Save'),
            ),
          ),
        ),
      );

      // Text should not be visible
      expect(find.text('Save'), findsNothing);
      // Loading indicator should be visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('disabled state when onPressed is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              variant: ButtonVariant.primary,
              onPressed: null,
              child: const Text('Disabled Button'),
            ),
          ),
        ),
      );

      expect(find.text('Disabled Button'), findsOneWidget);

      // Verify button is not tappable by checking InkWell callback
      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.onTap, isNull);
    });

    testWidgets('button applies correct padding from tokens',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              variant: ButtonVariant.primary,
              onPressed: () {},
              child: const Text('Button'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(InkWell),
          matching: find.byType(Container),
        ),
      );

      expect(
        container.padding,
        equals(
          EdgeInsets.symmetric(
            horizontal: AppSpacingTokens.buttonPaddingH,
            vertical: AppSpacingTokens.buttonPaddingV,
          ),
        ),
      );
    });

    testWidgets('button applies correct border radius from tokens',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              variant: ButtonVariant.primary,
              onPressed: () {},
              child: const Text('Button'),
            ),
          ),
        ),
      );

      final material = tester.widget<Material>(
        find.ancestor(
          of: find.byType(InkWell),
          matching: find.byType(Material),
        ).first,
      );

      expect(
        material.borderRadius,
        equals(BorderRadius.circular(AppRadiusTokens.button)),
      );
    });

    testWidgets('button works in both light and dark mode',
        (WidgetTester tester) async {
      // Test light mode
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: AppButton(
              variant: ButtonVariant.primary,
              onPressed: () {},
              child: const Text('Button'),
            ),
          ),
        ),
      );

      expect(find.text('Button'), findsOneWidget);

      // Test dark mode
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: AppButton(
              variant: ButtonVariant.primary,
              onPressed: () {},
              child: const Text('Button'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Button'), findsOneWidget);
    });

    testWidgets('all button variants can be instantiated',
        (WidgetTester tester) async {
      for (final variant in ButtonVariant.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppButton(
                variant: variant,
                onPressed: () {},
                child: const Text('Test'),
                icon: variant == ButtonVariant.icon ? Icons.star : null,
              ),
            ),
          ),
        );

        expect(find.byType(AppButton), findsOneWidget);
      }
    });

    testWidgets('button respects const constructor where possible',
        (WidgetTester tester) async {
      // This test verifies that the widget can be created as const
      const button = AppButton(
        variant: ButtonVariant.primary,
        onPressed: null,
        child: Text('Const Button'),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: button,
          ),
        ),
      );

      expect(find.text('Const Button'), findsOneWidget);
    });

    test('ButtonVariant enum has all expected variants', () {
      expect(ButtonVariant.values.length, equals(5));
      expect(ButtonVariant.values, contains(ButtonVariant.primary));
      expect(ButtonVariant.values, contains(ButtonVariant.secondary));
      expect(ButtonVariant.values, contains(ButtonVariant.text));
      expect(ButtonVariant.values, contains(ButtonVariant.icon));
      expect(ButtonVariant.values, contains(ButtonVariant.outlined));
    });
  });
}
