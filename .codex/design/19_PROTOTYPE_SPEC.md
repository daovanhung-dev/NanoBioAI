# Prototype Specification

Trước khi coding diện rộng, dựng và duyệt 16 prototype dưới đây trên design-system demo hoặc isolated test app. Mỗi prototype phải có Full/Balanced/Reduced, sound on/off và haptic on/off.

| ID | Prototype | Success criteria |
|---|---|---|
| P01 | Primary button press/loading/success/error | Không đổi kích thước; success sau commit; reduced static |
| P02 | Chip/segmented selection | Indicator liên tục, haptic một lần, stable semantics |
| P03 | Input focus/validation/password | Không shake khi gõ; keyboard-safe |
| P04 | Card expand và card-to-detail | Identity/Hero đúng; back đối xứng |
| P05 | Bottom navigation | Indicator glide; body fade-through; scroll giữ nguyên |
| P06 | Dashboard score/timeline delta | Không replay khi refresh cùng data |
| P07 | Timeline complete/skip/proof | Feedback sau transaction, không duplicate |
| P08 | Meal replacement | Replace in place; macro old→new; warning clarity |
| P09 | Onboarding step/back | Directional, state giữ, progress morph |
| P10 | AI message/typing/error | Scroll ổn định; insert identity; cue semantic |
| P11 | Voice orb | Idle/listen/process/speak/error + lifecycle |
| P12 | Nabi priority/interrupt | One owner, cooldown, static fallback |
| P13 | Loading→ready/empty/error | Layout không jump; outgoing semantics hidden |
| P14 | Milestone/plan ready | 520 ms max; event dedup; sound/haptic policy |
| P15 | Payment pending→approved | Pending không giống active; trusted approval only |
| P16 | Admin table/filter/mutation | Motion density thấp; row highlight; sound off |

## Review output

- Screen recording 60fps hoặc frame capture.
- Accessibility/reduced-motion recording.
- Interaction event log từ fake feedback adapter.
- Chốt token/API trước khi Wave 1 hoàn tất.
