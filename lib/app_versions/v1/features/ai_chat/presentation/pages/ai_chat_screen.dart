import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/app_versions/v1/features/nabi/providers/nabi_provider.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../controllers/ai_chat_controller.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late final NabiContextNotifier _nabiContextNotifier;

  int _lastMessageCount = 0;
  bool _lastLoadingState = false;

  @override
  void initState() {
    super.initState();
    _nabiContextNotifier = ref.read(nabiContextProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _nabiContextNotifier.setRoute(V1RoutePaths.aiChat);
    });
  }

  @override
  void dispose() {
    _nabiContextNotifier.setChatTyping(typing: false);
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppDuration.normal,
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _syncAutoScroll({required int messageCount, required bool isLoading}) {
    final shouldScroll =
        _lastMessageCount != messageCount || _lastLoadingState != isLoading;

    _lastMessageCount = messageCount;
    _lastLoadingState = isLoading;

    if (shouldScroll) {
      _scrollToBottom();
    }
  }

  void _sendMessage() {
    final message = _textController.text.trim();
    if (message.isEmpty) return;

    HapticFeedback.lightImpact();
    ref.read(aiChatControllerProvider.notifier).sendMessage(message);
    _textController.clear();
    _scrollToBottom();
  }

  void _sendSuggestedQuestion(String question) {
    _textController.text = question;
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiChatControllerProvider);
    final error = state.error;

    _syncAutoScroll(
      messageCount: state.messages.length,
      isLoading: state.isLoading,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: MedicalPageScaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(context),
        body: Column(
          children: [
            Expanded(
              child: state.messages.isEmpty
                  ? _ChatGptEmptyState(onQuestionTap: _sendSuggestedQuestion)
                  : _MessageList(
                      controller: _scrollController,
                      messages: state.messages,
                      isLoading: state.isLoading,
                    ),
            ),
            if (error != null)
              _ChatErrorBanner(
                message: error,
                onDismiss: () {
                  ref.read(aiChatControllerProvider.notifier).dismissError();
                },
              ),
            _ChatComposer(
              controller: _textController,
              focusNode: _focusNode,
              isLoading: state.isLoading,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      toolbarHeight: 64,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.background.withValues(alpha: .92),
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leadingWidth: 58,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        child: _MinimalIconButton(
          icon: Icons.arrow_back_rounded,
          semanticLabel: 'Quay lại',
          onTap: () => Navigator.pop(context),
        ),
      ),
      titleSpacing: 0,
      title: const _ChatHeaderTitle(),
      centerTitle: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: _MinimalIconButton(
            icon: Icons.refresh_rounded,
            semanticLabel: 'Làm mới cuộc trò chuyện',
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(aiChatControllerProvider.notifier).clearChat();
            },
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppColors.border.withValues(alpha: .42),
        ),
      ),
    );
  }
}

class _ChatErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ChatErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: AppColors.errorSoft,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.sm,
        ),
        child: _CenteredContent(
          maxWidth: 820,
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded),
                color: AppColors.error,
                iconSize: 20,
                tooltip: 'Đóng thông báo',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatHeaderTitle extends StatelessWidget {
  const _ChatHeaderTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _NamiAvatar(size: 34, iconSize: 18),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Nabi',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: .35),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Sẵn sàng lắng nghe bạn',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageList extends StatelessWidget {
  static const double _maxContentWidth = 820;

  final ScrollController controller;
  final List<ChatMessageEntity> messages;
  final bool isLoading;

  const _MessageList({
    required this.controller,
    required this.messages,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.lg,
        AppSpacing.pagePadding,
        AppSpacing.xl,
      ),
      itemCount: messages.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && isLoading) {
          return const _CenteredContent(
            maxWidth: _maxContentWidth,
            child: _TypingIndicator(),
          );
        }

        final message = messages[index];
        final isUser = message.role == MessageRole.user;

        return _CenteredContent(
          maxWidth: _maxContentWidth,
          child: _MessageRow(message: message, isUser: isUser),
        );
      },
    );
  }
}

class _MessageRow extends StatelessWidget {
  final ChatMessageEntity message;
  final bool isUser;

