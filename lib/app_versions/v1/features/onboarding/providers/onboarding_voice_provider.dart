import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/onboarding_voice_runtime.dart';

enum OnboardingVoicePhase {
  idle,
  preparing,
  speaking,
  listening,
  processing,
  manual,
  error,
}

class OnboardingVoiceState {
  const OnboardingVoiceState({
    this.isVoiceMode = false,
    this.phase = OnboardingVoicePhase.idle,
    this.stepIndex,
    this.questionId,
    this.transcript = '',
    this.message,
    this.downloadProgress,
    this.createRequestToken = 0,
    this.remindersFinished = false,
    this.draftQuestionId,
    this.draftText,
  });

  final bool isVoiceMode;
  final OnboardingVoicePhase phase;
  final int? stepIndex;
  final String? questionId;
  final String transcript;
  final String? message;
  final double? downloadProgress;
  final int createRequestToken;
  final bool remindersFinished;
  final String? draftQuestionId;
  final String? draftText;

  OnboardingVoiceState copyWith({
    bool? isVoiceMode,
    OnboardingVoicePhase? phase,
    int? stepIndex,
    bool clearStepIndex = false,
    String? questionId,
    bool clearQuestionId = false,
    String? transcript,
    String? message,
    bool clearMessage = false,
    double? downloadProgress,
    bool clearDownloadProgress = false,
    int? createRequestToken,
    bool? remindersFinished,
    String? draftQuestionId,
    String? draftText,
    bool clearDraft = false,
  }) => OnboardingVoiceState(
    isVoiceMode: isVoiceMode ?? this.isVoiceMode,
    phase: phase ?? this.phase,
    stepIndex: clearStepIndex ? null : stepIndex ?? this.stepIndex,
    questionId: clearQuestionId ? null : questionId ?? this.questionId,
    transcript: transcript ?? this.transcript,
    message: clearMessage ? null : message ?? this.message,
    downloadProgress: clearDownloadProgress
        ? null
        : downloadProgress ?? this.downloadProgress,
    createRequestToken: createRequestToken ?? this.createRequestToken,
    remindersFinished: remindersFinished ?? this.remindersFinished,
    draftQuestionId: clearDraft
        ? null
        : draftQuestionId ?? this.draftQuestionId,
    draftText: clearDraft ? null : draftText ?? this.draftText,
  );
}

final onboardingVoiceRuntimeProvider = Provider<OnboardingVoiceRuntime>((ref) {
  final runtime = OnboardingVoiceRuntime();
  ref.onDispose(() => unawaited(runtime.dispose()));
  return runtime;
});

final onboardingVoiceProvider =
    NotifierProvider<OnboardingVoiceController, OnboardingVoiceState>(
      OnboardingVoiceController.new,
    );

class OnboardingVoiceController extends Notifier<OnboardingVoiceState> {
  @override
  OnboardingVoiceState build() => const OnboardingVoiceState();

  void enterVoiceMode({int? stepIndex, String? questionId}) {
    final sameStep = stepIndex != null && stepIndex == state.stepIndex;
    state = state.copyWith(
      isVoiceMode: true,
      phase: OnboardingVoicePhase.idle,
      stepIndex: stepIndex,
      clearStepIndex: stepIndex == null,
      questionId: questionId ?? (sameStep ? state.questionId : null),
      clearQuestionId: questionId == null && !sameStep,
      transcript: '',
      clearMessage: true,
      clearDownloadProgress: true,
      remindersFinished: sameStep ? state.remindersFinished : false,
      clearDraft: !sameStep,
    );
  }

  void setTouchMode() {
    state = state.copyWith(
      isVoiceMode: false,
      phase: OnboardingVoicePhase.idle,
      clearMessage: true,
    );
    unawaited(ref.read(onboardingVoiceRuntimeProvider).stopAll());
  }

  void syncStep(int stepIndex, {String? questionId}) {
    if (state.stepIndex == stepIndex &&
        (questionId == null || state.questionId == questionId)) {
      return;
    }
    state = state.copyWith(
      stepIndex: stepIndex,
      questionId: questionId,
      clearQuestionId: questionId == null,
      phase: OnboardingVoicePhase.idle,
      transcript: '',
      clearMessage: true,
      remindersFinished: false,
      clearDraft: true,
    );
    unawaited(ref.read(onboardingVoiceRuntimeProvider).stopAll());
  }

  void setQuestion(String questionId) {
    final clearDraft =
        state.draftQuestionId != null && state.draftQuestionId != questionId;
    state = state.copyWith(
      questionId: questionId,
      phase: OnboardingVoicePhase.idle,
      transcript: '',
      clearMessage: true,
      clearDraft: clearDraft,
    );
  }

  void setDraft(String questionId, String value) {
    state = state.copyWith(draftQuestionId: questionId, draftText: value);
  }

  void setPhase(
    OnboardingVoicePhase phase, {
    String? message,
    bool clearMessage = false,
    double? downloadProgress,
    bool clearDownloadProgress = false,
    String? transcript,
  }) {
    state = state.copyWith(
      phase: phase,
      message: message,
      clearMessage: clearMessage,
      downloadProgress: downloadProgress,
      clearDownloadProgress:
          clearDownloadProgress || phase != OnboardingVoicePhase.preparing,
      transcript: transcript,
    );
  }

  void finishMedicationReminders() {
    state = state.copyWith(remindersFinished: true);
  }

  void requestCreatePlan() {
    state = state.copyWith(createRequestToken: state.createRequestToken + 1);
  }
}
