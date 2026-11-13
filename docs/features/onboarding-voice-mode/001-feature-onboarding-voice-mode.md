# Feature: Voice guided onboarding

**Commit proposal:** `feat(onboarding): add local voice guided onboarding`  
**Date:** 2026-11-13  
**Module:** M01 `ONBOARDING_PROFILE`  
**Status:** Implemented in source; Android/iOS device and browser acceptance pending.

## Goal

Offer a voice guided path through the existing onboarding, including the text
size setup. Nabi asks one question at a time, reads short choices, and listens
for an answer. Touch input remains available throughout the flow.

## User flow

1. On supported Android and iOS devices, the entry page offers voice mode next
   to the existing touch CTA. Touch remains the default.
2. Before the onboarding questions, voice mode asks the user to choose a text
   size. The user can answer by voice or tap a size on screen.
3. Nabi asks the existing onboarding fields in sequence and writes answers to
   the current `OnboardingController`. Small choice lists can be answered by
   label or position. Long catalogs remain visible for manual selection.
4. Daily routine asks each weekday and weekend time separately, including
   meals, sleep, naps, workouts and optional busy intervals.
5. Nabi reads the consent summary, but the user must tap the agreement control.
6. Nabi reads a short review and accepts “Tạo lộ trình” as a command that calls
   the existing save and plan generation flow.

## Privacy and platform boundary

- Speech recognition uses the already bundled `flutter_whisper_ggml` tiny
  quantized Vietnamese model. Its cache is shared with the existing ESP voice
  feature, so the model is downloaded once per app installation.
- The `record` stream is mono 16 kHz PCM held in memory and passed to Whisper;
  onboarding does not write a recording file or send audio/transcripts to an
  API. The transient answer is applied to the same onboarding state as touch
  input.
- First voice use can request microphone permission and download the roughly
  31 MB model. Missing permission, model, or Vietnamese TTS leaves the user on
  a screen with touch input and a mode switch.
- Android/iOS use the device model and installed Vietnamese TTS voice.
- Web uses the local Whisper WebAssembly worker only in a secure,
  cross-origin isolated page. If browser isolation, microphone, model download,
  or recognition is unavailable, the existing touch and text controls remain
  available. Web onboarding does not use TTS, so its visible question is the
  prompt.
- No database, API, payload, controller business rule, or persistence contract
  changes are introduced.

## Existing data fields covered

- Basic information: name, gender, birth year, occupation, height and weight.
- Health goals and conditions, including their existing free text fields.
- Habit, sleep, activity and water choices.
- Allergies, allergy note, treatments, medication/supplement choices, optional
  reminder schedules, treatment note and areas of interest.
- Weekday/weekend wake, five meal times, sleep, optional nap range, two workout
  ranges and optional busy range.
- Consent and review use the existing agreement and submission controls.

## Implementation

- `OnboardingVoiceRuntime` streams PCM to local Whisper and speaks with the
  device's installed Vietnamese TTS voice.
- `OnboardingVoiceController` keeps mode, current question, temporary input,
  recording status and model progress in session state only.
- `OnboardingVoiceQuestions` defines prompts, short/manual choices and
  deterministic parsing for numbers, times and spoken choice labels.
- `OnboardingVoiceStep` applies accepted answers through existing controller
  methods. If speech is unclear, Nabi repeats once and provides retry, typing,
  tapping, and touch mode controls.
- Consent agreement remains an explicit touch action. Review voice submission
  increments a local event consumed by the existing `ReviewStep` submit path.

## Verification

- Targeted `dart analyze` on touched onboarding runtime/UI files: PASS.
- Targeted `dart format` on touched Dart files: PASS.
- Automated tests were not run in this implementation turn.
- Android microphone/model/TTS acceptance, iOS microphone/model/TTS acceptance,
  browser microphone/model acceptance, and visual device smoke remain pending;
  static analysis does not verify runtime audio behavior.

## Related screens and worklog

- Screen specs: `v1-05-onboarding-entry`, `v1-06-onboarding-journey-shell`,
  `onb-01` through `onb-10`.
- Worklog: `docs/worklog/2026-11-13/006-worklog-onboarding-voice-mode.md`.
