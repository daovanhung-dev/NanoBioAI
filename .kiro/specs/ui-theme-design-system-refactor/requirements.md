# Requirements Document

## Introduction

This document specifies requirements for refactoring the BioAI Flutter application's UI/Theme design system. The current system consists of 13 theme files with significant token duplication, inconsistent styling across features, and performance issues. The refactored system will provide a simplified, reusable, performant, and extensible foundation for the application's visual design while maintaining backward compatibility with existing code.

## Glossary

- **Theme_System**: The centralized collection of design tokens, foundation styles, and component definitions that control the visual appearance of the BioAI application
- **Design_Token**: A named value (color, spacing, radius, shadow, typography, motion) that represents a design decision and can be reused across components
- **Foundation_Token**: Base-level design tokens that define primitive values (colors, spacing scale, typography scale, radius scale, shadow levels, motion curves)
- **Semantic_Token**: Design tokens that reference foundation tokens and convey meaning or purpose (primary color, surface color, text color, card shadow)
- **Primitive_Component**: A reusable UI building block with defined variants (Button, Card, Chip, Input, Badge, Section_Header, Empty_State, Loading_State, Error_State)
- **Feature_Component**: A domain-specific UI component that combines primitive components for feature-specific use cases (Onboarding_Step, Health_Card, Meal_Card)
- **Theme_Mode**: The visual appearance variant of the application (Light_Mode or Dark_Mode)
- **Component_Variant**: A specific style variation of a primitive component (Button_Primary, Button_Secondary, Card_Elevated, Chip_Selectable)
- **Onboarding_Flow**: The 7-step user journey that collects health data and triggers AI meal plan generation
- **Design_System**: The complete set of Foundation_Tokens, Primitive_Components, and documentation that guides consistent UI implementation
- **Token_Duplication**: Multiple design tokens that represent the same or nearly identical values, increasing maintenance burden
- **Hardcoded_Style**: Visual styling defined directly in feature widgets rather than referencing design tokens from the Theme_System

## Requirements

### Requirement 1: Foundation Token Consolidation

**User Story:** As a developer, I want a consolidated foundation token system, so that I can reference design values consistently without duplication.

#### Acceptance Criteria

1. THE Theme_System SHALL define Foundation_Tokens for colors with semantic categories (brand colors, status colors, surface colors, text colors, border colors)
2. THE Theme_System SHALL define Foundation_Tokens for typography with scale levels (display, heading, title, body, label, caption)
3. THE Theme_System SHALL define Foundation_Tokens for spacing with a base-8 scale (0, 4, 8, 16, 24, 32, 48, 64, 96)
4. THE Theme_System SHALL define Foundation_Tokens for radius with scale levels (none, sm, md, lg, xl, full)
5. THE Theme_System SHALL define Foundation_Tokens for shadows with elevation levels (0, 1, 2, 3, 4)
6. THE Theme_System SHALL define Foundation_Tokens for motion with duration values (fast: 150ms, normal: 250ms, slow: 350ms) and curve definitions (ease-in, ease-out, ease-in-out)
7. FOR ALL Foundation_Tokens, duplicate tokens with identical or near-identical values SHALL be eliminated
8. FOR ALL Foundation_Tokens, token names SHALL follow semantic naming conventions that convey purpose rather than visual properties

### Requirement 2: Semantic Token Layer

**User Story:** As a developer, I want semantic design tokens that reference foundation tokens, so that I can use meaningful names that convey intent in my UI code.

#### Acceptance Criteria

1. THE Theme_System SHALL define Semantic_Tokens for colors that reference Foundation_Tokens (primary, secondary, surface, background, text_primary, text_secondary, border, divider)
2. THE Theme_System SHALL define Semantic_Tokens for spacing that reference Foundation_Tokens (page_padding, card_padding, item_spacing, section_spacing, button_padding, input_padding)
3. THE Theme_System SHALL define Semantic_Tokens for component styling that reference Foundation_Tokens (card_shadow, button_shadow, card_radius, button_radius, input_radius)
4. FOR ALL Semantic_Tokens, the token SHALL reference a Foundation_Token rather than defining a literal value
5. WHEN a Semantic_Token is used across multiple components, THE Theme_System SHALL provide a single source of truth for that token value

