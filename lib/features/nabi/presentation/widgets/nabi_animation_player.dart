import 'package:flutter/material.dart';

import '../../data/nabi_assets.dart';
import '../../domain/nabi_animation_type.dart';

class NabiAnimationPlayer extends StatefulWidget {
  const NabiAnimationPlayer({
    super.key,
    this.animationType = NabiAnimationType.idle,
    this.spec,
    this.size = 96,
    this.fit = BoxFit.contain,
    this.filterQuality = FilterQuality.medium,
    this.fallbackIcon,
  });

  final NabiAnimationType animationType;
  final NabiAnimationSpec? spec;
  final double size;
  final BoxFit fit;
  final FilterQuality filterQuality;
  final Widget? fallbackIcon;

  @override
  State<NabiAnimationPlayer> createState() => _NabiAnimationPlayerState();
}

class _NabiAnimationPlayerState extends State<NabiAnimationPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late NabiAnimationSpec _spec;

  @override
  void initState() {
    super.initState();
    _spec = _resolveSpec();
    _controller = AnimationController(vsync: this, duration: _spec.duration);
    _start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    NabiAssets.precacheFirstFrame(context, _spec);
  }

  @override
  void didUpdateWidget(covariant NabiAnimationPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextSpec = _resolveSpec();
    if (nextSpec.id == _spec.id &&
        nextSpec.loop == _spec.loop &&
        nextSpec.fps == _spec.fps &&
        nextSpec.frameCount == _spec.frameCount) {
      return;
    }

    _spec = nextSpec;
    _controller
      ..duration = _spec.duration
      ..stop();
    NabiAssets.precacheFirstFrame(context, _spec);
    _start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  NabiAnimationSpec _resolveSpec() {
    return widget.spec ?? NabiAssets.specFor(widget.animationType);
  }

  void _start() {
    if (_spec.loop) {
      _controller.repeat();
    } else {
      _controller.forward(from: 0);
    }
  }

  int _frameForValue(double value) {
    final frame = (value * _spec.frameCount).floor() + 1;
    return frame.clamp(1, _spec.frameCount).toInt();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final frame = _frameForValue(_controller.value);
          return Image.asset(
            _spec.framePath(frame),
            width: widget.size,
            height: widget.size,
            fit: widget.fit,
            gaplessPlayback: true,
            filterQuality: widget.filterQuality,
            errorBuilder: (context, error, stackTrace) {
              return _NabiStaticFallback(
                spec: _spec,
                size: widget.size,
                fit: widget.fit,
                fallbackIcon: widget.fallbackIcon,
              );
            },
          );
        },
      ),
    );
  }
}

class _NabiStaticFallback extends StatelessWidget {
  const _NabiStaticFallback({
    required this.spec,
    required this.size,
    required this.fit,
    this.fallbackIcon,
  });

  final NabiAnimationSpec spec;
  final double size;
  final BoxFit fit;
  final Widget? fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      spec.staticFallbackAsset,
      width: size,
      height: size,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        return fallbackIcon ??
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: size * 0.42,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            );
      },
    );
  }
}
