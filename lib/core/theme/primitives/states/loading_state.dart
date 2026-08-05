import 'package:flutter/material.dart';

import '../../tokens/color_tokens.dart';
import '../../tokens/component_tokens.dart';
import '../../tokens/spacing_tokens.dart';

/// Loading state variants for different loading patterns.
enum LoadingVariant { spinner, skeleton, shimmer }

/// Consistent loading surface with reduced-motion support.
class LoadingState extends StatefulWidget {
  const LoadingState({super.key, required this.variant, this.message});

  final LoadingVariant variant;
  final String? message;

  @override
  State<LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<LoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotionTokens.shimmer,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduceMotion == reduceMotion && _controller.isAnimating) {
      return;
    }
    _reduceMotion = reduceMotion;
    if (_reduceMotion || widget.variant != LoadingVariant.shimmer) {
      _controller
        ..stop()
        ..value = 0.5;
    } else {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant LoadingState oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.variant == widget.variant) {
      return;
    }
    if (_reduceMotion || widget.variant != LoadingVariant.shimmer) {
      _controller
        ..stop()
        ..value = 0.5;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final semanticMessage = widget.message ?? 'Nabi đang chuẩn bị nội dung';

    return Semantics(
      liveRegion: true,
      label: semanticMessage,
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacingTokens.pagePadding),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIndicator(isDark),
                if (widget.message != null) ...[
                  SizedBox(height: AppSpacingTokens.sectionSpacing),
                  Text(
                    widget.message!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark
                          ? AppColorTokens.darkTextSecondary
                          : AppColorTokens.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator(bool isDark) {
    switch (widget.variant) {
      case LoadingVariant.spinner:
        return const SizedBox.square(
          dimension: AppSpacingTokens.touchTargetMin,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            color: AppColorTokens.primary,
          ),
        );
      case LoadingVariant.skeleton:
        return _SkeletonPanel(isDark: isDark);
      case LoadingVariant.shimmer:
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            if (_reduceMotion) {
              return child!;
            }
            final progress = _controller.value;
            return ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment(-1.5 + (progress * 3), 0),
                end: Alignment(-0.5 + (progress * 3), 0),
                colors: [
                  _skeletonColor(isDark),
                  _highlightColor(isDark),
                  _skeletonColor(isDark),
                ],
                stops: const [0, 0.5, 1],
              ).createShader(bounds),
              child: child,
            );
          },
          child: _SkeletonPanel(isDark: isDark),
        );
    }
  }

  Color _skeletonColor(bool isDark) => isDark
      ? AppColorTokens.darkSurfaceElevated
      : AppColorTokens.surfaceElevated;

  Color _highlightColor(bool isDark) => isDark
      ? AppColorTokens.darkBorder
      : AppColorTokens.primaryLight;
}

class _SkeletonPanel extends StatelessWidget {
  const _SkeletonPanel({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final fill = isDark
        ? AppColorTokens.darkSurfaceElevated
        : AppColorTokens.surfaceElevated;

    Widget block({required double height, double? width}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppRadiusTokens.input),
        ),
      );
    }

    return ExcludeSemantics(
      child: SizedBox(
        width: 360,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            block(height: 24, width: 220),
            SizedBox(height: AppSpacingTokens.itemSpacing),
            block(height: 16),
            SizedBox(height: AppSpacingTokens.itemSpacing),
            block(height: 16, width: 280),
            SizedBox(height: AppSpacingTokens.sectionSpacing),
            Row(
              children: [
                Expanded(child: block(height: 92)),
                SizedBox(width: AppSpacingTokens.itemSpacingLarge),
                Expanded(child: block(height: 92)),
              ],
            ),
            SizedBox(height: AppSpacingTokens.itemSpacingLarge),
            block(height: 72),
          ],
        ),
      ),
    );
  }
}