### Requirement 3: Light and Dark Mode Support

**User Story:** As a user, I want consistent visual appearance in both light and dark modes, so that the app is comfortable to use in different lighting conditions.

#### Acceptance Criteria

1. THE Theme_System SHALL provide Foundation_Token values for Light_Mode
2. THE Theme_System SHALL provide Foundation_Token values for Dark_Mode
3. WHEN Theme_Mode changes, THE Theme_System SHALL apply the corresponding token values to all components
4. FOR ALL color tokens, THE Theme_System SHALL ensure sufficient contrast ratios for text readability in both Light_Mode (4.5:1 minimum) and Dark_Mode (4.5:1 minimum)
5. FOR ALL surface tokens, THE Theme_System SHALL ensure clear visual hierarchy through elevation and shadow in both Light_Mode and Dark_Mode

### Requirement 4: Primitive Component Library

**User Story:** As a developer, I want a library of reusable primitive components, so that I can build feature UIs without recreating common patterns.

#### Acceptance Criteria

1. THE Theme_System SHALL provide a Button primitive with variants (primary, secondary, text, icon, outlined)
2. THE Theme_System SHALL provide a Card primitive with variants (default, elevated, outlined)
3. THE Theme_System SHALL provide a Chip primitive with variants (selectable, filter, action)
4. THE Theme_System SHALL provide an Input primitive with variants (text_field, dropdown, search)
5. THE Theme_System SHALL provide a Badge primitive with variants (status, count, dot)
6. THE Theme_System SHALL provide a Section_Header primitive with slots for title, subtitle, and action
7. THE Theme_System SHALL provide an Empty_State primitive with slots for icon, title, description, and action
8. THE Theme_System SHALL provide a Loading_State primitive with variants (spinner, skeleton, shimmer)
9. THE Theme_System SHALL provide an Error_State primitive with slots for icon, message, and retry action
10. FOR ALL Primitive_Components, styling SHALL reference Semantic_Tokens rather than hardcoded values
11. FOR ALL Primitive_Components, the component SHALL be marked const where possible for performance optimization

### Requirement 5: Onboarding UI Simplification

**User Story:** As a user completing onboarding, I want a clean and focused interface, so that I can easily input my health data without visual distractions.

#### Acceptance Criteria

1. THE Onboarding_Flow SHALL remove unnecessary gradient decorations from step backgrounds
2. THE Onboarding_Flow SHALL remove unnecessary shadow effects that do not convey visual hierarchy
3. THE Onboarding_Flow SHALL remove decorative elements that do not support the data collection task
4. THE Onboarding_Flow SHALL use Primitive_Components for input fields, buttons, and cards
5. THE Onboarding_Flow SHALL reference Semantic_Tokens for all spacing, colors, and typography
6. THE Onboarding_Flow SHALL maintain the 7-step structure (Welcome, Basic_Info, Goals, Conditions, Lifestyle, Extras, Review)
7. THE Onboarding_Flow SHALL preserve the business logic for data collection and AI meal plan generation trigger

### Requirement 6: Performance Optimization

**User Story:** As a developer, I want optimized UI rendering, so that the app provides smooth performance and quick response times.

#### Acceptance Criteria

1. FOR ALL Primitive_Components, THE Theme_System SHALL use const constructors where widget properties are immutable
2. WHEN a component does not require state changes, THE Theme_System SHALL mark the widget as const to prevent unnecessary rebuilds
3. THE Theme_System SHALL avoid nesting multiple Container widgets with decoration properties when a single Container suffices
4. THE Theme_System SHALL minimize BoxShadow complexity by using elevation levels (0-4) with predefined shadow lists
5. THE Theme_System SHALL avoid gradient decorations where solid colors provide equivalent visual communication

### Requirement 7: No Hardcoded Styling in Features

**User Story:** As a developer building feature UIs, I want to reference design tokens instead of hardcoded values, so that visual changes propagate consistently across the app.

