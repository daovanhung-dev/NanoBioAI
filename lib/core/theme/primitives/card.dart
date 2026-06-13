import 'package:flutter/material.dart';
import '../tokens/color_tokens.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/component_tokens.dart';

/// Card variants for different visual styles and interaction patterns.
///
/// Each variant serves a specific purpose in the UI hierarchy:
/// - **defaultCard**: Standard card with subtle background and shadow
/// - **elevated**: Prominent card with increased elevation for emphasis
/// - **outlined**: Card with border emphasis instead of shadow
///
/// **Validates: Requirements 4.2, 8.1**
enum CardVariant {
  /// Default card with subtle background and shadow
  defaultCard,

  /// Elevated card with increased shadow for emphasis
  elevated,

  /// Outlined card with border instead of shadow
  outlined,
}

/// A primitive card component with variant-based styling using design tokens.
///
/// `AppCard` is a Layer 3 primitive component that provides consistent container
/// styling across the application. It automatically adapts to light/dark mode
/// and supports different visual emphasis levels through variants.
///
/// ## Variants
///
/// ```dart
/// // Default card
/// AppCard(
///   variant: CardVariant.defaultCard,
///   child: Column(
///     children: [
///       Text('Title'),
///       Text('Content'),
///     ],
///   ),
/// )
///
/// // Elevated card (for emphasis)
/// AppCard(
///   variant: CardVariant.elevated,
///   child: Text('Important content'),
/// )
///
/// // Outlined card
/// AppCard(
///   variant: CardVariant.outlined,
///   child: Text('Bordered content'),
/// )
/// ```
///
/// ## Interaction
///
/// ```dart
/// // Interactive card
/// AppCard(
///   variant: CardVariant.defaultCard,
///   onTap: () {
///     print('Card tapped');
///   },
///   child: Text('Tap me'),
/// )
/// ```
///
/// ## Custom Padding
///
/// ```dart
/// // Card with custom padding
/// AppCard(
///   variant: CardVariant.defaultCard,
///   padding: EdgeInsets.all(24),
///   child: Text('Custom padding'),
/// )
/// ```
///
/// ## Token-Based Styling
///
/// All styling references semantic tokens:
/// - Colors: [AppColorTokens]
/// - Radius: [AppRadiusTokens]
/// - Shadows: [AppShadowTokens]
/// - Motion: [AppMotionTokens]
///
/// **Validates: Requirements 4.2, 4.10, 4.11, 3.3, 3.4, 3.5, 8.1, 8.2**
class AppCard extends StatelessWidget {
  /// Creates a card with the specified variant and styling.
  ///
  /// The [variant] determines the visual style.
  /// The [child] is the content to display inside the card.
  /// The [onTap] callback makes the card interactive.
  /// The [padding] can be customized or set to null for no padding.
  const AppCard({
    super.key,
    required this.variant,
    required this.child,
    this.onTap,
    this.padding,
  });

  /// The visual style variant for this card.
  final CardVariant variant;

  /// The content to display inside the card.
  final Widget child;

  /// Callback triggered when the card is tapped.
  ///
  /// If `null`, the card is not interactive.
  final VoidCallback? onTap;

  /// The padding inside the card.
  ///
  /// Defaults to [AppSpacingTokens.cardPadding] if not specified.
  /// Set to [EdgeInsets.zero] for no padding.
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectivePadding = padding ?? EdgeInsets.all(AppSpacingTokens.cardPadding);

    return AnimatedContainer(
      duration: AppMotionTokens.card,
      curve: AppMotionTokens.defaultCurve,
      decoration: BoxDecoration(
        color: _getBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(AppRadiusTokens.card),
        border: _getBorder(isDark),
        boxShadow: _getShadow(isDark),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadiusTokens.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadiusTokens.card),
          child: Padding(
            padding: effectivePadding,
            child: child,
          ),
        ),
      ),
    );
  }

  /// Gets the background color based on variant and theme mode.
  Color _getBackgroundColor(bool isDark) {
    if (isDark) {
      switch (variant) {
        case CardVariant.defaultCard:
          return AppColorTokens.darkSurface;
        case CardVariant.elevated:
          return AppColorTokens.darkSurfaceElevated;
        case CardVariant.outlined:
          return AppColorTokens.darkSurface;
      }
    } else {
      switch (variant) {
        case CardVariant.defaultCard:
        case CardVariant.elevated:
        case CardVariant.outlined:
          return AppColorTokens.surface;
      }
    }
  }

  /// Gets the border based on variant and theme mode.
  Border? _getBorder(bool isDark) {
    if (variant == CardVariant.outlined) {
      return Border.all(
        color: isDark ? AppColorTokens.darkBorder : AppColorTokens.border,
        width: 1,
      );
    }
    return null;
  }

  /// Gets the shadow based on variant and theme mode.
  List<BoxShadow>? _getShadow(bool isDark) {
    // Don't apply shadow on outlined variant
    if (variant == CardVariant.outlined) {
      return null;
    }

    // Use appropriate shadow based on theme mode
    switch (variant) {
      case CardVariant.defaultCard:
        return isDark ? AppShadowTokens.cardDark : AppShadowTokens.card;
      case CardVariant.elevated:
        return isDark 
            ? AppShadowTokens.cardElevatedDark 
            : AppShadowTokens.cardElevated;
      case CardVariant.outlined:
        return null;
    }
  }
}
