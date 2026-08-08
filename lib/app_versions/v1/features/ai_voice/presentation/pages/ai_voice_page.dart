import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/domain/entities/ai_voice_state.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/presentation/controllers/ai_voice_controller.dart';
import 'package:nano_app/app_versions/v1/features/nabi/providers/nabi_provider.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/features/nabi/nabi.dart';

class AiVoicePage extends ConsumerStatefulWidget {
  const AiVoicePage({super.key});

  @override
  ConsumerState<AiVoicePage> createState() => _AiVoicePageState();
}

class _AiVoicePageState extends ConsumerState<AiVoicePage>
    with WidgetsBindingObserver {
  late final NabiContextNotifier _nabi;
  late final AiVoiceController _voiceController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _nabi = ref.read(nabiContextProvider.notifier);
    _voiceController = ref.read(aiVoiceControllerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _nabi.setRoute(V1RoutePaths.aiVoice);
      _voiceController.initializeAndGreet();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _voiceController.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _voiceController.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiVoiceControllerProvider);
    final controller = ref.read(aiVoiceControllerProvider.notifier);

    ref.listen<AiVoiceState>(aiVoiceControllerProvider, (previous, next) {
      if (previous?.phase == next.phase) return;

      switch (next.phase) {
        case AiVoicePhase.listening:
          AppFeedbackService.instance.emit(AppFeedbackType.voiceStart);
          break;
        case AiVoicePhase.idle:
          if (previous?.phase == AiVoicePhase.listening ||
              previous?.phase == AiVoicePhase.speaking) {
            AppFeedbackService.instance.emit(AppFeedbackType.voiceStop);
          }
          break;
        case AiVoicePhase.speaking:
          if (next.response.isNotEmpty) {
            AppFeedbackService.instance.emit(AppFeedbackType.answerReady);
          }
          break;
        case AiVoicePhase.permissionDenied:
          AppFeedbackService.instance.emit(AppFeedbackType.warning);
          break;
        case AiVoicePhase.error:
          AppFeedbackService.instance.emit(AppFeedbackType.error);
          break;
        case AiVoicePhase.initializing:
        case AiVoicePhase.greeting:
        case AiVoicePhase.transcribing:
        case AiVoicePhase.thinking:
          break;
      }
    });

    final canTapMic = !state.isBusy || state.phase == AiVoicePhase.listening;
    final isListening = state.phase == AiVoicePhase.listening;

    return MedicalPageScaffold(
      backgroundColor: context.semanticColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: context.semanticColors.background,
        title: const Text('Trò chuyện bằng giọng nói'),
        actions: [
          IconButton(
            tooltip: state.isMuted ? 'Bật giọng NaBi' : 'Tắt giọng NaBi',
            onPressed: controller.toggleMuted,
            icon: Icon(
              state.isMuted
                  ? Icons.volume_off_rounded
                  : Icons.volume_up_rounded,
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: AppViewMotion(
                child: Column(
                  children: [
                    _NabiVoiceHero(phase: state.phase),
                    const SizedBox(height: AppSpacing.sectionSpacing),
                    Text(
                      _statusText(state.phase),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading3.copyWith(
                        color: context.semanticColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Chạm micro và nói một câu ngắn.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.semanticColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sectionSpacing),
                    AppStateSwitcher(
                      child: state.transcript.isEmpty
                          ? const SizedBox.shrink(
                              key: ValueKey('no-transcript'),
                            )
                          : Column(
                              key: const ValueKey('transcript'),
                              children: [
                                _VoiceMessageCard(
                                  title: 'Bạn vừa hỏi',
                                  content: state.transcript,
                                  icon: Icons.person_outline_rounded,
                                ),
                                const SizedBox(height: AppSpacing.md),
                              ],
                            ),
                    ),
                    AppStateSwitcher(
                      child: state.response.isEmpty
                          ? const SizedBox.shrink(key: ValueKey('no-response'))
                          : _VoiceMessageCard(
                              key: ValueKey(state.response),
                              title: 'NaBi trả lời',
                              content: state.response,
                              icon: Icons.favorite_outline_rounded,
                              trailing: state.isMuted
                                  ? null
                                  : IconButton(
                                      tooltip: 'Nghe lại',
                                      onPressed: state.isBusy
                                          ? null
                                          : controller.replayResponse,
                                      icon: const Icon(Icons.replay_rounded),
                                    ),
                            ),
                    ),
                    AppStateSwitcher(
                      child: state.errorMessage == null
                          ? const SizedBox.shrink(key: ValueKey('no-error'))
                          : Padding(
                              key: ValueKey(state.errorMessage),
                              padding: const EdgeInsets.only(
                                top: AppSpacing.md,
                              ),
                              child: _VoiceError(message: state.errorMessage!),
                            ),
                    ),
                    const SizedBox(height: AppSpacing.sectionSpacing),
                    AppPressScale(
                      enabled: canTapMic,
                      pressedScale: .965,
                      child: Semantics(
                        button: true,
                        enabled: canTapMic,
                        label: isListening
                            ? 'Dừng nghe'
                            : 'Bắt đầu nói với NaBi',
                        child: InkWell(
                          onTap: isListening
                              ? controller.stop
                              : state.isBusy
                              ? null
                              : controller.listenAndRespond,
                          customBorder: const CircleBorder(),
                          child: AnimatedContainer(
                            duration: AppMotionScope.duration(
                              context,
                              AppDuration.normal,
                            ),
                            curve: AppAnimations.emphasizedCurve,
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isListening
                                  ? AppColors.error
                                  : AppColors.primary,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (isListening
                                              ? AppColors.error
                                              : AppColors.primary)
                                          .withValues(alpha: .22),
                                  blurRadius: state.isBusy ? 18 : 10,
                                  spreadRadius: state.isBusy ? 2 : 0,
                                ),
                              ],
                            ),
                            child: AnimatedSwitcher(
                              duration: AppMotionScope.duration(
                                context,
                                AppDuration.fast,
                              ),
                              child: Icon(
                                isListening
                                    ? Icons.stop_rounded
                                    : Icons.mic_rounded,
                                key: ValueKey(isListening),
                                color: AppColors.surface,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        TextButton.icon(
                          onPressed: state.isBusy ? controller.stop : null,
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Dừng'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.go(V1RoutePaths.aiChat),
                          icon: const Icon(Icons.keyboard_alt_outlined),
                          label: const Text('Nhập chữ'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sectionSpacing),
                    Text(
                      'Không đọc mật khẩu, thông tin tài chính hoặc dữ liệu quá nhạy cảm bằng giọng nói.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.semanticColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NabiVoiceHero extends StatelessWidget {
  final AiVoicePhase phase;

  const _NabiVoiceHero({required this.phase});

  @override
  Widget build(BuildContext context) {
    return AppStateSwitcher(
      duration: AppDuration.normal,
      child: NabiAnimationPlayer(
        key: ValueKey(phase),
        animationType: _animationFor(phase),
        size: 132,
        fallbackIcon: const Icon(
          Icons.health_and_safety_rounded,
          size: 80,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

NabiAnimationType _animationFor(AiVoicePhase phase) {
  return switch (phase) {
    AiVoicePhase.initializing => NabiAnimationType.loading,
    AiVoicePhase.greeting => NabiAnimationType.greeting,
    AiVoicePhase.listening => NabiAnimationType.listening,
    AiVoicePhase.transcribing ||
    AiVoicePhase.thinking => NabiAnimationType.thinking,
    AiVoicePhase.speaking => NabiAnimationType.talking,
    AiVoicePhase.error => NabiAnimationType.error,
    AiVoicePhase.permissionDenied => NabiAnimationType.reminder,
    AiVoicePhase.idle => NabiAnimationType.idle,
  };
}

class _VoiceMessageCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Widget? trailing;

  const _VoiceMessageCard({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: context.semanticColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.semanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: context.semanticColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            content,
            style: AppTextStyles.bodyLarge.copyWith(
              color: context.semanticColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceError extends StatelessWidget {
  final String message;

  const _VoiceError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

String _statusText(AiVoicePhase phase) {
  return switch (phase) {
    AiVoicePhase.initializing => 'NaBi đang chuẩn bị…',
    AiVoicePhase.greeting => 'NaBi đang chào bạn',
    AiVoicePhase.listening => 'NaBi đang lắng nghe…',
    AiVoicePhase.transcribing => 'NaBi đang ghi lại câu hỏi…',
    AiVoicePhase.thinking => 'NaBi đang suy nghĩ…',
    AiVoicePhase.speaking => 'NaBi đang trả lời…',
    AiVoicePhase.permissionDenied => 'NaBi chưa có quyền dùng micro',
    AiVoicePhase.error => 'Mình thử lại nhé',
    AiVoicePhase.idle => 'NaBi sẵn sàng nghe bạn',
  };
}
