import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/nabi_assets.dart';
import '../../domain/nabi_animation_type.dart';
import 'nabi_animation_player.dart';

class NaBiFloatingMascot extends StatefulWidget {
  const NaBiFloatingMascot({
    super.key,
    this.animationType = NabiAnimationType.idle,
    this.onTap,
    this.size,
    this.showLabel = true,
    this.label,
    this.semanticLabel = 'Nabi - chạm để mở trò chuyện',
    this.enabled = true,
  });

  final NabiAnimationType animationType;
  final FutureOr<void> Function()? onTap;
  final double? size;
  final bool showLabel;
  final String? label;
  final String semanticLabel;
  final bool enabled;

  @override
  State<NaBiFloatingMascot> createState() => _NaBiFloatingMascotState();
}

class _NaBiFloatingMascotState extends State<NaBiFloatingMascot> {
  NabiAnimationType? _temporaryAnimation;
  bool _pressed = false;
  bool _preloaded = false;

  NabiAnimationType get _currentAnimation {
    return _temporaryAnimation ?? widget.animationType;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_preloaded) return;
    _preloaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      NabiAssets.precacheCoreAnimations(context);
    });
  }

  @override
  void didUpdateWidget(covariant NaBiFloatingMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationType != widget.animationType &&
        _temporaryAnimation == null) {
      NabiAssets.precacheFirstFrame(
        context,
        NabiAssets.specFor(widget.animationType),
      );
    }
  }

  Future<void> _handleTap() async {
    if (!widget.enabled) return;
    HapticFeedback.mediumImpact();

    setState(() {
      _pressed = false;
      _temporaryAnimation = NabiAnimationType.greeting;
    });

    await Future<void>.delayed(const Duration(milliseconds: 380));
    if (!mounted) return;

    final callback = widget.onTap;
    if (callback != null) {
      await callback();
    }

    if (!mounted) return;
    setState(() => _temporaryAnimation = null);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedSize = _resolveSize(context, widget.size);
    final mascot = Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      child: Tooltip(
        message: widget.semanticLabel,
        waitDuration: const Duration(milliseconds: 450),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.enabled
              ? (_) {
                  HapticFeedback.selectionClick();
                  setState(() => _pressed = true);
                }
              : null,
          onTapCancel: widget.enabled
              ? () => setState(() => _pressed = false)
              : null,
          onTapUp: widget.enabled
              ? (_) => setState(() => _pressed = false)
              : null,
          onTap: widget.enabled ? _handleTap : null,
          child: AnimatedScale(
            scale: _pressed ? 0.92 : 1,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOutCubic,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.22),
                    blurRadius: lerpDouble(18, 26, _pressed ? 0 : 1)!,
                    spreadRadius: 1,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: SizedBox.square(
                dimension: resolvedSize,
                child: NabiAnimationPlayer(
                  animationType: _currentAnimation,
                  size: resolvedSize,
                  fallbackIcon: Icon(
                    Icons.auto_awesome_rounded,
                    size: resolvedSize * 0.42,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!widget.showLabel) return mascot;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        mascot,
        const SizedBox(height: 5),
        _MascotLabel(text: widget.label ?? 'Hỏi Nabi'),
      ],
    );
  }

  double _resolveSize(BuildContext context, double? explicitSize) {
    if (explicitSize != null) return explicitSize;

    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 78;
    if (width < 600) return 92;
    return 118;
  }
}

class _MascotLabel extends StatelessWidget {
  const _MascotLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
