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
      unawaited(_voiceController.initialize());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(_voiceController.handleAppLifecycleState(state));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_voiceController.leavePage());
    super.dispose();
  }

  Future<void> _onPrimaryAction(AiVoiceState state) {
    return state.isSessionInProgress
        ? _voiceController.stopConversation()
        : _voiceController.startConversation();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiVoiceControllerProvider);
    final running = state.isSessionInProgress;
    final actionLabel = running ? 'Dừng' : 'Bắt đầu';

    return MedicalPageScaffold(
      backgroundColor: context.semanticColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: context.semanticColors.background,
        title: const Text('Trò chuyện bằng giọng nói'),
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
                    _statusText(state.phase),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading3.copyWith(
                      color: context.semanticColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    running
                        ? 'Nabi sẽ nghe từng câu, suy nghĩ rồi trả lời xong trước khi nghe tiếp.'
                        : 'Micro chỉ mở sau khi bạn nhấn Bắt đầu.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.semanticColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ReactionSpeedSelector(
                    speed: state.reactionSpeed,
                    enabled: !running,
                    onChanged: _voiceController.setReactionSpeed,
                  ),
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  if (state.transcript.isNotEmpty) ...[
                    _VoiceMessageCard(
                      title: 'Bạn vừa nói',
                      content: state.transcript,
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (state.response.isNotEmpty)
                    _VoiceMessageCard(
                      title: 'Nabi trả lời',
                      content: state.response,
                      icon: Icons.favorite_outline_rounded,
                    ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _VoiceError(message: state.errorMessage!),
                  ],
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  AppPressScale(
                    pressedScale: .965,
                    child: Semantics(
                      button: true,
                      label: actionLabel,
                      child: InkWell(
                        key: const Key('ai_voice_primary_action'),
                        onTap: () => _onPrimaryAction(state),
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
                            color: running
                                ? AppColors.error
                                : AppColors.primary,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (running
                                            ? AppColors.error
                                            : AppColors.primary)
                                        .withValues(alpha: .22),
                                blurRadius: 16,
                                spreadRadius: running ? 2 : 0,
                              ),
                            ],
                          ),
                          child: Icon(
                            running ? Icons.stop_rounded : Icons.mic_rounded,
                            color: AppColors.surface,
                            size: 34,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    actionLabel,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: context.semanticColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () => context.push(V1RoutePaths.aiChat),
                    icon: const Icon(Icons.keyboard_alt_outlined),
                    label: const Text('Nhập chữ'),
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

class _ReactionSpeedSelector extends StatelessWidget {
  const _ReactionSpeedSelector({
    required this.speed,
    required this.enabled,
    required this.onChanged,
  });

  final AiVoiceReactionSpeed speed;
  final bool enabled;
  final ValueChanged<AiVoiceReactionSpeed> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<AiVoiceReactionSpeed>(
      key: const Key('ai_voice_reaction_speed'),
      initialValue: speed,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Tốc độ phản ứng',
        helperText: 'Nabi sẽ gửi câu hỏi khi bạn im lặng đủ thời gian đã chọn.',
        prefixIcon: Icon(Icons.speed_rounded),
      ),
      items: AiVoiceReactionSpeed.values
          .map(
            (reactionSpeed) => DropdownMenuItem<AiVoiceReactionSpeed>(
              value: reactionSpeed,
              child: Text(reactionSpeed.label),
            ),
          )
          .toList(growable: false),
      onChanged: enabled
          ? (reactionSpeed) {
              if (reactionSpeed != null) onChanged(reactionSpeed);
            }
          : null,
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
    AiVoicePhase.initializing => NabiAnimationType.loading,
    AiVoicePhase.idle => NabiAnimationType.idle,
    AiVoicePhase.listening => NabiAnimationType.listening,
    AiVoicePhase.thinking => NabiAnimationType.thinking,
    AiVoicePhase.speaking => NabiAnimationType.talking,
    AiVoicePhase.permissionDenied => NabiAnimationType.reminder,
    AiVoicePhase.error => NabiAnimationType.error,
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

String _statusText(AiVoicePhase phase) {
  return switch (phase) {
    AiVoicePhase.initializing => 'Nabi đang chuẩn bị…',
    AiVoicePhase.idle => 'Nabi sẵn sàng trò chuyện',
    AiVoicePhase.listening => 'Nabi đang lắng nghe…',
    AiVoicePhase.thinking => 'Nabi đang suy nghĩ…',
    AiVoicePhase.speaking => 'Nabi đang trả lời…',
    AiVoicePhase.permissionDenied => 'Nabi chưa có quyền dùng micro',
    AiVoicePhase.error => 'Cuộc trò chuyện vừa dừng',
  };
}