#### Acceptance Criteria

1. WHEN a feature widget defines spacing, THE widget SHALL reference AppSpacing tokens rather than literal pixel values
2. WHEN a feature widget defines colors, THE widget SHALL reference AppColors tokens rather than literal Color values
3. WHEN a feature widget defines border radius, THE widget SHALL reference AppRadius tokens rather than literal BorderRadius values
4. WHEN a feature widget defines shadows, THE widget SHALL reference AppShadows elevation levels rather than inline BoxShadow definitions
5. WHEN a feature widget defines typography, THE widget SHALL reference AppTextStyles tokens rather than inline TextStyle definitions

### Requirement 8: Component Variant System

**User Story:** As a developer, I want clearly defined component variants, so that I can select the appropriate visual style for different use cases.

#### Acceptance Criteria

1. FOR ALL Primitive_Components with variants, THE component SHALL expose a variant parameter (enum or sealed class)
2. WHEN a variant parameter is provided, THE component SHALL apply the corresponding token set for that variant
3. THE Theme_System SHALL document available variants for each Primitive_Component
4. FOR ALL Component_Variants, styling differences SHALL be achieved through Semantic_Token references rather than conditional hardcoded values

### Requirement 9: Extensibility for New Features

**User Story:** As a developer adding new features, I want to compose UIs from existing primitives and tokens, so that I can build quickly without reinventing styles.

#### Acceptance Criteria

1. WHEN a developer creates a new feature screen, THE developer SHALL be able to compose the UI using Primitive_Components from the Theme_System
2. WHEN a developer needs custom spacing, THE developer SHALL find appropriate semantic or foundation spacing tokens in AppSpacing
3. WHEN a developer needs custom component styling, THE developer SHALL be able to extend Primitive_Components or create Feature_Components that reference existing tokens
4. THE Theme_System SHALL provide documentation on token usage patterns and component composition guidelines

### Requirement 10: Backward Compatibility and Migration

**User Story:** As a developer maintaining existing code, I want a clear migration path from old styling patterns to the new design system, so that I can refactor incrementally without breaking features.

#### Acceptance Criteria

1. WHEN existing code references deprecated token names, THE Theme_System SHALL provide backward-compatible aliases that map to new Semantic_Tokens
2. THE Theme_System SHALL document deprecated tokens with migration instructions
3. WHEN a feature screen is refactored, THE Theme_System SHALL ensure that visual output remains consistent with the previous implementation
4. THE Theme_System SHALL provide a migration guide that lists old token names, new token names, and usage examples

### Requirement 11: Token Count Reduction

**User Story:** As a developer maintaining the theme system, I want a minimal set of necessary tokens, so that the system is easier to understand and modify.

#### Acceptance Criteria

1. WHEN the refactored Theme_System is complete, THE system SHALL contain fewer than 60 color tokens (reduced from current 80+ tokens)
2. WHEN the refactored Theme_System is complete, THE system SHALL contain fewer than 30 spacing tokens (reduced from current 40+ tokens)
3. WHEN the refactored Theme_System is complete, THE system SHALL contain fewer than 15 gradient definitions (reduced from current 25+ gradients)
4. WHEN the refactored Theme_System is complete, THE system SHALL contain fewer than 20 shadow definitions (reduced from current 30+ shadows)
5. FOR ALL tokens in the refactored system, the token SHALL be used in at least one component or feature

### Requirement 12: Design System Documentation

**User Story:** As a developer using the design system, I want clear documentation on available tokens and components, so that I can find the right element for my use case quickly.

#### Acceptance Criteria

1. THE Theme_System SHALL provide inline code documentation for all Foundation_Token definitions
2. THE Theme_System SHALL provide inline code documentation for all Semantic_Token definitions
3. THE Theme_System SHALL provide inline code documentation for all Primitive_Component classes with usage examples
4. THE Theme_System SHALL provide a design system overview document that explains the token hierarchy (Foundation → Semantic → Component)
5. THE Theme_System SHALL provide visual examples of Component_Variants in the documentation
