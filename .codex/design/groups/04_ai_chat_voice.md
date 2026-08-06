# AI Chat và Voice AI

## Goal

Đồng bộ message motion, voice orb, Nabi state, quota/loading/error và sound cue có ý nghĩa.

## Current evidence

- Files: **5**.
- Page/screen: **2**.
- Files có motion: **3**.
- Files dùng duration raw: **2**.
- Files dùng color trực tiếp: **2**.
- Files gọi haptic trực tiếp: **2**.

## Group design rules

- Conversation insert giữ scroll và message identity.
- Voice orb state machine là source visual duy nhất.
- Sound cue semantic, không loop processing.
- Native lifecycle/stale operation token không bị motion che giấu.

## Views

| View | Entrance | State transition | Feedback | Design intent |
| --- | --- | --- | --- | --- |
| lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart | Message/voice state fade-size | Insert message, typing, composer, error banner | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Message insert size+fade, typing rhythm, composer focus, quota/error transition; tách animation controller khỏi business events. |
| lib/app_versions/v1/features/ai_voice/presentation/pages/ai_voice_page.dart | Message/voice state fade-size | Idle → listening → processing → speaking → error | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Voice orb state machine idle/listening/processing/speaking/error; đồng bộ Nabi và sound cue, stale async không làm replay. |

## File-by-file design

| File | Kind | Role | Current evidence | Target design | Transition contract | Wave |
| --- | --- | --- | --- | --- | --- | --- |
| lib/app_versions/v1/features/ai_chat/presentation/controllers/ai_chat_controller.dart | controller | AIChatState / AIChatController | Chưa có motion/feedback đáng kể | Giữ nguyên nghiệp vụ; chuẩn hóa UI phase/state identity; loại bỏ haptic trực tiếp khỏi controller và phát feedback sau khi state thành công/thất bại được xác nhận. | Stable state/identity contract | W6 AI/Voice |
| lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart | page | AIChatScreen / _AIChatScreenState / _ChatErrorBanner / _ChatHeaderTitle | controller×2, AnimatedContainer×2, AnimatedSwitcher×1, TweenAnimationBuilder×2, haptic trực tiếp×3, duration raw×1, Colors.*×3, motion token×6, Semantics×4, Nabi×6 | Message insert size+fade, typing rhythm, composer focus, quota/error transition; tách animation controller khỏi business events. | Insert message, typing, composer, error banner | W6 AI/Voice |
| lib/app_versions/v1/features/ai_voice/presentation/controllers/ai_voice_controller.dart | controller | AiVoiceController | Chưa có motion/feedback đáng kể | Giữ nguyên nghiệp vụ; chuẩn hóa UI phase/state identity; loại bỏ haptic trực tiếp khỏi controller và phát feedback sau khi state thành công/thất bại được xác nhận. | Stable state/identity contract | W6 AI/Voice |
| lib/app_versions/v1/features/ai_voice/presentation/pages/ai_voice_page.dart | page | AiVoicePage / _AiVoicePageState / _NabiVoiceHero / _VoiceMessageCard | AnimatedContainer×1, AnimatedSwitcher×1, motion token×2, Semantics×1, Nabi×11 | Voice orb state machine idle/listening/processing/speaking/error; đồng bộ Nabi và sound cue, stale async không làm replay. | Idle → listening → processing → speaking → error | W6 AI/Voice |
| lib/app_versions/v1/shared/widgets/ai_chat_fab.dart | widget | AIChatFAB / _AIChatFABState / DraggableAIChatButton / _DraggableAIChatButtonState | controller×6, AnimatedContainer×1, AnimatedOpacity×1, AnimatedScale×1, haptic trực tiếp×4, duration raw×2, Colors.*×1, motion token×5, Semantics×1, Nabi×4 | FAB press/drag/morph thống nhất, snap physics có giới hạn; feedback qua service; tránh haptic spam khi kéo. | Insert message, typing, composer, error banner | W6 AI/Voice |

## Acceptance

- Không raw sound/haptic call ngoài feedback service.
- Không motion replay khi state không đổi.
- Có reduced-motion behavior.
- Có loading/empty/error/ready hoặc lý do không áp dụng.
- Targeted widget/route/state test được bổ sung trong coding wave.
