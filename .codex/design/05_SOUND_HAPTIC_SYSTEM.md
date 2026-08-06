# Sound and Haptic System

## 1. Current evidence

- Source hiện có gọi `HapticFeedback` trực tiếp ở nhiều widget/controller.
- Không có audio playback package hoặc `AppFeedbackService` trong source audit.
- `pubspec.yaml` khai báo `assets/nabi/04_audio/sfx/`, nhưng snapshot được cung cấp không chứa file audio vật lý. Đây là blocker trước khi coding sound.

## 2. Canonical architecture

```text
UI interaction
  → AppFeedbackService.emit(type, context)
      → policy (user setting/system/lifecycle/cooldown)
      → haptic adapter
      → sound adapter
      → no-op/test adapter
```

### Dự kiến file

- `lib/core/feedback/app_feedback_service.dart`
- `lib/core/feedback/app_feedback_type.dart`
- `lib/core/feedback/app_feedback_policy.dart`
- `lib/core/feedback/app_haptic_adapter.dart`
- `lib/core/feedback/app_sound_adapter.dart`
- `lib/core/feedback/providers/app_feedback_provider.dart`

Widget, controller, repository và animation player không được gọi audio package trực tiếp.

## 3. Feedback types

| Type | Haptic | Sound | Condition |
|---|---|---|---|
| `selection` | selection click | optional tick | Selected value thật sự đổi |
| `action` | light | none/subtle tap | Primary action accepted |
| `commitSuccess` | medium/success | soft success | Persistence/RPC succeeded |
| `commitError` | warning/light | soft error | User-action failure |
| `voiceStart` | light | start cue | Microphone started |
| `voiceStop` | selection | stop cue | Listening stopped |
| `answerReady` | none | answer cue | AI message inserted |
| `planReady` | success | short chime | Plan persisted + reminders scheduled |
| `milestone` | success | celebration chime | Unique milestone event |
| `criticalAlert` | warning | alert cue | Critical state, cooldown enforced |

## 4. Sound policy

- Modes: `off`, `subtle`, `full`.
- Default User: `subtle`; Admin: `off`.
- Generic tap không sound.
- Tôn trọng silent/accessibility policy theo quyết định platform.
- Không phát sound khi app background.
- Stop/dispose player theo lifecycle.
- Preload chỉ 3–5 cue ngắn phổ biến.
- Mỗi asset nên < 1 giây, loudness đồng đều, không có bass/treble gây giật mình.

## 5. Asset naming proposal

```text
assets/audio/ui/
  ui_selection_tick.wav
  ui_action_soft.wav
  ui_success_soft.wav
  ui_error_soft.wav
  voice_listen_start.wav
  voice_listen_stop.wav
  ai_answer_ready.wav
  plan_ready_chime.wav
  milestone_chime.wav
  critical_alert_soft.wav
```

Không coding mapping cuối cho đến khi asset thật, license và platform playback được xác minh.

## 6. Settings

Settings cần có:

- Hiệu ứng chuyển động: Đầy đủ / Giảm / Theo hệ thống.
- Phản hồi rung: Bật/Tắt.
- Âm thanh giao diện: Tắt / Tinh tế / Đầy đủ.
- Nabi animation: Đầy đủ / Tối giản / Tĩnh.

## 7. Test

- Fake feedback adapter ghi event.
- Không cue khi state không đổi.
- Không success trước commit.
- Cooldown/dedup theo event ID.
- Sound off và reduced mode.
- Lifecycle background no-play.
