import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

/// Foundation motion tokens defining animation durations and curves.
///
/// These are primitive, immutable values that form the base of the motion vocabulary.
/// Use semantic motion tokens from `AppMotionTokens` instead of referencing these directly.
///
/// **Duration Scale:**
/// - `fast` (150ms): Quick micro-interactions like button presses and hover states
/// - `normal` (250ms): Standard component transitions like cards and inputs
/// - `slow` (350ms): Page-level transitions and complex animations
///
/// **Curves:**
/// - `easeIn`: Accelerating motion, starting slow and ending fast
/// - `easeOut`: Decelerating motion, starting fast and ending slow
/// - `easeInOut`: Smooth motion, accelerating then decelerating (default for most animations)
///
/// Example usage:
/// ```dart
/// AnimatedContainer(
///   duration: MotionFoundation.normal,
///   curve: MotionFoundation.easeInOut,
///   // ...
/// )
/// ```
@immutable
class MotionFoundation {
  const MotionFoundation._();

  // ============================================================
  // DURATIONS
  // ============================================================

  /// Fast duration for quick micro-interactions (150ms).
  ///
  /// Use for:
  /// - Button press feedback
  /// - Hover state transitions
  /// - Focus ring appearances
  /// - Ripple effects
  static const Duration fast = Duration(milliseconds: 150);

  /// Normal duration for standard component transitions (250ms).
  ///
  /// Use for:
  /// - Card animations
  /// - Input field transitions
  /// - Modal appearances
  /// - Dropdown expansions
  static const Duration normal = Duration(milliseconds: 250);

  /// Slow duration for page-level transitions and complex animations (350ms).
  ///
  /// Use for:
  /// - Page transitions
  /// - Dialog openings
  /// - Bottom sheet slides
  /// - Complex multi-element animations
  static const Duration slow = Duration(milliseconds: 350);

  // ============================================================
  // CURVES
  // ============================================================

  /// Ease-in curve: accelerating motion, starting slow and ending fast.
  ///
  /// Use for:
  /// - Elements exiting the viewport
  /// - Dismissal animations
  /// - Elements accelerating off-screen
  static const Curve easeIn = Curves.easeIn;

  /// Ease-out curve: decelerating motion, starting fast and ending slow.
  ///
  /// Use for:
  /// - Elements entering the viewport
  /// - Appearance animations
  /// - Elements decelerating to rest
  static const Curve easeOut = Curves.easeOut;

  /// Ease-in-out curve: smooth motion, accelerating then decelerating.
  ///
  /// Use for:
  /// - Most standard animations (default choice)
  /// - State changes
  /// - Property transitions
  /// - Bidirectional movements
  static const Curve easeInOut = Curves.easeInOut;
}
