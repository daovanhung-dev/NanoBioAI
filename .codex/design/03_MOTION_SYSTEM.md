# Nabi Kinetic Motion System

## 1. Duration tokens

| Token | Duration | Use |
|---|---:|---|
| `instant` | 0 ms | Reduced/static state |
| `press` | 90 ms | Pointer down/up |
| `micro` | 140 ms | Check, icon, focus |
| `quick` | 180 ms | Chip, switch, small state |
| `standard` | 240 ms | Card/input/content transition |
| `emphasized` | 320 ms | Modal, step, complex state |
| `route` | 360 ms | Page transition |
| `hero` | 420 ms | Shared container/Hero |
| `celebration` | 520 ms | Milestone, plan ready |
| `ambient` | 2200–4000 ms | Whitelisted slow loop only |

## 2. Curves

- Enter: `easeOutCubic`.
- Exit: `easeInCubic`.
- Standard state: `fastOutSlowIn` hoặc canonical cubic tương đương.
- Emphasized: spring preset có damping cao, không elastic bounce.
- Drag/snap: spring riêng, velocity-aware.

## 3. Distances and scale

| Token | Value |
|---|---:|
| micro shift | 2 px |
| small shift | 4 px |
| component enter | 8 px |
| page enter | 12–16 px |
| button pressed | 0.975 |
| card pressed | 0.988 |
| chip icon enter | 0.78 → 1 |
| modal enter | 0.96 → 1 |
| background page scale | 0.995 |

## 4. Transition taxonomy

### Micro
Press, focus, select, toggle, icon morph, number delta.

### Component
Loading→ready, empty→content, card expand, list insert/delete, validation, progress.

### Spatial
Route push/back, card-to-detail, modal, bottom sheet, navigation destination.

## 5. Route registry

- Detail: shared-axis horizontal + subtle fade/scale.
- Full-screen creation/onboarding: directional step transition.
- Tab/destination: fade-through.
- Modal/dialog: fade-scale.
- Bottom sheet: spring slide + content delayed 40 ms.
- Auth redirects/guards: static/fade-through, không slide qua nhiều màn hình trung gian.
- Admin: fade-through 4 px, route 220–280 ms.

## 6. State switch rules

- `AnimatedSwitcher` child bắt buộc có key theo semantic state.
- Loading placeholder giữ layout để tránh jump.
- Number tween chỉ khi value đổi, không tween lại từ 0.
- List insert/delete dùng item ID; không dùng index làm identity.
- Provider refresh cùng value không chạy animation.

## 7. Reduced motion

- Bỏ translation, scale, parallax, shimmer và loop.
- Giữ opacity/color transition 0–120 ms để state vẫn rõ.
- Nabi dùng static expression hoặc first frame.
- Route chuyển static hoặc fade 80 ms.

## 8. Ambient whitelist

Chỉ các thành phần sau được loop:

- Voice orb khi listening/processing.
- Nabi idle khi visible.
- Loading spinner/shimmer có timeout và visibility.
- Dashboard ambient background rất chậm, tối đa một effect.

Không loop: button, card, warning, locked, text, normal icon.
