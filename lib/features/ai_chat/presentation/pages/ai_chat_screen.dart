import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../controllers/ai_chat_controller.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  late final AnimationController _backgroundController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _backgroundController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted || !_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppDuration.normal,
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _sendMessage() {
    final message = _textController.text.trim();
    if (message.isEmpty) return;

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

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          _AnimatedBackground(
            backgroundController: _backgroundController,
            pulseController: _pulseController,
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: AppDuration.normal,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: state.messages.isEmpty
                        ? _EmptyNamiState(
                            key: const ValueKey('empty-chat'),
                            onQuestionTap: _sendSuggestedQuestion,
                          )
                        : _buildMessageList(state.messages, state.isLoading),
                  ),
                ),
                _InputArea(
                  controller: _textController,
                  focusNode: _focusNode,
                  isLoading: state.isLoading,
                  onSend: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.md),
        child: _GlassIconButton(
          icon: Icons.arrow_back_rounded,
          semanticLabel: 'Quay lại',
          onTap: () => Navigator.pop(context),
        ),
      ),
      title: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.circular),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: AppDecoration.glass(
              opacity: 0.92,
              radius: AppRadius.circular,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _NamiAvatar(size: 34, iconSize: 18),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nami',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withValues(
                                  alpha: 0.45,
                                ),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Đang lắng nghe bạn',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md),
          child: _GlassIconButton(
            icon: Icons.refresh_rounded,
            semanticLabel: 'Làm mới cuộc trò chuyện',
            onTap: () {
              ref.read(aiChatControllerProvider.notifier).clearChat();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMessageList(List<ChatMessageEntity> messages, bool isLoading) {
    return ListView.builder(
      key: const ValueKey('message-list'),
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.xl,
        AppSpacing.pagePadding,
        AppSpacing.md,
      ),
      itemCount: messages.length + (isLoading ? 2 : 1),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const _ConversationWarmNote();
        }

        final messageIndex = index - 1;

        if (messageIndex == messages.length && isLoading) {
          return const _TypingIndicator();
        }

        final message = messages[messageIndex];
        final isUser = message.role == MessageRole.user;

        return _MessageBubble(message: message, isUser: isUser);
      },
    );
  }
}

class _EmptyNamiState extends StatelessWidget {
  final ValueChanged<String> onQuestionTap;

  const _EmptyNamiState({super.key, required this.onQuestionTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.xl,
        AppSpacing.pagePadding,
        AppSpacing.xl,
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.92, end: 1),
            duration: AppDuration.slow,
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              width: 132,
              height: 132,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.16),
                    AppColors.secondary.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Container(
                decoration: AppDecoration.base(
                  gradient: AppGradients.ai,
                  shape: BoxShape.circle,
                  shadows: AppShadows.floating,
                ),
                child: const Icon(
                  AppIcons.aiChat,
                  size: 58,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Nami đang ở đây cùng bạn',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Bạn cứ kể cho Nami nghe điều mình đang quan tâm. Nami sẽ nhẹ nhàng gợi ý để bạn chăm sóc sức khỏe, bữa ăn, giấc ngủ và cảm xúc tốt hơn mỗi ngày.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.65,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _CareReminderCard(),
          const SizedBox(height: AppSpacing.xl),
          _SuggestedQuestions(onQuestionTap: onQuestionTap),
        ],
      ),
    );
  }
}

