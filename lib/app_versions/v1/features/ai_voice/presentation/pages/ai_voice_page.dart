import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/domain/entities/ai_voice_state.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/presentation/controllers/ai_voice_controller.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/providers/ai_voice_providers.dart';
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
      _voiceController.initialize();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(_voiceController.handleAppLifecycleState(state));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_voiceController.stopConversation());
    super.dispose();
  }

  Future<void> _onPrimaryAction(AiVoiceState state) async {
    if (state.isSessionActive) {
      await _voiceController.toggleListening();
      return;
    }
    await _voiceController.startConversation();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiVoiceControllerProvider);
    final controller = ref.read(aiVoiceControllerProvider.notifier);
    final sessionActive = state.isSessionActive;
    final sessionInProgress = state.isSessionInProgress;
    final listening = state.isListening && !state.isListeningPaused;
    final primaryLabel = state.phase == AiVoicePhase.connecting
        ? 'Đang kết nối…'
        : sessionActive
        ? state.isListeningPaused
              ? 'Tiếp tục nghe'
              : 'Tạm dừng micro'
        : 'Bắt đầu trò chuyện';

    return MedicalPageScaffold(
      backgroundColor: context.semanticColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: context.semanticColors.background,
        title: const Text('Trò chuyện bằng giọng nói'),
        actions: [
          IconButton(
            tooltip: state.isMuted ? 'Bật giọng Nabi' : 'Tắt giọng Nabi',
            onPressed: sessionActive
                ? () => controller.setMuted(!state.isMuted)
                : null,
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
              child: Column(
                children: [
                  _NabiVoiceHero(phase: state.phase),
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  Text(
                    _statusText(state),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading3.copyWith(
                      color: context.semanticColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    sessionInProgress
                        ? 'Micro luôn sẵn sàng. Bạn có thể nói chen Nabi bất cứ lúc nào.'
                        : 'Chỉ mở micro sau khi bạn nhấn Bắt đầu.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.semanticColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  if (state.transcript.isNotEmpty) ...[
                    _VoiceMessageCard(
                      title: state.hasSpeechStarted
                          ? 'Bạn đang nói'
                          : 'Bạn vừa nói',
                      content: state.transcript,
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (state.responseDraft.isNotEmpty)
                    _VoiceMessageCard(
                      title: 'Nabi trả lời',
                      content: state.responseDraft,
                      icon: Icons.favorite_outline_rounded,
                    ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _VoiceError(message: state.errorMessage!),
                  ],
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  AppPressScale(
                    enabled: state.phase != AiVoicePhase.connecting,
                    pressedScale: .965,
                    child: Semantics(
                      button: true,
                      label: primaryLabel,
                      child: InkWell(
                        onTap: state.phase == AiVoicePhase.connecting
                            ? null
                            : () => _onPrimaryAction(state),
                        customBorder: const CircleBorder(),
                        child: AnimatedContainer(
                          duration: AppMotionScope.duration(
                            context,
                            AppDuration.normal,
                          ),
                          curve: AppAnimations.emphasizedCurve,
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: sessionActive && listening
                                ? AppColors.error
                                : AppColors.primary,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (sessionActive && listening
                                            ? AppColors.error
                                            : AppColors.primary)
                                        .withValues(alpha: .22),
                                blurRadius: 16,
                                spreadRadius: sessionActive ? 2 : 0,
                              ),
                            ],
                          ),
                          child: Icon(
                            sessionActive && listening
                                ? Icons.pause_rounded
                                : Icons.mic_rounded,
                            color: AppColors.surface,
                            size: 34,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    primaryLabel,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: context.semanticColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      TextButton.icon(
                        onPressed: sessionInProgress
                            ? controller.stopConversation
                            : null,
                        icon: const Icon(Icons.stop_circle_outlined),
                        label: const Text('Dừng phiên'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.push(V1RoutePaths.aiChat),
                        icon: const Icon(Icons.keyboard_alt_outlined),
                        label: const Text('Nhập chữ'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  Text(
                    'Nabi dùng phát hiện giọng nói tự động. Khi bạn nói chen, âm thanh Nabi đang chờ phát sẽ bị xóa ngay.',
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
    );
  }
}

class _NabiVoiceHero extends StatelessWidget {
  const _NabiVoiceHero({required this.phase});

  final AiVoicePhase phase;

  @override
  Widget build(BuildContext context) {
    return NabiAnimationPlayer(
      key: ValueKey(phase),
      animationType: _animationFor(phase),
      size: 132,
      fallbackIcon: const Icon(
        Icons.health_and_safety_rounded,
        size: 80,
        color: AppColors.primary,
      ),
    );
  }
}

NabiAnimationType _animationFor(AiVoicePhase phase) {
  return switch (phase) {
    AiVoicePhase.initializing ||
    AiVoicePhase.connecting => NabiAnimationType.loading,
    AiVoicePhase.listening ||
    AiVoicePhase.userSpeaking ||
    AiVoicePhase.interrupted ||
    AiVoicePhase.reconnecting => NabiAnimationType.listening,
    AiVoicePhase.speaking => NabiAnimationType.talking,
    AiVoicePhase.permissionDenied => NabiAnimationType.reminder,
    AiVoicePhase.error => NabiAnimationType.error,
    AiVoicePhase.idle || AiVoicePhase.paused => NabiAnimationType.idle,
    AiVoicePhase.greeting => NabiAnimationType.greeting,
    AiVoicePhase.transcribing ||
    AiVoicePhase.finalizingInput ||
    AiVoicePhase.thinking ||
    AiVoicePhase.waitingFirstToken ||
    AiVoicePhase.streamingResponse ||
    AiVoicePhase.recoveringRecognizer => NabiAnimationType.thinking,
  };
}

class _VoiceMessageCard extends StatelessWidget {
  const _VoiceMessageCard({
    required this.title,
    required this.content,
    required this.icon,
  });

  final String title;
  final String content;
  final IconData icon;

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
              Text(
                title,
                style: AppTextStyles.labelLarge.copyWith(
                  color: context.semanticColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
  const _VoiceError({required this.message});

  final String message;

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

String _statusText(AiVoiceState state) {
  return switch (state.phase) {
    AiVoicePhase.initializing => 'Nabi đang chuẩn bị…',
    AiVoicePhase.idle => 'Nabi sẵn sàng trò chuyện',
    AiVoicePhase.connecting => 'Nabi đang kết nối…',
    AiVoicePhase.listening => 'Nabi đang lắng nghe…',
    AiVoicePhase.userSpeaking => 'Mình đang nghe bạn nói…',
    AiVoicePhase.speaking => 'Nabi đang trả lời — bạn có thể chen lời',
    AiVoicePhase.paused => 'Micro đang tạm dừng',
    AiVoicePhase.reconnecting => 'Nabi đang nối lại…',
    AiVoicePhase.interrupted => 'Nabi đã dừng và đang nghe bạn',
    AiVoicePhase.permissionDenied => 'Nabi chưa có quyền dùng micro',
    AiVoicePhase.error => 'Kết nối vừa gián đoạn',
    AiVoicePhase.greeting => 'Nabi đang chào bạn',
    AiVoicePhase.transcribing ||
    AiVoicePhase.finalizingInput => 'Nabi đang hoàn tất câu hỏi…',
    AiVoicePhase.thinking ||
    AiVoicePhase.waitingFirstToken => 'Nabi đang suy nghĩ…',
    AiVoicePhase.streamingResponse => 'Nabi đang bắt đầu trả lời…',
    AiVoicePhase.recoveringRecognizer => 'Nabi đang nối lại micro…',
  };
}
