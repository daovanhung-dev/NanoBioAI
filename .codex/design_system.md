# Design System Context

## Current state

The project has a custom theme/design system under `lib/core/theme`.

There are two related layers in practice:

1. Old/backward-compatible classes exported by `core/theme/theme.dart`, heavily used by current UI:
   - `AppColors`
   - `AppTextStyles`
   - `AppTheme`
   - `AppSpacing`
   - `AppRadius`
   - `AppShadows`
   - `AppGradients`
   - `AppAnimations`
   - `AppDuration`
   - `AppIcons`
   - `AppDecoration`
   - `AppTypography`
2. New three-layer design system exported by `core/theme/design_system.dart`:
   - foundation tokens
   - semantic tokens
   - primitive components

README and `IMPLEMENTATION_STATUS.md` describe design system as in progress, about 60% complete. Tokens and primitives are implemented; feature screen refactors are not complete.

## Import choice

For existing feature code, most current files import:

```dart
import 'package:nano_app/core/theme/theme.dart';
```

For new/refactored primitive-based UI, design system docs recommend:

```dart
import 'package:nano_app/core/theme/design_system.dart';
```

When editing an existing screen, follow the import/pattern already used in that file unless deliberately refactoring design system usage.

## Old-compatible theme classes

`AppTheme.lightTheme` is the only app theme currently wired in `BioAIApp`.

`AppColors`:

- Brand: primary blue `#3B82F6`, secondary cyan `#06B6D4`, tertiary purple.
- Status: success, warning, error, info and soft variants.
- Surfaces: background/scaffold/surface/card/input.
- Dark variants exist but app does not currently wire a dark theme.
- Text colors: primary, secondary, muted, hint, disabled, inverse.
- Aliases exist for backward compatibility.

`AppDecoration`:

- Helpers for card, elevatedCard, premiumCard, container, input, focusedInput, errorInput, button, gradient, glass, dialog, bottomSheet, circle, outlined, adaptive.

`AppAnimations`:

- Helpers for fade, slide, scale, rotate, size, fadeScale, fadeSlide, animatedOpacity, animatedScale, animatedContainer, switcher, transitions, stagger.

`AppIcons`:

- Central Material icon aliases for app/nav/health/AI/chart/media/actions/status.

## New three-layer design system

Source docs:

- `lib/core/theme/IMPLEMENTATION_STATUS.md`
- `lib/core/theme/design_system.dart`

Layer 1 foundation:

- `foundation/colors.dart`: `ColorFoundation`, `GradientFoundation`.
- `foundation/spacing.dart`: base-8 scale.
- `foundation/radius.dart`: 0, 4, 8, 12, 16, 24, full.
- `foundation/shadows.dart`: small/medium/large + dark.
- `foundation/typography.dart`: Roboto sizes/weights/line heights.
- `foundation/motion.dart`: fast 150ms, normal 250ms, slow 350ms; ease curves.

Layer 2 semantic:

- `tokens/color_tokens.dart`: `AppColorTokens`.
- `tokens/spacing_tokens.dart`: `AppSpacingTokens`.
- `tokens/component_tokens.dart`: `AppRadiusTokens`, `AppShadowTokens`, `AppMotionTokens`, `AppTextStyles`.

Layer 3 primitives:

- `AppButton` with `ButtonVariant`: primary, secondary, text, icon, outlined.
- `AppCard` with `CardVariant`.
- `AppChip` with `ChipVariant`.
- `AppInput` with `InputVariant`.
- `AppBadge` with `BadgeVariant`, `BadgeStatus`.
- `SectionHeader`.
- `EmptyState`.
- `LoadingState` with `LoadingVariant`.
- `ErrorState`.

## Existing UI usage

Currently modern screens use many hand-written widgets plus old theme tokens:

- Splash: heavy gradient/glass/animated orb UI.
- Login: glass card, inline hardcoded colors, `_BackgroundOrbs`; TODO says refactor.
- Onboarding: many custom step widgets and custom chips/inputs; TODO in design status says not refactored.
- Dashboard: many extracted widgets, uses `AppColors`, `AppSpacing`, `AppDuration`, `AppAnimations`.
- Meal Plan: large single file, responsive helper, uses old theme classes.
- AI Chat: uses old theme classes and custom animated background/FAB.
- Settings: hardcoded UI + old theme classes, no data wiring.

## Design refactor guidance

From `IMPLEMENTATION_STATUS.md`, preferred rules:

- Use semantic tokens, not foundation tokens directly in features.
- Prefer primitive components over custom buttons/cards/inputs/chips.
- Avoid hardcoded colors/spacing/radius/shadows when refactoring.
- Support light/dark if building new reusable components.
- Use const constructors where possible.

Practical repo-specific guidance:

- Do not perform a broad UI refactor casually. Many UI files are large and animated.
- If touching a feature screen for behavior, keep styling changes minimal.
- If explicitly refactoring UI, do it step-by-step and run widget tests/analyze.

## Known design TODOs

`docs/todo/login_ui_refactor_todo.md`:

- Split login into layout/header/form/input/buttons/social/register/decorative components.
- Move validation out of UI.
- Reuse design system tokens.
- Move form UI state toward Riverpod.

`docs/todo/ui_todo_dashboard.md`:

- Dashboard was already partly split into widgets, but TODO asks further extraction/chart/model refactor.
- Notes say UI stable; prioritize flow first.

`lib/core/theme/IMPLEMENTATION_STATUS.md`:

- Onboarding flow refactor pending.
- Feature screens refactor pending.
- Backward compatibility/migration guide pending.
- Documentation/performance/final validation pending.

## Tests related to design

- `test/core/theme/foundation/motion_test.dart`
- `test/core/theme/foundation/gradient_test.dart`
- `test/core/theme/primitives/button_test.dart`

These validate token values and primitive button behavior.
