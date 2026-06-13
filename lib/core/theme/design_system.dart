/// BioAI Design System - Layer 3 Export
///
/// This file exports the complete three-layer token architecture and primitive
/// component library for the BioAI application design system.
///
/// ## Token Architecture (3 Layers)
///
/// **Layer 1: Foundation Tokens** - Primitive, immutable values
/// - Colors (28 values)
/// - Spacing (base-8 scale, 10 values)
/// - Radius (7 levels)
/// - Shadows (5 definitions)
/// - Typography (font sizes, weights, line heights)
/// - Motion (durations and curves)
/// - Gradients (5 definitions)
///
/// **Layer 2: Semantic Tokens** - Meaningful, context-aware names
/// - Color tokens (24 mappings: light + dark mode)
/// - Spacing tokens (15 semantic names)
/// - Component tokens (radius, shadow, motion, text style mappings)
///
/// **Layer 3: Primitive Components** - Reusable UI building blocks
/// - Button, Card, Chip, Input, Badge
/// - Section Header
/// - Empty State, Loading State, Error State
///
/// ## Usage
///
/// Import this single file to access the entire design system:
///
/// ```dart
/// import 'package:nano_app/core/theme/design_system.dart';
///
/// // Use semantic tokens
/// color: AppColorTokens.primary,
/// padding: EdgeInsets.all(AppSpacingTokens.pagePadding),
///
/// // Use primitive components
/// AppButton(
///   variant: ButtonVariant.primary,
///   onPressed: () {},
///   child: Text('Save'),
/// )
/// ```
///
/// ## Design Principles
///
/// 1. **Always use semantic tokens** - Never use foundation tokens directly
/// 2. **Use primitive components** - Avoid custom implementations
/// 3. **Support light/dark mode** - Check Theme.brightness in components
/// 4. **Const constructors** - Use const where possible for performance
/// 5. **Token-based styling** - No hardcoded colors, spacing, or radius values
///
/// **Validates: Requirements 3.1, 3.2, 3.3, 9.1, 9.2**
library design_system;

// ============================================================================
// FOUNDATION TOKENS (Layer 1)
// ============================================================================

/// Foundation color palette (28 colors)
export 'foundation/colors.dart' show ColorFoundation, GradientFoundation;

/// Foundation spacing scale (base-8, 10 values)
export 'foundation/spacing.dart' show SpacingFoundation;

/// Foundation radius scale (7 levels)
export 'foundation/radius.dart' show RadiusFoundation;

/// Foundation shadow definitions (5 shadows)
export 'foundation/shadows.dart' show ShadowFoundation;

/// Foundation typography scale (font sizes, weights, line heights)
export 'foundation/typography.dart' show TypographyFoundation;

/// Foundation motion tokens (durations and curves)
export 'foundation/motion.dart' show MotionFoundation;

// ============================================================================
// SEMANTIC TOKENS (Layer 2)
// ============================================================================

/// Semantic color tokens (24 mappings: light + dark)
export 'tokens/color_tokens.dart' show AppColorTokens;

/// Semantic spacing tokens (15 semantic names)
export 'tokens/spacing_tokens.dart' show AppSpacingTokens;

/// Component tokens (radius, shadow, motion, text styles)
export 'tokens/component_tokens.dart'
    show
        AppRadiusTokens,
        AppShadowTokens,
        AppMotionTokens,
        AppTextStyles;

// ============================================================================
// PRIMITIVE COMPONENTS (Layer 3)
// ============================================================================

/// Button primitive (primary, secondary, text, icon, outlined variants)
export 'primitives/button.dart' show AppButton, ButtonVariant;

/// Card primitive (default, elevated, outlined variants)
export 'primitives/card.dart' show AppCard, CardVariant;

/// Chip primitive (selectable, filter, action variants)
export 'primitives/chip.dart' show AppChip, ChipVariant;

/// Input primitive (textField, dropdown, search variants)
export 'primitives/input.dart' show AppInput, InputVariant;

/// Badge primitive (status, count, dot variants)
export 'primitives/badge.dart' show AppBadge, BadgeVariant, BadgeStatus;

/// Section header primitive (title + optional subtitle and action)
export 'primitives/section_header.dart' show SectionHeader;

/// Empty state primitive (icon, title, description, optional action)
export 'primitives/states/empty_state.dart' show EmptyState;

/// Loading state primitive (spinner, skeleton, shimmer variants)
export 'primitives/states/loading_state.dart' show LoadingState, LoadingVariant;

/// Error state primitive (message, retry action)
export 'primitives/states/error_state.dart' show ErrorState;

// ============================================================================
// THEME CONFIGURATION
// ============================================================================

// The main AppThemeData class will be exported here once created
// export 'app_theme_data.dart' show AppThemeData;
