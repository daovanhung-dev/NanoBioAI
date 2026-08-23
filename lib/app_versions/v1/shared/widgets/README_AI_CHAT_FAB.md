# AI Chat FAB Widget

Lifecycle: `Current source note`. Baseline: `25018e8`.

`ai_chat_fab.dart` cung cấp:

- `AIChatFAB`: nút chat có entrance/breathing/orbit motion, reduced-motion và
  economical-tier fallback.
- `DraggableAIChatButton`: wrapper có thể kéo, long-press để reset vị trí và
  gọi `AIChatFAB`.

## Reachability hiện tại

- `DashboardPage` dùng `DraggableAIChatButton` khi
  `showStandaloneChatButton == true` (mặc định cho route dashboard độc lập).
- `MainNavigationPage` truyền `showStandaloneChatButton: false` và dùng
  `NabiFloatingOverlay`; vì vậy tài liệu không được nói FAB được gắn trực tiếp
  trong main navigation.
- Tap mặc định dùng `context.push(V1RoutePaths.aiChat)`; route AI Chat cần auth.

## Contract

```dart
const AIChatFAB(
  size: 64,
  showStatusDot: true,
  tooltip: 'Nabi ở đây khi bạn cần',
)
```

Có thể truyền `onPressed` để caller kiểm soát navigation. Motion policy đến từ
`AppMotionScope`; feedback đến từ `AppFeedbackService`.

Không gọi status dot là bằng chứng live Gemini/network availability: widget
không đọc AI config hoặc network state.

Verification: static reachability; visual/device behavior `UNVERIFIED` nếu
không có test/device evidence riêng.
