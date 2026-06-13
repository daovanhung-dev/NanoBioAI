# Implementation Plan: UI Theme Design System Refactor

## Overview

This implementation plan refactors the BioAI Flutter application's UI/Theme design system from a 13-file theme system with 80+ color tokens, 40+ spacing tokens, 25+ gradients, and 30+ shadows into a consolidated three-layer token architecture (Foundation → Semantic → Component) with a primitive component library. The refactor eliminates token duplication, removes hardcoded styling from feature widgets, and improves performance through const constructors and simplified decorations.

The implementation follows a bottom-up approach: foundation tokens → semantic tokens → primitive components → feature refactoring → migration support.

## Tasks

- [ ] 1. Set up foundation token layer
  - [-] 1.1 Create foundation color palette
    - Create `lib/core/theme/foundation/colors.dart`
    - Define `ColorFoundation` class with brand colors (blue, cyan, purple)
    - Define status colors (green, amber, red, sky)
    - Define neutral slate scale (slate50-slate900)
    - Target: 28 color values (reduced from 80+)
    - _Requirements: 1.1, 11.1_
  
  - [-] 1.2 Create foundation spacing scale
    - Create `lib/core/theme/foundation/spacing.dart`
    - Define `SpacingFoundation` class with base-8 scale (0, 4, 8, 12, 16, 24, 32, 48, 64, 96)
    - _Requirements: 1.3, 11.2_
  
  - [-] 1.3 Create foundation radius scale
    - Create `lib/core/theme/foundation/radius.dart`
    - Define `RadiusFoundation` class with scale levels (0, 4, 8, 12, 16, 24, full)
    - _Requirements: 1.4_
  
  - [-] 1.4 Create foundation shadow definitions
    - Create `lib/core/theme/foundation/shadows.dart`
    - Define `ShadowFoundation` class with elevation levels (shadowSm, shadowMd, shadowLg)
    - Define dark mode variants (shadowSmDark, shadowMdDark)
    - Target: 5 foundation shadows (reduced from 30+)
    - _Requirements: 1.5, 11.4_
  
  - [-] 1.5 Create foundation typography scale
    - Create `lib/core/theme/foundation/typography.dart`
    - Define `TypographyFoundation` class with font sizes (12-32), weights (regular, medium, semibold, bold), line heights
    - _Requirements: 1.2_
  
  - [x] 1.6 Create foundation motion tokens
    - Create `lib/core/theme/foundation/motion.dart`
    - Define `MotionFoundation` class with durations (fast: 150ms, normal: 250ms, slow: 350ms) and curves
    - _Requirements: 1.6_
  
  - [x] 1.7 Create foundation gradient definitions
    - Add `GradientFoundation` class to `colors.dart`
    - Define primary, premium, success, surfaceLight, surfaceDark gradients
    - Target: 5 gradient definitions (reduced from 25+)
    - _Requirements: 11.3_

- [~] 2. Checkpoint - Verify foundation tokens
  - Ensure all foundation token files compile without errors
  - Verify all foundation classes use `@immutable` annotation and const constructors
  - Ask the user if questions arise.

- [x] 3. Set up semantic token layer
  - [x] 3.1 Create semantic color tokens
    - Create `lib/core/theme/tokens/color_tokens.dart`
    - Define `AppColorTokens` class with light mode tokens (primary, surface, background, text, borders, status)
    - Define dark mode tokens (darkBackground, darkSurface, darkText, darkBorder)
    - All tokens reference `ColorFoundation` values
    - Target: 24 semantic color mappings
    - _Requirements: 2.1, 2.4, 3.1, 3.2_
  
  - [x] 3.2 Create semantic spacing tokens
    - Create `lib/core/theme/tokens/spacing_tokens.dart`
    - Define `AppSpacingTokens` class with page-level (pagePadding, sectionSpacing), component-level (cardPadding, buttonPadding, inputPadding, chipPadding), and layout tokens (itemSpacing, iconTextSpacing)
    - All tokens reference `SpacingFoundation` values
    - Target: 15 semantic spacing tokens
    - _Requirements: 2.2, 2.4_
  
  - [x] 3.3 Create component tokens
    - Create `lib/core/theme/tokens/component_tokens.dart`
    - Define `AppRadiusTokens` class with component radius mappings (button, card, input, chip, badge, dialog, avatar)
    - Define `AppShadowTokens` class with component shadow mappings (card, cardElevated, dialog, button)
    - Define `AppMotionTokens` class with component animation mappings (button, card, dialog, page)
    - Define `AppTextStyles` class with text style presets (displayLarge, heading1, heading2, bodyLarge, bodyMedium, labelLarge, caption)
    - All tokens reference foundation values
    - _Requirements: 2.3, 2.4, 2.5_

