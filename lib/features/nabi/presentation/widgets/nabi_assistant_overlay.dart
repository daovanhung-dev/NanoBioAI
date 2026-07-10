import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/nabi_controller.dart';
import '../../application/nabi_state.dart';
import 'nabi_character.dart';

/// Callback để app có thể mở chat theo chính sách điều hướng sẵn có.
typedef NabiOpenChat = FutureOr<void> Function(BuildContext context);

/// Cấu hình presentation của Nabi toàn cục.
class NabiOverlayConfig {
  const NabiOverlayConfig({
    this.chatRoute = '/ai-chat',
    this.onOpenChat,
    this.characterSize = 92,
    this.initialAlignment = const Alignment(0.84, 0.72),
    this.showSpeechBubble = true,
    this.isEnabled,
  });

  /// Route AI Chat hiện có của NanoBio.
  final String chatRoute;

  /// Ưu tiên callback này khi app có guard/analytics riêng cho AI Chat.
  final NabiOpenChat? onOpenChat;
  final double characterSize;
  final Alignment initialAlignment;
  final bool showSpeechBubble;

  /// Có thể khóa Nabi ở một số flow nhạy cảm mà không xóa widget khỏi app.
  final bool Function(BuildContext context)? isEnabled;
}

/// Lớp phủ đặt trên child của AppShell/ShellRoute.
///
/// - Có mặt trên mọi màn hình được bọc bởi [NabiAppShell].
/// - Chạm: thực hiện đúng vai trò của nút AI Chat cũ.
/// - Kéo: người dùng tự đặt vị trí nổi mà không chặn thao tác UI bên dưới.
/// - Nhấn giữ: thu gọn/mở rộng Nabi trong phiên hiện tại.
class NabiAssistantOverlay extends ConsumerStatefulWidget {
  const NabiAssistantOverlay({required this.config, super.key});

  final NabiOverlayConfig config;

  @override
  ConsumerState<NabiAssistantOverlay> createState() =>
      _NabiAssistantOverlayState();
}

class _NabiAssistantOverlayState extends ConsumerState<NabiAssistantOverlay>
    with SingleTickerProviderStateMixin {
  late Alignment _alignment;
  late final AnimationController _entryController;
  bool _isDragging = false;
  bool _dragMoved = false;

  @override
  void initState() {
    super.initState();
    _alignment = widget.config.initialAlignment;
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    )..forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(NabiControllerProvider);
    final enabled = widget.config.isEnabled?.call(context) ?? true;

    if (!state.isVisible || !enabled) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        return IgnorePointer(
          ignoring: !enabled,
          child: SafeArea(
            minimum: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Align(
              alignment: _alignment,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _entryController,
                  curve: Curves.easeOut,
                ),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.74, end: 1).animate(
                    CurvedAnimation(
                      parent: _entryController,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                  child: _NabiFloatingControl(
                    state: state,
                    showSpeechBubble: widget.config.showSpeechBubble,
                    characterSize: widget.config.characterSize,
                    isDragging: _isDragging,
                    isRightSide: _alignment.x >= 0,
                    onTap: _dragMoved ? null : _openChat,
                    onLongPress: () {
                      HapticFeedback.selectionClick();
                      ref
                          .read(NabiControllerProvider.notifier)
                          .toggleMinimized();
                    },
                    onPanStart: (_) {
                      setState(() {
                        _isDragging = true;
                        _dragMoved = false;
                      });
                    },
                    onPanUpdate: (details) {
                      final nextX =
                          _alignment.x +
                          details.delta.dx / constraints.maxWidth * 2;
                      final nextY =
                          _alignment.y +
                          details.delta.dy / constraints.maxHeight * 2;
                      setState(() {
                        _dragMoved = true;
                        _alignment = Alignment(
                          nextX.clamp(-0.92, 0.92).toDouble(),
                          nextY.clamp(-0.87, 0.87).toDouble(),
                        );
                      });
                    },
                    onPanEnd: (_) {
                      setState(() => _isDragging = false);
                      // GestureDetector kích hoạt onTap sau pan trong một số thiết bị.
                      Future<void>.delayed(
                        const Duration(milliseconds: 90),
                        () {
                          if (mounted) setState(() => _dragMoved = false);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openChat() async {
    HapticFeedback.lightImpact();
    final controller = ref.read(NabiControllerProvider.notifier);

    if (widget.config.onOpenChat != null) {
      await widget.config.onOpenChat!(context);
      return;
    }

    // Khi ở AI Chat, chạm Nabi chỉ đổi sang trạng thái lắng nghe; không push
    // route lặp hoặc làm mất nội dung hội thoại hiện tại.
    final state = ref.read(NabiControllerProvider);
    if (state.isChatOpen) {
      controller.setContext(
        state.context,
        detail: 'Nabi đang lắng nghe bạn đây.',
      );
      return;
    }

    controller.setChatThinking();
    if (!mounted) return;
    context.go(widget.config.chatRoute);
  }
}

class _NabiFloatingControl extends StatelessWidget {
  const _NabiFloatingControl({
    required this.state,
    required this.showSpeechBubble,
    required this.characterSize,
    required this.isDragging,
    required this.isRightSide,
    required this.onTap,
    required this.onLongPress,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  final NabiState state;
  final bool showSpeechBubble;
  final double characterSize;
  final bool isDragging;
  final bool isRightSide;
  final VoidCallback? onTap;
  final VoidCallback onLongPress;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;

  @override
  Widget build(BuildContext context) {
    final avatar = Semantics(
      button: true,
      label: state.isChatOpen
          ? 'Nabi đang lắng nghe'
          : 'Mở trò chuyện với Nabi',
      hint: 'Chạm để trò chuyện, nhấn giữ để thu gọn, kéo để đổi vị trí.',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: AnimatedScale(
          scale: isDragging ? 0.94 : 1,
          duration: const Duration(milliseconds: 120),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(characterSize),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(0.16),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: NabiCharacter(
              emotion: state.emotion,
              size: state.isMinimized ? characterSize * 0.68 : characterSize,
              minimized: state.isMinimized,
            ),
          ),
        ),
      ),
    );

    if (!showSpeechBubble || state.isMinimized) return avatar;

    final bubble = Flexible(child: _NabiSpeechBubble(text: state.bubbleText));

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 286),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        textDirection: isRightSide ? TextDirection.rtl : TextDirection.ltr,
        children: <Widget>[avatar, const SizedBox(width: 4), bubble],
      ),
    );
  }
}

class _NabiSpeechBubble extends StatelessWidget {
  const _NabiSpeechBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      alignment: Alignment.bottomCenter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.98),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.12),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Text(
            text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.28,
            ),
          ),
        ),
      ),
    );
  }
}
