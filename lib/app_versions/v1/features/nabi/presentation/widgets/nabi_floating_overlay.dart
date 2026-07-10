import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/features/nabi/nabi.dart' as shared_nabi;

import '../../application/nabi_visual_animation_mapper.dart';
import '../../domain/nabi_visual_state.dart';
import '../../providers/nabi_provider.dart';
import 'nabi_character_widget.dart';

/// Nabi nổi có thể kéo thả, hiển thị ở bất kỳ trang nào.
///
/// Thay thế hoàn toàn [DraggableAIChatButton] cũ. Đặt vào Stack của
/// [MainNavigationPage] hoặc bất kỳ Scaffold nào cần Nabi nổi.
///
/// ```dart
/// Stack(
///   children: [
///     child,
///     const NabiFloatingOverlay(),
///   ],
/// )
/// ```
class NabiFloatingOverlay extends ConsumerStatefulWidget {
  /// Khoảng cách đáy tối thiểu (để tránh đè lên bottom nav).
  final double bottomReserve;

  /// Hiện label "Hỏi Nabi" phía dưới.
  final bool showLabel;

  /// Ẩn/hiện toàn bộ overlay.
  final bool visible;

  /// Override callback khi chạm – mặc định mở AI chat.
  final VoidCallback? onTap;

  const NabiFloatingOverlay({
    super.key,
    this.bottomReserve = 132,
    this.showLabel = true,
    this.visible = true,
    this.onTap,
  });

  @override
  ConsumerState<NabiFloatingOverlay> createState() =>
      _NabiFloatingOverlayState();
}

class _NabiFloatingOverlayState extends ConsumerState<NabiFloatingOverlay>
    with SingleTickerProviderStateMixin {
  static const double _nabiSize = 80;
  static const double _containerWidth = 96;
  static const double _containerHeight = 104;

  Offset? _offset;
  bool _isDragging = false;

  // Entrance animation
  late final AnimationController _entranceController;
  late final Animation<double> _entranceScale;
  late final Animation<double> _entranceOpacity;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: AppDuration.slow,
    );

    _entranceScale = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );

    _entranceOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0, 0.7, curve: Curves.easeOut),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Offset _defaultOffset(Size size, EdgeInsets padding) {
    return Offset(
      (size.width - _containerWidth - AppSpacing.md).clamp(
        AppSpacing.md,
        double.infinity,
      ),
      (size.height - _containerHeight - widget.bottomReserve - padding.bottom)
          .clamp(padding.top + AppSpacing.md, double.infinity),
    );
  }

  Offset _clampOffset(Offset raw, Size size, EdgeInsets padding) {
    return Offset(
      raw.dx
          .clamp(AppSpacing.md, size.width - _containerWidth - AppSpacing.md)
          .toDouble(),
      raw.dy
          .clamp(
            padding.top + AppSpacing.md,
            size.height - _containerHeight - widget.bottomReserve,
          )
          .toDouble(),
    );
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    ref.read(NabiContextProvider.notifier).setRoute(V1RoutePaths.aiChat);
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      context.push(V1RoutePaths.aiChat);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visualState = ref.watch(NabiVisualStateProvider);
    final animationType = NabiVisualAnimationMapper.fromVisualState(
      visualState,
    );

    return IgnorePointer(
      ignoring: !widget.visible,
      child: AnimatedOpacity(
        opacity: widget.visible ? 1 : 0,
        duration: AppDuration.fast,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final padding = MediaQuery.paddingOf(context);
            final offset = _offset ?? _defaultOffset(size, padding);

            return Stack(
              children: [
                Positioned(
                  left: offset.dx,
                  top: offset.dy,
                  child: AnimatedBuilder(
                    animation: _entranceController,
                    builder: (_, child) => Opacity(
                      opacity: _entranceOpacity.value,
                      child: Transform.scale(
                        scale: _entranceScale.value,
                        child: child,
                      ),
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanStart: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => _isDragging = true);
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          _offset = _clampOffset(
                            offset + details.delta,
                            size,
                            padding,
                          );
                        });
                      },
                      onPanEnd: (_) {
                        setState(() => _isDragging = false);
                        _snapToEdge(size, padding);
                      },
                      onLongPress: () {
                        HapticFeedback.mediumImpact();
                        setState(() => _offset = _defaultOffset(size, padding));
                      },
                      child: SizedBox(
                        width: _containerWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Nabi character
                            AnimatedScale(
                              scale: _isDragging ? 0.9 : 1.0,
                              duration: AppDuration.fast,
                              curve: Curves.easeOutCubic,
                              child:
                                  shared_nabi
                                      .NabiFeatureFlags
                                      .spriteMascotEnabled
                                  ? shared_nabi.NaBiFloatingMascot(
                                      animationType: animationType,
                                      size: _nabiSize,
                                      showLabel: false,
                                      enabled: !_isDragging,
                                      semanticLabel:
                                          'Nabi - cham de mo chat voi Nabi',
                                      onTap: _handleTap,
                                    )
                                  : NabiCharacterWidget(
                                      size: _nabiSize,
                                      showAura: !_isDragging,
                                      onTap: _handleTap,
                                      semanticLabel:
                                          'Nabi – chạm để mở chat với Nabi',
                                    ),
                            ),

                            // Label phía dưới
                            if (widget.showLabel) ...[
                              const SizedBox(height: 5),
                              _NabiLabel(isDragging: _isDragging),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Snap về cạnh trái hoặc phải gần nhất khi thả.
  void _snapToEdge(Size size, EdgeInsets padding) {
    final currentOffset = _offset;
    if (currentOffset == null) return;

    final midX = size.width / 2;
    final targetX = currentOffset.dx + _containerWidth / 2 < midX
        ? AppSpacing.md
        : size.width - _containerWidth - AppSpacing.md;

    setState(() {
      _offset = _clampOffset(Offset(targetX, currentOffset.dy), size, padding);
    });
  }
}

class _NabiLabel extends ConsumerWidget {
  final bool isDragging;

  const _NabiLabel({required this.isDragging});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(NabiVisualStateProvider);

    final labelText = switch (state) {
      NabiVisualState.chatTyping ||
      NabiVisualState.chatReasoning ||
      NabiVisualState.aiGeneratingPlan => 'Đang suy nghĩ…',
      NabiVisualState.chatAnswerReady => 'Nabi trả lời',
      NabiVisualState.loading || NabiVisualState.syncing => 'Đang tải…',
      NabiVisualState.offline => 'Ngoại tuyến',
      NabiVisualState.taskComplete ||
      NabiVisualState.dayComplete => 'Tuyệt vời',
      _ => 'Hỏi Nabi',
    };

    return AnimatedOpacity(
      opacity: isDragging ? 0 : 1,
      duration: AppDuration.fast,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppRadius.circular),
          boxShadow: AppShadows.md,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: AnimatedSwitcher(
          duration: AppDuration.fast,
          child: Text(
            labelText,
            key: ValueKey(labelText),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
}