  const _MessageRow({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const _NamiAvatar(size: 34, iconSize: 17),
            const SizedBox(width: AppSpacing.md),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isUser ? 620 : double.infinity,
              ),
              child: isUser
                  ? _UserMessageBubble(message: message)
                  : _AssistantMessage(message: message),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantMessage extends StatelessWidget {
  final ChatMessageEntity message;

  const _AssistantMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppDuration.normal,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              message.content,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                height: 1.72,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            _MessageTime(time: message.timestamp, isUser: false),
          ],
        ),
      ),
    );
  }
}

class _UserMessageBubble extends StatelessWidget {
  final ChatMessageEntity message;

  const _UserMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppDuration.normal,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.lg),
            topRight: Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(AppRadius.lg),
            bottomRight: Radius.circular(AppRadius.sm),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: .16),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SelectableText(
              message.content,
              textAlign: TextAlign.left,
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white,
                height: 1.56,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            _MessageTime(time: message.timestamp, isUser: true),
          ],
        ),
      ),
    );
  }
}

class _MessageTime extends StatelessWidget {
  final DateTime time;
  final bool isUser;

  const _MessageTime({required this.time, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return Text(
      '$hour:$minute',
      style: AppTextStyles.caption.copyWith(
        color: isUser
            ? Colors.white.withValues(alpha: .72)
            : AppColors.textMuted,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _ChatGptEmptyState extends StatelessWidget {
  static const double _maxContentWidth = 760;

  final ValueChanged<String> onQuestionTap;

  const _ChatGptEmptyState({required this.onQuestionTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.xl,
          AppSpacing.pagePadding,
          AppSpacing.xl,
        ),
        child: _CenteredContent(
          maxWidth: _maxContentWidth,
          child: Column(
            children: [
              const _NamiHeroMark(),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Hôm nay bạn muốn Nabi giúp gì?',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.3,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Hỏi về ăn uống, ngủ, vận động, cảm xúc hoặc điều bạn bận tâm.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.62,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _PromptGrid(onQuestionTap: onQuestionTap),
              const SizedBox(height: AppSpacing.lg),
              _CareNote(),
            ],
          ),
        ),
      ),
    );
  }
}

class _NamiHeroMark extends StatelessWidget {
  const _NamiHeroMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: AppGradients.ai.colors),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .18),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(6),
        child: Container(
          decoration: AppDecoration.base(
            gradient: AppGradients.ai,
            shape: BoxShape.circle,
          ),
          child: const Icon(AppIcons.aiChat, color: Colors.white, size: 34),
        ),
      ),
    );
  }
}

class _PromptGrid extends StatelessWidget {
  final ValueChanged<String> onQuestionTap;

  const _PromptGrid({required this.onQuestionTap});

