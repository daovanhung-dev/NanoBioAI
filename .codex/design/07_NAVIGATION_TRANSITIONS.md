# Navigation and Spatial Transition Design

## 1. Registry

Tạo `AppRouteMotionSpec` ánh xạ route/archetype thay vì mỗi router tự viết transition.

| Archetype | Enter | Exit/secondary | Duration |
|---|---|---|---:|
| Detail | fade + 12 px horizontal + scale 0.995 | previous scale 0.995 | 360 ms |
| Onboarding step | direction-aware 16 px + fade | reverse symmetric | 320 ms |
| Tab/destination | fade-through | fade-through | 220 ms |
| Modal/dialog | fade-scale 0.96 | scrim fade | 260 ms |
| Bottom sheet | vertical spring | scrim fade | 320–360 ms |
| Auth guard/redirect | static/fade | none | 0–140 ms |
| Admin workspace | fade + 4 px | fade | 220–280 ms |

## 2. Back behavior

- Push và back phải đối xứng.
- Hardware back giữ state/scroll và không replay entrance toàn page.
- Direct-route fallback không tạo double transition.
- Redirect chain không hiện flash màn hình protected.

## 3. Shared elements

Ưu tiên cho:

- Meal card → recipe detail.
- Insight card → insight detail.
- Proof thumbnail → proof preview.
- Avatar → profile edit.
- Health score card → score breakdown.

Hero tag phải dựa trên entity ID + route scope, không dùng index.

## 4. Navigation destination

- Một sliding active indicator.
- Icon scale/fill nhẹ; label fade/slide 2 px.
- Body fade-through, không slide toàn màn hình giữa peer tabs.

## 5. Reduced motion

- Route static hoặc fade 80 ms.
- Shared-element transform bị tắt; giữ focus/semantic order.