class _CareReminderCard extends StatelessWidget {
  const _CareReminderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecoration.container(
        color: AppColors.surface.withValues(alpha: 0.88),
        radius: AppRadius.lg,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        shadows: AppShadows.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: AppDecoration.base(
              gradient: AppGradients.primary,
              shape: BoxShape.circle,
              shadows: AppShadows.xs,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Một lời nhắn nhỏ: Nami có thể đồng hành và gợi ý, còn những vấn đề sức khỏe nghiêm trọng bạn vẫn nên hỏi bác sĩ nhé.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationWarmNote extends StatelessWidget {
  const _ConversationWarmNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: AppDecoration.container(
          color: AppColors.surface.withValues(alpha: 0.82),
          radius: AppRadius.lg,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            const _NamiAvatar(size: 36, iconSize: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Nami sẽ đọc thật kỹ từng chia sẻ của bạn và trả lời bằng cách dễ hiểu nhất.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSend;

  const _InputArea({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.94),
            border: Border(
              top: BorderSide(color: AppColors.border.withValues(alpha: 0.45)),
            ),
            boxShadow: AppShadows.sm,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 124),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: AppDecoration.input(
                          borderColor: focusNode.hasFocus
                              ? AppColors.primary.withValues(alpha: 0.42)
                              : AppColors.border.withValues(alpha: 0.55),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.sm,
                                bottom: 2,
                              ),
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                color: AppColors.primary.withValues(alpha: 0.8),
                                size: 20,
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: controller,
                                focusNode: focusNode,
                                maxLines: null,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.textPrimary,
                                  height: 1.45,
                                ),
                                enabled: !isLoading,
                                decoration: InputDecoration(
                                  hintText:
                                      'Nhắn cho Nami điều bạn đang quan tâm...',
                                  hintStyle: AppTextStyles.inputHint.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onSubmitted: (_) => onSend(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Semantics(
                      label: 'Gửi tin nhắn cho Nami',
                      button: true,
                      child: GestureDetector(
                        onTap: isLoading ? null : onSend,
                        child: AnimatedContainer(
                          duration: AppDuration.fast,
                          curve: Curves.easeOutCubic,
                          width: 50,
                          height: 50,
                          decoration: isLoading
                              ? AppDecoration.container(
                                  color: AppColors.disabled,
                                  radius: AppRadius.circular,
                                )
                              : AppDecoration.primaryGradient(
                                  radius: AppRadius.circular,
                                ),
                          child: AnimatedSwitcher(
                            duration: AppDuration.fast,
                            child: isLoading
                                ? const SizedBox(
                                    key: ValueKey('loading-send'),
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    key: ValueKey('ready-send'),
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Nami sẽ luôn trả lời nhẹ nhàng, không phán xét và dễ hiểu nhất có thể.',
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
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageEntity message;
  final bool isUser;

  const _MessageBubble({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: AppSpacing.md,
        left: isUser ? AppSpacing.xl : 0,
        right: isUser ? 0 : AppSpacing.xl,
      ),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const _NamiAvatar(size: 38, iconSize: 19),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: AppDuration.normal,
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                decoration: isUser
                    ? AppDecoration.gradient(
                        colors: AppGradients.primary.colors,
                        radius: AppRadius.lg,
                        shadows: AppShadows.sm,
                      )
                    : AppDecoration.container(
                        color: AppColors.surface.withValues(alpha: 0.94),
                        radius: AppRadius.lg,
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.46),
                        ),
                        shadows: AppShadows.xs,
                      ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isUser) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.spa_rounded,
                            color: AppColors.primary,
                            size: 15,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Nami gửi bạn',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                    Text(
                      message.content,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: isUser ? Colors.white : AppColors.textPrimary,
                        height: 1.62,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Text(
                        _formatTime(message.timestamp),
                        style: AppTextStyles.caption.copyWith(
                          color: isUser
                              ? Colors.white.withValues(alpha: 0.72)
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: AppSpacing.sm),
            const _UserAvatar(),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
      duration: const Duration(milliseconds: 1200),
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
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _NamiAvatar(size: 38, iconSize: 19),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: AppDecoration.container(
              color: AppColors.surface.withValues(alpha: 0.94),
              radius: AppRadius.lg,
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.42),
              ),
              shadows: AppShadows.xs,
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Nami đang đọc thật kỹ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ...List.generate(3, (index) {
                      final delay = index * 0.2;
                      final value = (_controller.value - delay).clamp(0.0, 1.0);
                      final scale = (1 - (value - 0.5).abs() * 2).clamp(
                        0.45,
                        1.0,
                      );

                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(
                              alpha: 0.35 + scale * 0.55,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestedQuestions extends StatelessWidget {
  final ValueChanged<String> onQuestionTap;

  const _SuggestedQuestions({required this.onQuestionTap});

  static const _questions = [
    _NamiSuggestion(
      icon: Icons.bedtime_rounded,
      title: 'Giấc ngủ',
      question: 'Nami ơi, làm sao để mình ngủ sâu hơn?',
      subtitle: 'Nhẹ nhàng chăm lại nhịp nghỉ ngơi',
    ),
    _NamiSuggestion(
      icon: Icons.restaurant_rounded,
      title: 'Bữa ăn',
      question: 'Bữa sáng hôm nay mình nên ăn gì?',
      subtitle: 'Gợi ý món dễ ăn, đủ năng lượng',
    ),
    _NamiSuggestion(
      icon: Icons.self_improvement_rounded,
      title: 'Căng thẳng',
      question: 'Mình đang hơi căng thẳng, Nami giúp mình với.',
      subtitle: 'Một vài cách thở và thả lỏng',
    ),
    _NamiSuggestion(
      icon: Icons.water_drop_rounded,
      title: 'Uống nước',
      question: 'Mỗi ngày mình nên uống bao nhiêu nước?',
      subtitle: 'Nhắc nhẹ để cơ thể dễ chịu hơn',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nami gợi ý vài điều nhỏ',
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Chạm vào một câu hỏi nếu bạn chưa biết bắt đầu từ đâu.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Column(
          children: _questions.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _SuggestionCard(
                item: item,
                onTap: () => onQuestionTap(item.question),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final _NamiSuggestion item;
  final VoidCallback onTap;

  const _SuggestionCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: AppDecoration.container(
            color: AppColors.surface.withValues(alpha: 0.9),
            radius: AppRadius.lg,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
            shadows: AppShadows.xs,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: AppDecoration.container(
                  color: AppColors.primary.withValues(alpha: 0.09),
                  radius: AppRadius.circular,
                ),
                child: Icon(item.icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.subtitle,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textMuted,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NamiSuggestion {
  final IconData icon;
  final String title;
  final String question;
  final String subtitle;

  const _NamiSuggestion({
    required this.icon,
    required this.title,
    required this.question,
    required this.subtitle,
  });
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  const _GlassIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: AppDecoration.glass(
            opacity: 0.9,
            radius: AppRadius.circular,
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
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
        boxShadow: AppShadows.xs,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Container(
          margin: const EdgeInsets.all(3),
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

class _UserAvatar extends StatelessWidget {
  const _UserAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: AppDecoration.base(
        gradient: AppGradients.primary,
        shape: BoxShape.circle,
        shadows: AppShadows.xs,
      ),
      child: const Icon(AppIcons.profile, color: Colors.white, size: 19),
    );
  }
}

class _AnimatedBackground extends StatelessWidget {
  final AnimationController backgroundController;
  final AnimationController pulseController;

  const _AnimatedBackground({
    required this.backgroundController,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([backgroundController, pulseController]),
      builder: (context, child) {
        final pulse = pulseController.value;

        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.background,
                    AppColors.primary.withValues(alpha: 0.08),
                    AppColors.secondary.withValues(alpha: 0.06),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -120 + (pulse * 12),
              right: -90,
              child: _SoftOrb(
                size: 260,
                color: AppColors.primary,
                opacity: 0.12 + pulse * 0.05,
              ),
            ),
            Positioned(
              top: 210,
              left: -120 + (pulse * 10),
              child: _SoftOrb(
                size: 220,
                color: AppColors.secondary,
                opacity: 0.1,
              ),
            ),
            Positioned(
              bottom: -130,
              right: -80 + (pulse * 10),
              child: _SoftOrb(
                size: 250,
                color: AppColors.primary,
                opacity: 0.08,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _CalmGridPainter(
                    progress: backgroundController.value,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SoftOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _SoftOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: opacity * 0.35),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _CalmGridPainter extends CustomPainter {
  final double progress;

  const _CalmGridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.025)
      ..strokeWidth = 1;

    const gap = 34.0;
    final offset = progress * gap;

    for (double x = -gap + offset; x < size.width + gap; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = -gap + offset; y < size.height + gap; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CalmGridPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
