# Nabi global companion

## Goal

Hợp nhất owner, priority queue, animation lifecycle, speech bubble và feedback orchestration.

## Current evidence

- Files: **11**.
- Page/screen: **0**.
- Files có motion: **6**.
- Files dùng duration raw: **4**.
- Files dùng color trực tiếp: **0**.
- Files gọi haptic trực tiếp: **3**.

## Group design rules

- Một owner + priority queue + cooldown.
- Renderer pure visual; feedback qua service.
- Pause/cache theo visibility/lifecycle.
- Static first-frame fallback cho reduced motion/performance.

## File-by-file design

| File | Kind | Role | Current evidence | Target design | Transition contract | Wave |
| --- | --- | --- | --- | --- | --- | --- |
| lib/app_versions/v1/features/nabi/presentation/nabi_page_mixin.dart | presentation_support | _DashboardPageState | Nabi×16 | Giữ logic thuần; bổ sung semantic presentation metadata hoặc stable identity chỉ khi cần cho transition; không chứa animation, sound hay BuildContext. | Stable state/identity contract | W6 AI/Nabi |
| lib/app_versions/v1/features/nabi/presentation/nabi_route_observer.dart | presentation_support | NabiRouteObserver | Nabi×4 | Giữ logic thuần; bổ sung semantic presentation metadata hoặc stable identity chỉ khi cần cho transition; không chứa animation, sound hay BuildContext. | Stable state/identity contract | W6 AI/Nabi |
| lib/app_versions/v1/features/nabi/presentation/widgets/nabi_character_widget.dart | widget | NabiCharacterWidget / _NabiCharacterWidgetState / _NabiAura / _NabiImage | controller×28, duration raw×11, motion token×8, Semantics×1, Nabi×72 | Compatibility wrapper cho V1; route về renderer canonical và lên kế hoạch deprecate. | Loading/empty/error/ready và action result | W6 AI/Nabi |
| lib/app_versions/v1/features/nabi/presentation/widgets/nabi_floating_overlay.dart | widget | NabiFloatingOverlay / _NabiFloatingOverlayState / _NabiLabel | controller×2, AnimatedSwitcher×1, AnimatedOpacity×2, AnimatedScale×1, haptic trực tiếp×3, motion token×5, Nabi×27 | Hợp nhất với global overlay hoặc định nghĩa owner riêng rõ; không để hai mascot chồng nhau. | Loading/empty/error/ready và action result | W6 AI/Nabi |
| lib/features/nabi/presentation/navigation/nabi_route_mapper.dart | presentation_support | NabiRouteMapper | Nabi×14 | Giữ logic thuần; bổ sung semantic presentation metadata hoặc stable identity chỉ khi cần cho transition; không chứa animation, sound hay BuildContext. | Stable state/identity contract | W6 AI/Nabi |
| lib/features/nabi/presentation/navigation/nabi_route_observer.dart | presentation_support | NabiRouteObserver | Nabi×6 | Giữ logic thuần; bổ sung semantic presentation metadata hoặc stable identity chỉ khi cần cho transition; không chứa animation, sound hay BuildContext. | Stable state/identity contract | W6 AI/Nabi |
| lib/features/nabi/presentation/widgets/nabi_animation_player.dart | widget | NabiAnimationPlayer / _NabiAnimationPlayerState / _NabiStaticFallback | controller×2, Nabi×14 | Canonical playback lifecycle: visibility/ticker control, first-frame fallback, cache budget, reduced-motion static expression. | Loading/empty/error/ready và action result | W6 AI/Nabi |
| lib/features/nabi/presentation/widgets/nabi_app_shell.dart | widget | NabiAppShell | Nabi×7 | Một Nabi owner toàn app; cung cấp route context, safe-area/keyboard avoidance và feedback scope. | Loading/empty/error/ready và action result | W6 AI/Nabi |
| lib/features/nabi/presentation/widgets/nabi_assistant_overlay.dart | widget | NabiOverlayConfig / NabiAssistantOverlay / _NabiAssistantOverlayState / _NabiFloatingControl | controller×2, AnimatedScale×1, AnimatedSize×1, haptic trực tiếp×2, duration raw×2, motion token×2, Semantics×1, Nabi×19 | Overlay open/close/shared transition, focus trap, drag/collapse semantics; feedback qua service. | Loading/empty/error/ready và action result | W6 AI/Nabi |
| lib/features/nabi/presentation/widgets/nabi_character.dart | widget | NabiCharacter / _NabiCharacterState / _NabiCharacterPainter | controller×4, duration raw×2, Nabi×35 | Pure visual renderer; không business logic, haptic hay sound; map emotion/animation từ orchestrator. | Loading/empty/error/ready và action result | W6 AI/Nabi |
| lib/features/nabi/presentation/widgets/nabi_floating_mascot.dart | widget | NaBiFloatingMascot / _NaBiFloatingMascotState / _MascotLabel | AnimatedScale×1, haptic trực tiếp×2, duration raw×2, motion token×1, Semantics×1, Nabi×11 | Press/drag/greeting qua canonical primitive; bỏ raw duration và haptic trực tiếp; cooldown tap. | Loading/empty/error/ready và action result | W6 AI/Nabi |

## Acceptance

- Không raw sound/haptic call ngoài feedback service.
- Không motion replay khi state không đổi.
- Có reduced-motion behavior.
- Có loading/empty/error/ready hoặc lý do không áp dụng.
- Targeted widget/route/state test được bổ sung trong coding wave.