- [~] 4. Checkpoint - Verify semantic tokens
  - Ensure all semantic token files compile without errors
  - Verify all semantic tokens reference foundation tokens (no literal values)
  - Ask the user if questions arise.

- [x] 5. Create primitive components - Buttons and Cards
  - [x] 5.1 Create Button primitive
    - Create `lib/core/theme/primitives/button.dart`
    - Define `ButtonVariant` enum (primary, secondary, text, icon, outlined)
    - Define `AppButton` StatelessWidget with variant parameter, onPressed callback, loading/disabled states
    - Implement token-based styling for each variant using `AppColorTokens`, `AppSpacingTokens`, `AppRadiusTokens`
    - Ensure const constructor where possible
    - _Requirements: 4.1, 4.10, 4.11, 8.1, 8.2_
  
  - [x] 5.2 Create Card primitive
    - Create `lib/core/theme/primitives/card.dart`
    - Define `CardVariant` enum (defaultCard, elevated, outlined)
    - Define `AppCard` StatelessWidget with variant parameter, child widget, onTap callback, optional padding
    - Implement light/dark mode adaptation using `Theme.of(context).brightness`
    - Implement token-based styling for each variant using `AppColorTokens`, `AppRadiusTokens`, `AppShadowTokens`
    - Ensure const constructor where possible
    - _Requirements: 4.2, 4.10, 4.11, 3.3, 3.4, 3.5, 8.1, 8.2_

- [x] 6. Create primitive components - Inputs and Chips
  - [x] 6.1 Create Chip primitive
    - Create `lib/core/theme/primitives/chip.dart`
    - Define `ChipVariant` enum (selectable, filter, action)
    - Define `AppChip` StatelessWidget with label, variant, selected state, onTap/onDeleted callbacks
    - Implement token-based styling using semantic tokens
    - Ensure const constructor where possible
    - _Requirements: 4.3, 4.10, 4.11, 8.1, 8.2_
  
  - [x] 6.2 Create Input primitive
    - Create `lib/core/theme/primitives/input.dart`
    - Define `InputVariant` enum (textField, dropdown, search)
    - Define `AppInput` StatelessWidget with variant, controller, label, hint, errorText, callbacks
    - Implement token-based styling using semantic tokens
    - Ensure const constructor where possible
    - _Requirements: 4.4, 4.10, 4.11, 8.1, 8.2_

- [x] 7. Create primitive components - Badges and Headers
  - [x] 7.1 Create Badge primitive
    - Create `lib/core/theme/primitives/badge.dart`
    - Define `BadgeVariant` enum (status, count, dot)
    - Define `AppBadge` StatelessWidget with variant, count, status, color parameters
    - Implement token-based styling using semantic tokens
    - Ensure const constructor where possible
    - _Requirements: 4.5, 4.10, 4.11, 8.1, 8.2_
  
  - [x] 7.2 Create Section Header primitive
    - Create `lib/core/theme/primitives/section_header.dart`
    - Define `SectionHeader` StatelessWidget with title, subtitle, action callback, actionLabel
    - Use `AppButton` for action, `AppTextStyles` for text styling, `AppSpacingTokens` for layout
    - Ensure const constructor where possible
    - _Requirements: 4.6, 4.10, 4.11_

