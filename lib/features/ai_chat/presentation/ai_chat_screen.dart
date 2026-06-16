import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../domain/entities/chat_message_entity.dart';
import 'controllers/ai_chat_controller.dart';

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
      duration: const Duration(seconds: 15),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppDuration.normal,
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  void _sendMessage() {
    final message = _textController.text.trim();
    if (message.isEmpty) return;

    ref.read(aiChatControllerProvider.notifier).sendMessage(message);
    _textController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiChatControllerProvider);

    return Scaffold(
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
                  child: state.messages.isEmpty
                      ? _buildEmptyState()
                      : _buildMessageList(state.messages, state.isLoading),
                ),
                _buildInputArea(state.isLoading),
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
      leading: IconButton(
        icon: Container(
          width: 40,
          height: 40,
          decoration: AppDecoration.glass(
            opacity: 0.9,
            radius: AppRadius.circular,
          ),
          child: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: AppDecoration.glass(
          opacity: 0.9,
          radius: AppRadius.circular,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'BioAI Assistant',
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Container(
            width: 40,
            height: 40,
            decoration: AppDecoration.glass(
              opacity: 0.9,
              radius: AppRadius.circular,
            ),
            child: const Icon(Icons.refresh_rounded, color: AppColors.primary),
          ),
          onPressed: () {
            ref.read(aiChatControllerProvider.notifier).clearChat();
          },
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xxxl),

          Container(
            width: 120,
            height: 120,
            decoration: AppDecoration.base(
              gradient: AppGradients.ai,
              shape: BoxShape.circle,
              shadows: AppShadows.floating,
            ),
            child: const Icon(AppIcons.aiChat, size: 60, color: Colors.white),
          ),

          const SizedBox(height: AppSpacing.xl),

          Text(
            'Xin chào! Mình là BioAI',
            style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            'Mình ở đây để lắng nghe và hỗ trợ bạn về sức khỏe, dinh dưỡng và lối sống.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          _SuggestedQuestions(
            onQuestionTap: (question) {
              _textController.text = question;
              _sendMessage();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessageEntity> messages, bool isLoading) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      itemCount: messages.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && isLoading) {
          return const _TypingIndicator();
        }

        final message = messages[index];
        final isUser = message.role == MessageRole.user;

        return _MessageBubble(message: message, isUser: isUser);
      },
    );
  }

  Widget _buildInputArea(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.98),
        border: Border(
          top: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: AppDecoration.input(
                  borderColor: AppColors.border.withOpacity(0.5),
                ),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTextStyles.bodyLarge,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    hintText: 'Nhắn tin cho BioAI...',
                    hintStyle: AppTextStyles.inputHint,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            GestureDetector(
              onTap: isLoading ? null : _sendMessage,
              child: AnimatedContainer(
                duration: AppDuration.fast,
                width: 48,
                height: 48,
                decoration: isLoading
                    ? AppDecoration.container(
                        color: AppColors.disabled,
                        radius: AppRadius.circular,
                      )
                    : AppDecoration.primaryGradient(radius: AppRadius.circular),
                child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ],
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
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(),
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
                    offset: Offset(0, 10 * (1 - value)),
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
                        color: AppColors.surface,
                        radius: AppRadius.lg,
                        border: Border.all(
                          color: AppColors.border.withOpacity(0.5),
                        ),
                      ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.content,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: isUser ? Colors.white : AppColors.textPrimary,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    Text(
                      _formatTime(message.timestamp),
                      style: AppTextStyles.caption.copyWith(
                        color: isUser
                            ? Colors.white.withOpacity(0.7)
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (isUser) ...[const SizedBox(width: AppSpacing.sm), _buildAvatar()],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: AppDecoration.base(
        gradient: isUser ? AppGradients.primary : AppGradients.ai,
        shape: BoxShape.circle,
        shadows: AppShadows.xs,
      ),
      child: Icon(
        isUser ? AppIcons.profile : AppIcons.aiChat,
        color: Colors.white,
        size: 20,
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
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: AppDecoration.base(
              gradient: AppGradients.ai,
              shape: BoxShape.circle,
            ),
            child: const Icon(AppIcons.aiChat, color: Colors.white, size: 20),
          ),

          const SizedBox(width: AppSpacing.sm),

          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: AppDecoration.container(
              color: AppColors.surface,
              radius: AppRadius.lg,
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final delay = index * 0.2;
                    final value = (_controller.value - delay).clamp(0.0, 1.0);
                    final scale = (1 - (value - 0.5).abs() * 2).clamp(0.5, 1.0);

                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.5 + scale * 0.5),
                        shape: BoxShape.circle,
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

class _SuggestedQuestions extends StatelessWidget {
  final Function(String) onQuestionTap;

  const _SuggestedQuestions({required this.onQuestionTap});

  static const _questions = [
    'Làm sao để cải thiện giấc ngủ?',
    'Bữa sáng nên ăn gì?',
    'Cách giảm stress hiệu quả?',
    'Uống bao nhiêu nước mỗi ngày?',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.sm),
          child: Text(
            'Gợi ý câu hỏi:',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _questions.map((question) {
            return GestureDetector(
              onTap: () => onQuestionTap(question),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: AppDecoration.container(
                  color: AppColors.surface,
                  radius: AppRadius.circular,
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.aiChat, size: 16, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      question,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
                ),
              ),
            ),

            Positioned(
              top: -100,
              right: -80,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withOpacity(
                        0.1 + pulseController.value * 0.05,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: -120,
              left: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondary.withOpacity(0.08),
                      Colors.transparent,
                    ],
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
