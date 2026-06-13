import 'package:flutter/foundation.dart';
import '../foundation/spacing.dart';

/// Semantic spacing tokens that provide meaningful names for spacing values.
///
/// This class defines the Layer 2 semantic spacing tokens that reference
/// foundation spacing values. All spacing used in components and features
/// should reference these semantic tokens rather than foundation values
/// directly or hardcoded pixel values.
///
/// Token Categories:
/// - **Page-level**: Spacing for overall page layout (padding, section spacing)
/// - **Component-level**: Spacing for individual component padding
/// - **Layout**: Spacing for arranging elements within layouts
///
/// Example:
/// ```dart
/// // DON'T use hardcoded values
/// Padding(padding: EdgeInsets.all(16))
///
/// // DON'T use foundation tokens directly
/// Padding(padding: EdgeInsets.all(SpacingFoundation.space16))
///
/// // DO use semantic tokens
/// Padding(padding: EdgeInsets.all(AppSpacingTokens.pagePadding))
/// ```
///
/// **Validates: Requirements 2.2, 2.4**
@immutable
class AppSpacingTokens {
  const AppSpacingTokens._();

  // ============================================================================
  // Page-level Spacing
  // ============================================================================

  /// Standard page padding for main content areas.
  ///
  /// Used for horizontal padding on screens and vertical spacing
  /// for main content sections. Provides consistent breathing room
  /// from screen edges.
  ///
  /// References: [SpacingFoundation.space16]
  static const double pagePadding = SpacingFoundation.space16;

  /// Spacing between major sections within a page.
  ///
  /// Used to create clear visual separation between distinct content
  /// sections, such as between header and body, or between different
  /// feature areas.
  ///
  /// References: [SpacingFoundation.space24]
  static const double sectionSpacing = SpacingFoundation.space24;

  // ============================================================================
  // Component-level Spacing
  // ============================================================================

  /// Standard padding inside card components.
  ///
  /// Used for the default internal padding of card widgets to create
  /// adequate breathing room for card content.
  ///
  /// References: [SpacingFoundation.space16]
  static const double cardPadding = SpacingFoundation.space16;

  /// Compact padding for cards with dense content.
  ///
  /// Used when cards need to display more information in less space
  /// while maintaining readability.
  ///
  /// References: [SpacingFoundation.space12]
  static const double cardPaddingCompact = SpacingFoundation.space12;

  /// Horizontal padding inside buttons.
  ///
  /// Used for the left and right padding of button content to ensure
  /// adequate touch target size and visual balance.
  ///
  /// References: [SpacingFoundation.space24]
  static const double buttonPaddingH = SpacingFoundation.space24;

  /// Vertical padding inside buttons.
  ///
  /// Used for the top and bottom padding of button content to achieve
  /// the minimum touch target height of 48px.
  ///
  /// References: [SpacingFoundation.space12]
  static const double buttonPaddingV = SpacingFoundation.space12;

  /// Padding inside input fields.
  ///
  /// Used for the internal padding of text inputs, dropdowns, and
  /// search fields to create comfortable input areas.
  ///
  /// References: [SpacingFoundation.space16]
  static const double inputPadding = SpacingFoundation.space16;

  /// Horizontal padding inside input fields.
  ///
  /// Used for the left and right padding of text inputs to ensure
  /// adequate spacing for text entry.
  ///
  /// References: [SpacingFoundation.space16]
  static const double inputPaddingH = SpacingFoundation.space16;

  /// Vertical padding inside input fields.
  ///
  /// Used for the top and bottom padding of text inputs to achieve
  /// comfortable input height.
  ///
  /// References: [SpacingFoundation.space16]
  static const double inputPaddingV = SpacingFoundation.space16;

  /// Horizontal padding inside chips.
  ///
  /// Used for the left and right padding of chip content to create
  /// compact but readable chip components.
  ///
  /// References: [SpacingFoundation.space12]
  static const double chipPaddingH = SpacingFoundation.space12;

  /// Vertical padding inside chips.
  ///
  /// Used for the top and bottom padding of chip content to create
  /// appropriately sized chip components.
  ///
  /// References: [SpacingFoundation.space8]
  static const double chipPaddingV = SpacingFoundation.space8;

  // ============================================================================
  // Layout Spacing
  // ============================================================================

  /// Spacing between related items in a list or group.
  ///
  /// Used for vertical spacing between list items, form fields,
  /// or other grouped elements that have a close relationship.
  ///
  /// References: [SpacingFoundation.space8]
  static const double itemSpacing = SpacingFoundation.space8;

  /// Larger spacing between items that need more separation.
  ///
  /// Used when items in a list or group need more visual distinction
  /// while maintaining their relationship.
  ///
  /// References: [SpacingFoundation.space16]
  static const double itemSpacingLarge = SpacingFoundation.space16;

  /// Spacing between an icon and adjacent text.
  ///
  /// Used to create proper spacing in icon-text combinations such as
  /// buttons with icons, list items with leading icons, or labels
  /// with status indicators.
  ///
  /// References: [SpacingFoundation.space8]
  static const double iconTextSpacing = SpacingFoundation.space8;

  // ============================================================================
  // Size Constants
  // ============================================================================

  /// Minimum touch target size for interactive elements.
  ///
  /// Based on Material Design and WCAG accessibility guidelines,
  /// interactive elements should be at least 48x48 dp to ensure
  /// easy tapping for all users.
  static const double touchTargetMin = 48;

  /// Minimum height for button components.
  ///
  /// Ensures buttons meet touch target accessibility requirements
  /// and maintain consistent sizing across the application.
  static const double buttonMinHeight = 48;

  /// Minimum height for input field components.
  ///
  /// Ensures input fields are large enough for comfortable interaction
  /// and text entry, especially on mobile devices.
  static const double inputMinHeight = 56;
}
