# Splash và onboarding

## Goal

Dẫn dắt người dùng theo không gian liên tục, giảm chữ, tăng phản hồi lựa chọn và giữ khả năng quay lại.

## Current evidence

- Files: **22**.
- Page/screen: **4**.
- Files có motion: **10**.
- Files dùng duration raw: **6**.
- Files dùng color trực tiếp: **9**.
- Files gọi haptic trực tiếp: **3**.

## Group design rules

- Step transition theo hướng và stable state; hardware Back không replay.
- Mỗi bước một câu hỏi chính; progressive disclosure.
- Selection feedback có haptic; sound chỉ welcome/plan ready.
- Nabi theo priority và không che CTA/keyboard.

## Views

| View | Entrance | State transition | Feedback | Design intent |
| --- | --- | --- | --- | --- |
| lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_entry_page.dart | Directional fade-slide 12 px; step-aware | Step, selection, validation, review/result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Hero nhập vai với ambient aura nhẹ; CTA có press/sound tinh tế; không tự động replay khi quay lại. |
| lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_page.dart | Directional fade-slide 12 px; step-aware | Step, selection, validation, review/result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Directional step transition dựa trên index; progress morph; giữ state/key để back không reset/replay. |
| lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_text_scale_page.dart | Directional fade-slide 12 px; step-aware | Step, selection, validation, review/result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Preview typography trực tiếp; thumb/label motion nhỏ; tôn trọng system scale và reduce motion. |
| lib/app_versions/v1/features/splash/presentation/pages/splash_page.dart | Directional fade-slide 12 px; step-aware | Loading/empty/error/ready và action result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Dùng một timeline orchestrator thay nhiều controller rời: atmosphere → logo → Nabi → route; tối đa 1.4 giây, cho phép skip và static fallback. |

## File-by-file design