- [x] 8. Create primitive components - State widgets
  - [x] 8.1 Create Empty State primitive
    - Create `lib/core/theme/primitives/states/empty_state.dart`
    - Define `EmptyState` StatelessWidget with icon, title, description, action callback, actionLabel
    - Use `AppButton` for action, `AppTextStyles` for text, semantic tokens for spacing and colors
    - Ensure const constructor where possible
    - _Requirements: 4.7, 4.10, 4.11_
  
  - [x] 8.2 Create Loading State primitive
    - Create `lib/core/theme/primitives/states/loading_state.dart`
    - Define `LoadingVariant` enum (spinner, skeleton, shimmer)
    - Define `LoadingState` StatelessWidget with variant and optional message
    - Implement spinner variant using CircularProgressIndicator with semantic color tokens
    - Ensure const constructor where possible
    - _Requirements: 4.8, 4.10, 4.11_
  
  - [x] 8.3 Create Error State primitive
    - Create `lib/core/theme/primitives/states/error_state.dart`
    - Define `ErrorState` StatelessWidget with message, onRetry callback, retryLabel
    - Use `AppButton` for retry action, semantic color tokens for error styling
    - Ensure const constructor where possible
    - _Requirements: 4.9, 4.10, 4.11_

- [x] 9. Checkpoint - Verify primitive components
  - Ensure all primitive component files compile without errors
  - Verify all components use semantic tokens (no hardcoded colors, spacing, or radius)
  - Verify all components use const constructors where possible
  - Ask the user if questions arise.

- [x] 10. Create main theme configuration
  - [x] 10.1 Create app theme file
    - Create `lib/core/theme/design_system.dart`
    - Export all foundation token files
    - Export all semantic token files
    - Export all primitive component files
    - Define `AppThemeData` class that provides light and dark `ThemeData` instances
    - Map semantic color tokens to Material ThemeData properties
    - _Requirements: 3.1, 3.2, 3.3, 9.1, 9.2_

- [ ] 11. Refactor Onboarding flow UI
  - [~] 11.1 Refactor Onboarding step backgrounds
    - Locate onboarding step widgets (7-step flow: Welcome, Basic_Info, Goals, Conditions, Lifestyle, Extras, Review)
    - Remove gradient decorations from step backgrounds
    - Replace with semantic surface color tokens
    - Remove unnecessary shadow effects
    - Remove decorative elements not supporting data collection
    - Preserve 7-step structure and data collection business logic
    - _Requirements: 5.1, 5.2, 5.3, 5.6, 5.7_
  
  - [~] 11.2 Replace Onboarding components with primitives
    - Replace custom button implementations with `AppButton` primitive
    - Replace custom input fields with `AppInput` primitive
    - Replace custom card wrappers with `AppCard` primitive
    - Ensure all spacing references `AppSpacingTokens`
    - Ensure all colors reference `AppColorTokens`
    - Ensure all typography references `AppTextStyles`
    - _Requirements: 5.4, 5.5, 7.1, 7.2, 7.3, 7.4, 7.5_

- [~] 12. Checkpoint - Verify Onboarding refactor
  - Run the application and navigate through the 7-step Onboarding flow
  - Verify visual appearance is clean and simplified
  - Verify data collection and AI meal plan generation trigger still function correctly
  - Ask the user if questions arise.

- [ ] 13. Refactor feature screens to use design system
  - [~] 13.1 Identify feature screens with hardcoded styling
    - Search codebase for literal `Color(0x...)` values in feature widgets (exclude theme files)
    - Search for literal `EdgeInsets` with numeric values
    - Search for inline `BoxShadow` definitions
    - Search for inline `TextStyle` definitions
    - Create list of files requiring refactoring
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_
  
  - [~] 13.2 Refactor high-priority feature screens
    - Replace hardcoded colors with `AppColorTokens` references
    - Replace hardcoded spacing with `AppSpacingTokens` references
    - Replace hardcoded radius with `AppRadiusTokens` references
    - Replace hardcoded shadows with `AppShadowTokens` references
    - Replace custom button/card/input implementations with primitive components where applicable
    - Focus on main user flows: Home, Health Dashboard, Meal Planning
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 9.1, 9.3_

- [ ] 14. Create backward compatibility layer
  - [~] 14.1 Create deprecated token aliases
    - Create `lib/core/theme/deprecated.dart`
    - Define `@Deprecated` aliases for old token names mapping to new semantic tokens
    - Document each deprecated token with migration instruction comment
    - _Requirements: 10.1, 10.2_
  
  - [~] 14.2 Create migration guide document
    - Create `lib/core/theme/MIGRATION_GUIDE.md`
    - List old token names, new token names, and usage examples
    - Provide before/after code examples for common patterns
    - Document component migration patterns (custom button → AppButton)
    - _Requirements: 10.2, 10.4_