  static const List<_PromptAction> _items = [
    _PromptAction(
      icon: Icons.bedtime_rounded,
      title: 'Cải thiện giấc ngủ',
      subtitle: 'Nabi ơi, làm sao để mình ngủ sâu hơn?',
    ),
    _PromptAction(
      icon: Icons.restaurant_rounded,
      title: 'Gợi ý bữa ăn',
      subtitle: 'Hôm nay mình nên ăn gì cho nhẹ bụng?',
    ),
    _PromptAction(
      icon: Icons.self_improvement_rounded,
      title: 'Giảm căng thẳng',
      subtitle: 'Mình đang hơi căng thẳng, Nabi giúp mình với.',
    ),
    _PromptAction(
      icon: Icons.directions_walk_rounded,
      title: 'Vận động nhẹ',
      subtitle: 'Gợi ý cho mình vài bài tập nhẹ hôm nay.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 560;

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _items.map((item) {
            final width = isNarrow
                ? constraints.maxWidth
                : (constraints.maxWidth - AppSpacing.sm) / 2;

            return SizedBox(
              width: width,
              child: _PromptCard(
                item: item,
                onTap: () => onQuestionTap(item.subtitle),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _PromptCard extends StatelessWidget {
  final _PromptAction item;
  final VoidCallback onTap;

  const _PromptCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Gợi ý: ${item.title}',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: AppColors.border.withValues(alpha: .62),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(item.icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CareNote extends StatelessWidget {
  const _CareNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(Icons.favorite_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Vấn đề sức khỏe nghiêm trọng vẫn nên hỏi bác sĩ.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatComposer extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSend;

  const _ChatComposer({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
  });

  @override
  State<_ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<_ChatComposer> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChanged);
    widget.focusNode.addListener(_handleFocusChanged);
    _hasText = widget.controller.text.trim().isNotEmpty;
  }

  @override
  void didUpdateWidget(covariant _ChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTextChanged);
      widget.controller.addListener(_handleTextChanged);
      _handleTextChanged();
    }

    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      widget.focusNode.addListener(_handleFocusChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    widget.focusNode.removeListener(_handleFocusChanged);
    super.dispose();
  }

  void _handleTextChanged() {
    final next = widget.controller.text.trim().isNotEmpty;
    if (_hasText == next) return;

    setState(() => _hasText = next);
  }

  void _handleFocusChanged() {
    setState(() {});
  }

  void _submit() {
    if (!_hasText || widget.isLoading) return;
    widget.onSend();
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _hasText && !widget.isLoading;
    final focused = widget.focusNode.hasFocus;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          color: AppColors.background.withValues(alpha: .92),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.sm,
            AppSpacing.pagePadding,
            AppSpacing.sm,
          ),
          child: SafeArea(
            top: false,
            child: _CenteredContent(
              maxWidth: 820,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: AppDuration.fast,
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.sm,
                      AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(
                        color: focused
                            ? AppColors.primary.withValues(alpha: .38)
                            : AppColors.border.withValues(alpha: .72),
                        width: focused ? 1.4 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textPrimary.withValues(alpha: .06),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: 30,
                              maxHeight: 140,
                            ),
                            child: TextField(
                              controller: widget.controller,
                              focusNode: widget.focusNode,
                              enabled: !widget.isLoading,
                              maxLines: null,
                              minLines: 1,
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              textCapitalization: TextCapitalization.sentences,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textPrimary,
                                height: 1.48,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Nhắn cho Nabi...',
                                hintStyle: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.textMuted,
                                  height: 1.48,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _SendButton(
                          canSend: canSend,
                          isLoading: widget.isLoading,
                          onTap: _submit,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Nabi có thể chưa luôn chính xác. Bạn hãy kiểm tra lại những thông tin quan trọng nhé.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool canSend;
  final bool isLoading;
  final VoidCallback onTap;

  const _SendButton({
    required this.canSend,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = canSend ? AppColors.primary : AppColors.border;
    final foreground = canSend ? Colors.white : AppColors.textMuted;

    return Semantics(
      label: 'Gửi tin nhắn',
      button: true,
      enabled: canSend,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: canSend ? onTap : null,
        child: AnimatedContainer(
          duration: AppDuration.fast,
          curve: Curves.easeOutCubic,
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            boxShadow: canSend
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: .22),
                      blurRadius: 16,
                      offset: const Offset(0, 7),
                    ),
                  ]
                : null,
          ),
          child: AnimatedSwitcher(
            duration: AppDuration.fast,
            child: isLoading
                ? const SizedBox(
                    key: ValueKey('send-loading'),
                    width: 18,
                    height: 18,
                    child: Center(
                      child: SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : Icon(
                    key: const ValueKey('send-ready'),
                    Icons.arrow_upward_rounded,
                    color: foreground,
                    size: 21,
                  ),
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _NamiAvatar(size: 34, iconSize: 17),
          const SizedBox(width: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final phase = (_controller.value + index * .18) % 1;
                    final scale = .55 + (.45 * (1 - (phase - .5).abs() * 2));

                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(
                            alpha: .35 + scale * .45,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MinimalIconButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  const _MinimalIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon),
        color: AppColors.textPrimary,
        iconSize: 23,
        splashRadius: 24,
        tooltip: semanticLabel,
      ),
    );
  }
}

class _NamiAvatar extends StatelessWidget {
  final double size;
  final double iconSize;

  const _NamiAvatar({this.size = 36, this.iconSize = 20});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: AppGradients.ai.colors),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: AppDecoration.base(
            gradient: AppGradients.ai,
            shape: BoxShape.circle,
          ),
          child: Icon(AppIcons.aiChat, color: Colors.white, size: iconSize),
        ),
      ),
    );
  }
}

class _CenteredContent extends StatelessWidget {
  final double maxWidth;
  final Widget child;

  const _CenteredContent({required this.maxWidth, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class _PromptAction {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PromptAction({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
