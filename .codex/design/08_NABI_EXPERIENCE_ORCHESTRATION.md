# Nabi Experience Orchestration

## 1. Problem statement

Source hiện có Nabi global và Nabi V1 với route observer, overlay, mascot và renderer riêng. Design mới yêu cầu một owner và một priority policy để tránh hai mascot/animation/sound chạy đồng thời.

## 2. Architecture

```text
route + feature state + user event
  → NabiExperienceOrchestrator
      → priority queue / cooldown / lifecycle
      → NabiVisualState
      → Nabi renderer/animation player
      → AppFeedbackService cue (optional)
```

Renderer không gọi haptic/sound và không biết business repository.

## 3. Priority

1. Critical health/system state.
2. Active user interaction/permission.
3. Voice/AI listening-processing-speaking.
4. Commit success/error.
5. Route greeting/guidance.
6. Ambient idle.

Higher priority được phép interrupt lower priority; celebration không interrupt critical/voice.

## 4. States

`idle`, `notice`, `guide`, `listen`, `think`, `speak`, `celebrate`, `encourage`, `warn`, `recover`, `static`.

## 5. Rules

- Một route chỉ có một Nabi owner.
- Không che primary CTA, keyboard hoặc proof capture.
- Speech bubble tối đa 3 dòng, có dismiss/cooldown.
- Idle animation pause khi offscreen/background.
- Reduced motion dùng static expression.
- Cache first frame và active spritesheet có giới hạn; không precache toàn asset catalog.
- Sound cue do orchestrator yêu cầu thông qua feedback service.

## 6. Route mapping

- Splash/onboarding: welcome/guide/thinking/plan-ready.
- Dashboard: time-based greeting, insight notice, task completion.
- AI Chat/Voice: listen/think/speak/error.
- Meal/schedule: guide/encourage/success.
- Auth/profile: greet/guide/recover.
- Premium/payment: locked/guide/success chỉ sau trusted approval.
- Admin: default no ambient Nabi.