| File | Kind | Role | Current evidence | Target design | Transition contract | Wave |
| --- | --- | --- | --- | --- | --- | --- |
| lib/app_versions/v1/features/onboarding/presentation/constants/onboarding_options.dart | presentation_support | OnboardingOptions | Chưa có motion/feedback đáng kể | Giữ logic thuần; bổ sung semantic presentation metadata hoặc stable identity chỉ khi cần cho transition; không chứa animation, sound hay BuildContext. | Stable state/identity contract | W3 Splash/Onboarding |
| lib/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart | controller | OnboardingState / OnboardingController | Chưa có motion/feedback đáng kể | Giữ nguyên nghiệp vụ; chuẩn hóa UI phase/state identity; loại bỏ haptic trực tiếp khỏi controller và phát feedback sau khi state thành công/thất bại được xác nhận. | Stable state/identity contract | W3 Splash/Onboarding |
| lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_entry_page.dart | page | OnboardingEntryPage / _BrandBar / _GreenHero / _HeroOrb | Nabi×22 | Hero nhập vai với ambient aura nhẹ; CTA có press/sound tinh tế; không tự động replay khi quay lại. | Step, selection, validation, review/result | W3 Splash/Onboarding |
| lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_page.dart | page | OnboardingPage / _OnboardingPageState | AnimatedSwitcher×1, duration raw×2, Colors.*×1, Nabi×1 | Directional step transition dựa trên index; progress morph; giữ state/key để back không reset/replay. | Step, selection, validation, review/result | W3 Splash/Onboarding |
| lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_text_scale_page.dart | page | OnboardingTextScaleGate / OnboardingTextScalePage | Nabi×9 | Preview typography trực tiếp; thumb/label motion nhỏ; tôn trọng system scale và reduce motion. | Step, selection, validation, review/result | W3 Splash/Onboarding |
| lib/app_versions/v1/features/onboarding/presentation/widgets/basic_info_step.dart | widget | BasicInfoStep / _ResponsivePair / _BirthYearField / _BmiInsight | Nabi×16 | Áp dụng directional reveal, stable selection identity, shared progress và Nabi context; feedback chỉ sau state hợp lệ. | Step, selection, validation, review/result | W3 Splash/Onboarding |
| lib/app_versions/v1/features/onboarding/presentation/widgets/conditions_step.dart | widget | ConditionsStep / _ConditionsStepState | Nabi×9 | Áp dụng directional reveal, stable selection identity, shared progress và Nabi context; feedback chỉ sau state hợp lệ. | Step, selection, validation, review/result | W3 Splash/Onboarding |
| lib/app_versions/v1/features/onboarding/presentation/widgets/consent_step.dart | widget | ConsentStep / _ConsentCard | AnimatedContainer×2, AnimatedSwitcher×1, haptic trực tiếp×1, duration raw×1, Colors.*×1, motion token×2, Semantics×1, Nabi×17 | Áp dụng directional reveal, stable selection identity, shared progress và Nabi context; feedback chỉ sau state hợp lệ. | Step, selection, validation, review/result | W3 Splash/Onboarding |
| lib/app_versions/v1/features/onboarding/presentation/widgets/daily_routine_step.dart | widget | DailyRoutineStep / _RoutineTimelinePreview | Nabi×11 | Áp dụng directional reveal, stable selection identity, shared progress và Nabi context; feedback chỉ sau state hợp lệ. | Step, selection, validation, review/result | W3 Splash/Onboarding |
| lib/app_versions/v1/features/onboarding/presentation/widgets/extras_step.dart | widget | ExtrasStep | Nabi×6 | Áp dụng directional reveal, stable selection identity, shared progress và Nabi context; feedback chỉ sau state hợp lệ. | Step, selection, validation, review/result | W3 Splash/Onboarding |
| lib/app_versions/v1/features/onboarding/presentation/widgets/goals_step.dart | widget | GoalsStep | Nabi×6 | Áp dụng directional reveal, stable selection identity, shared progress và Nabi context; feedback chỉ sau state hợp lệ. | Step, selection, validation, review/result | W3 Splash/Onboarding |
| lib/app_versions/v1/features/onboarding/presentation/widgets/health_chip.dart | widget | HealthChip | AnimatedContainer×1, Colors.*×1, motion token×1, Semantics×1, Nabi×5 | Áp dụng directional reveal, stable selection identity, shared progress và Nabi context; feedback chỉ sau state hợp lệ. | Step, selection, validation, review/result | W3 Splash/Onboarding |
| lib/app_versions/v1/features/onboarding/presentation/widgets/lifestyle_step.dart | widget | LifestyleStep / _LifestylePicker | Nabi×9 | Áp dụng directional reveal, stable selection identity, shared progress và Nabi context; feedback chỉ sau state hợp lệ. | Step, selection, validation, review/result | W3 Splash/Onboarding |
| lib/app_versions/v1/features/onboarding/presentation/widgets/nabi_onboarding_experience.dart | widget | NabiPalette / NabiAmbientBackground / _NabiAmbientBackgroundState / _WellnessAtmospherePainter | controller×6, AnimatedContainer×1, AnimatedSwitcher×1, AnimatedScale×1, haptic trực tiếp×1, duration raw×2, Colors.*×2, motion token×3, Semantics×2, Nabi×92 | Orchestrate Nabi theo bước với priority/cooldown; không chạy cùng lúc ambient + celebration + speech. | Step, selection, validation, review/result | W3 Splash/Onboarding |
| lib/app_versions/v1/features/onboarding/presentation/widgets/onboarding_chip.dart | widget | OnboardingChip | AnimatedContainer×1, Colors.*×1, motion token×1, Semantics×1, Nabi×5 | Áp dụng directional reveal, stable selection identity, shared progress và Nabi context; feedback chỉ sau state hợp lệ. | Step, selection, validation, review/result | W3 Splash/Onboarding |
| lib/app_versions/v1/features/onboarding/presentation/widgets/onboarding_compact_ui.dart | widget | OnboardingSectionCard / OnboardingChoiceGrid / OnboardingChoiceTile / _OnboardingChoiceTileState | AnimatedContainer×3, AnimatedSwitcher×1, AnimatedScale×1, haptic trực tiếp×3, Colors.*×3, motion token×5, Semantics×2, Nabi×59 | Hợp nhất các chip/input/section helper vào primitives; loại bỏ haptic trực tiếp và duration raw. | Step, selection, validation, review/result | W3 Splash/Onboarding |
| lib/app_versions/v1/features/onboarding/presentation/widgets/onboarding_step_shell.dart | widget | OnboardingStepShell / _WellnessTopBar / _LeafProgress / _StepBody | AnimatedContainer×1, TweenAnimationBuilder×1, duration raw×1, motion token×2, Nabi×31 | Canonical scaffold cho mọi bước: title/body/action slots, keyboard-safe, shared progress và transition boundary. | Step, selection, validation, review/result | W3 Splash/Onboarding |
| lib/app_versions/v1/features/onboarding/presentation/widgets/onboarding_text_field.dart | widget | OnboardingTextField / _OnboardingTextFieldState | AnimatedContainer×1, motion token×2, Nabi×12 | Áp dụng directional reveal, stable selection identity, shared progress và Nabi context; feedback chỉ sau state hợp lệ. | Step, selection, validation, review/result | W3 Splash/Onboarding |
| lib/app_versions/v1/features/onboarding/presentation/widgets/result_step.dart | widget | ResultStep / _ScoreRing | TweenAnimationBuilder×1, duration raw×1, Colors.*×1, Nabi×14 | Plan generation state machine: preparing → generating → persisted → ready/error; success chime chỉ sau persistence thành công. | Step, selection, validation, review/result | W3 Splash/Onboarding |
| lib/app_versions/v1/features/onboarding/presentation/widgets/review_step.dart | widget | ReviewStep / _ReadinessHero / _SummarySection / _StatusCard | Colors.*×1, Nabi×26 | Áp dụng directional reveal, stable selection identity, shared progress và Nabi context; feedback chỉ sau state hợp lệ. | Step, selection, validation, review/result | W3 Splash/Onboarding |
| lib/app_versions/v1/features/onboarding/presentation/widgets/welcome_step.dart | widget | WelcomeStep / _WelcomeBenefit | Nabi×10 | Áp dụng directional reveal, stable selection identity, shared progress và Nabi context; feedback chỉ sau state hợp lệ. | Step, selection, validation, review/result | W3 Splash/Onboarding |
| lib/app_versions/v1/features/splash/presentation/pages/splash_page.dart | page | SplashPage / _SplashPageState / _SplashLayout / _SplashAtmosphere | controller×17, AnimatedContainer×3, duration raw×2, Colors.*×2, motion token×5, Semantics×3, Nabi×46 | Dùng một timeline orchestrator thay nhiều controller rời: atmosphere → logo → Nabi → route; tối đa 1.4 giây, cho phép skip và static fallback. | Loading/empty/error/ready và action result | W3 Splash/Onboarding |

## Acceptance

- Không raw sound/haptic call ngoài feedback service.
- Không motion replay khi state không đổi.
- Có reduced-motion behavior.
- Có loading/empty/error/ready hoặc lý do không áp dụng.
- Targeted widget/route/state test được bổ sung trong coding wave.
