import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nano_app/app_versions/v1/features/nabi/providers/nabi_provider.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/core/membership/membership_upgrade_route.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/shared/membership/presentation/membership_upgrade_navigation.dart';
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
  late final NabiContextNotifier _nabi;

  bool _nearBottom = true;
  bool _forceNextScroll = false;
  bool _hasUnreadAnswer = false;

  @override
  void initState() {
    super.initState();
    _nabi = ref.read(nabiContextProvider.notifier);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _nabi.setRoute(V1RoutePaths.aiChat);
    });
  }

  @override
  void dispose() {
    _nabi.setChatTyping(typing: false);
    _scrollController.removeListener(_onScroll);
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final distance =
        _scrollController.position.maxScrollExtent - _scrollController.position.pixels;
    final near = distance <= 96;
    if (near == _nearBottom) return;
    setState(() {
      _nearBottom = near;
      if (near) _hasUnreadAnswer = false;
    });
  }

  void _scrollToBottom({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (immediate || AppMotionScope.reduceMotionOf(context)) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: AppDuration.normal,
          curve: AppAnimations.emphasizedCurve,
        );
      }
      if (_hasUnreadAnswer) setState(() => _hasUnreadAnswer = false);
    });
  }

  void _sendMessage() {
    final message = _textController.text.trim();
    if (message.isEmpty) return;
    AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
    _forceNextScroll = true;
    ref.read(aiChatControllerProvider.notifier).sendMessage(message);
    _textController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiChatControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlayStyle =
        (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: context.semanticColors.background,
              systemNavigationBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
            );

    ref.listen<AIChatState>(aiChatControllerProvider, (previous, next) {
      final responseArrived =
          previous?.isLoading == true &&
          !next.isLoading &&
          next.messages.length > (previous?.messages.length ?? 0) &&
          next.messages.last.role == MessageRole.assistant;
      if (responseArrived) {
        AppFeedbackService.instance.emit(AppFeedbackType.answerReady);
        if (_forceNextScroll || _nearBottom) {
          _forceNextScroll = false;
          _scrollToBottom();
        } else if (mounted) {
          setState(() => _hasUnreadAnswer = true);
        }
      }
      if (next.isLoading && (_forceNextScroll || _nearBottom)) {
        _scrollToBottom();
      }
      if (next.error != null && next.error != previous?.error) {
        AppFeedbackService.instance.emit(AppFeedbackType.error);
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: MedicalPageScaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: context.semanticColors.background,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: context.semanticColors.background,
          systemOverlayStyle: overlayStyle,
          leading: IconButton(
            tooltip: 'Quay lại',
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const _ChatTitle(),
          actions: [
            IconButton(
              tooltip: 'Trò chuyện bằng giọng nói',
              onPressed: () => context.push(V1RoutePaths.aiVoice),
              icon: const Icon(Icons.mic_rounded),
            ),
            IconButton(
              tooltip: 'Làm mới cuộc trò chuyện',
              onPressed: () {
                ref.read(aiChatControllerProvider.notifier).clearChat();
                setState(() => _hasUnreadAnswer = false);
              },
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  state.messages.isEmpty
                      ? _EmptyChat(onQuestionTap: (value) {
                          _textController.text = value;
                          _sendMessage();
                        })
                      : ListView.builder(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.pagePadding,
                            AppSpacing.sm,
                            AppSpacing.pagePadding,
                            AppSpacing.xxl,
                          ),
                          itemCount:
                              state.messages.length + (state.isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == state.messages.length) {
                              return const _TypingIndicator();
                            }
                            return _MessageBubble(message: state.messages[index]);
                          },
                        ),
                  if (_hasUnreadAnswer)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: FilledButton.tonalIcon(
                        onPressed: _scrollToBottom,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        label: const Text('Tin nhắn mới'),
                      ),
                    ),
                ],
              ),
            ),
            if (state.error != null)
              _ErrorBanner(
                message: state.error!,
                onRetry: state.canRetry
                    ? ref.read(aiChatControllerProvider.notifier).retryLastMessage
                    : null,
                onUpgrade: state.showPlusUpgrade
                    ? () => openMembershipUpgrade(
                          context,
                          planCode: MembershipUpgradePlan.plus,
                        )
                    : null,
                onDismiss:
                    ref.read(aiChatControllerProvider.notifier).dismissError,
              ),
            SafeArea(
              top: false,
              child: _Composer(
                controller: _textController,
                focusNode: _focusNode,
                loading: state.isLoading,
                onSend: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatTitle extends StatelessWidget {
  const _ChatTitle();
  @override
  Widget build(BuildContext context) => Row(children: [
    CircleAvatar(
      radius: 16,
      backgroundColor: context.semanticColors.primarySoft,
      child: Icon(Icons.auto_awesome_rounded,
          color: context.semanticColors.primary, size: 18),
    ),
    const SizedBox(width: AppSpacing.sm),
    Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Nabi', style: AppTextStyles.labelLarge),
        Text('Sẵn sàng lắng nghe bạn',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
                color: context.semanticColors.textSecondary)),
      ]),
    ),
  ]);
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.onQuestionTap});
  final ValueChanged<String> onQuestionTap;
  @override
  Widget build(BuildContext context) {
    const prompts = [
      'Nabi ơi, làm sao để mình ngủ sâu hơn?',
      'Hôm nay mình nên ăn gì cho nhẹ bụng?',
      'Mình đang hơi căng thẳng, Nabi giúp mình với.',
      'Gợi ý cho mình vài bài tập nhẹ hôm nay.',
    ];
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(children: [
            Icon(Icons.auto_awesome_rounded,
                size: 48, color: context.semanticColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text('Hôm nay bạn muốn Nabi giúp gì?',
                textAlign: TextAlign.center, style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.lg),
            for (final prompt in prompts)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => onQuestionTap(prompt),
                    child: Text(prompt, textAlign: TextAlign.left),
                  ),
                ),
              ),
            Text(
              'Vấn đề sức khỏe nghiêm trọng vẫn nên hỏi bác sĩ.',
              style: AppTextStyles.caption.copyWith(
                  color: context.semanticColors.textSecondary),
            ),
          ]),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessageEntity message;
  @override
  Widget build(BuildContext context) {
    final user = message.role == MessageRole.user;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: user
              ? context.semanticColors.primary
              : context.semanticColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: user ? null : Border.all(color: context.semanticColors.border),
        ),
        child: SelectableText(
          message.content,
          style: AppTextStyles.bodyLarge.copyWith(
            color: user
                ? context.semanticColors.surface
                : context.semanticColors.textPrimary,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(children: [
      const SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      const SizedBox(width: AppSpacing.sm),
      Text('Nabi đang suy nghĩ...', style: AppTextStyles.bodyMedium),
    ]),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss,
      this.onRetry, this.onUpgrade});
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onUpgrade;
  final VoidCallback onDismiss;
  @override
  Widget build(BuildContext context) => Material(
    color: context.semanticColors.errorSoft,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding, vertical: AppSpacing.sm),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message)),
          if (onUpgrade != null)
            TextButton(onPressed: onUpgrade, child: const Text('Nâng cấp Plus'))
          else if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Thử lại')),
          IconButton(
            tooltip: 'Đóng thông báo',
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded),
          ),
        ]),
      ),
    ),
  );
}

class _Composer extends StatefulWidget {
  const _Composer({required this.controller, required this.focusNode,
      required this.loading, required this.onSend});
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool loading;
  final VoidCallback onSend;
  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }
  @override
  void didUpdateWidget(covariant _Composer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }
  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }
  void _changed() => setState(() {});
  @override
  Widget build(BuildContext context) {
    final canSend = widget.controller.text.trim().isNotEmpty && !widget.loading;
    return Container(
      color: context.semanticColors.background,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding, AppSpacing.sm, AppSpacing.pagePadding, AppSpacing.sm),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            enabled: !widget.loading,
            minLines: 1,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Nhắn cho Nabi...'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton.filled(
          tooltip: 'Gửi',
          onPressed: canSend ? widget.onSend : null,
          icon: widget.loading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.arrow_upward_rounded),
        ),
      ]),
    );
  }
}