- [ ] 15. Add design system documentation
  - [~] 15.1 Add inline documentation to foundation tokens
    - Add dartdoc comments to all `ColorFoundation` tokens
    - Add dartdoc comments to all `SpacingFoundation` tokens
    - Add dartdoc comments to all other foundation classes
    - _Requirements: 12.1_
  
  - [~] 15.2 Add inline documentation to semantic tokens
    - Add dartdoc comments to all `AppColorTokens` tokens
    - Add dartdoc comments to all `AppSpacingTokens` tokens
    - Add dartdoc comments to all component token classes
    - _Requirements: 12.2_
  
  - [~] 15.3 Add inline documentation to primitive components
    - Add dartdoc comments to all primitive component classes with usage examples
    - Document all variant enums with use case descriptions
    - Add parameter documentation for all public APIs
    - _Requirements: 12.3_
  
  - [~] 15.4 Create design system overview document
    - Create `lib/core/theme/README.md`
    - Explain token hierarchy (Foundation → Semantic → Component)
    - Provide visual examples of component variants
    - Document when to use each primitive component
    - _Requirements: 12.4, 12.5, 9.4_

- [ ] 16. Performance optimization pass
  - [~] 16.1 Verify const constructor usage
    - Review all primitive components for const constructor opportunities
    - Add const constructors where widget properties are immutable
    - Add const keywords to widget instantiations where possible
    - _Requirements: 6.1, 6.2_
  
  - [~] 16.2 Simplify widget decoration nesting
    - Search for nested Container widgets with decoration properties
    - Merge decorations into single Container where possible
    - Use Material widget instead of Container+BoxDecoration where appropriate for elevation
    - _Requirements: 6.3_
  
  - [~] 16.3 Verify shadow and gradient optimization
    - Ensure all shadows use elevation levels (0-4) with predefined shadow lists
    - Verify gradients are only used for brand moments and premium features (target: 5 gradients)
    - Replace gradient decorations with solid colors where equivalent
    - _Requirements: 6.4, 6.5_

- [ ] 17. Final checkpoint and validation
  - [~] 17.1 Validate token count targets
    - Count color tokens (target: <60)
    - Count spacing tokens (target: <30)
    - Count gradient definitions (target: <15)
    - Count shadow definitions (target: <20)
    - Verify all tokens are used in at least one component
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_
  
  - [~] 17.2 Verify visual consistency
    - Run application in light mode and verify visual appearance
    - Run application in dark mode and verify visual appearance
    - Verify contrast ratios meet 4.5:1 minimum for text in both modes
    - Verify all features maintain original visual output after refactoring
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 10.3_
  
  - [~] 17.3 Final review and user feedback
    - Ensure all tests pass
    - Review all documentation for completeness
    - Ask the user if questions arise or if additional refinements are needed

## Notes

- The implementation follows a bottom-up approach: foundation → semantic → components → features
- Each checkpoint ensures incremental validation before proceeding to dependent layers
- Focus on token-based styling eliminates hardcoded values and enables consistent theme changes
- Primitive components provide reusable building blocks for rapid feature development
- Backward compatibility layer enables incremental migration without breaking existing code
- Performance optimizations (const constructors, simplified decorations) improve rendering efficiency
- Target token reductions: colors (<60), spacing (<30), gradients (<15), shadows (<20)

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2", "1.3", "1.4", "1.5", "1.6"] },
    { "id": 1, "tasks": ["1.7", "3.1", "3.2"] },
    { "id": 2, "tasks": ["3.3"] },
    { "id": 3, "tasks": ["5.1", "5.2"] },
    { "id": 4, "tasks": ["6.1", "6.2", "7.1", "7.2"] },
    { "id": 5, "tasks": ["8.1", "8.2", "8.3"] },
    { "id": 6, "tasks": ["10.1"] },
    { "id": 7, "tasks": ["11.1"] },
    { "id": 8, "tasks": ["11.2", "13.1"] },
    { "id": 9, "tasks": ["13.2", "14.1"] },
    { "id": 10, "tasks": ["14.2", "15.1", "15.2", "15.3"] },
    { "id": 11, "tasks": ["15.4", "16.1", "16.2", "16.3"] },
    { "id": 12, "tasks": ["17.1", "17.2", "17.3"] }
  ]
}
```
