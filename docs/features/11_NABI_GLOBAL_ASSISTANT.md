# 11 — Nabi: nhân vật trợ lý nổi toàn cục

## Mục tiêu đã triển khai

Nabi thay thế hoàn toàn vai trò của nút AI Chat dạng hình cũ:

- Luôn hiển thị nổi trên mọi màn hình được bọc bởi `NabiAppShell`.
- Chạm Nabi mở `/ai-chat` (hoặc callback điều hướng có sẵn của dự án).
- Kéo Nabi tới vị trí thuận tay trong phiên hiện tại.
- Nhấn giữ để thu gọn/mở rộng nhân vật.
- Biểu cảm thay đổi thật bằng Canvas theo `NabiEmotion`; không phải một ảnh tĩnh đổi text.
- Cảm xúc đổi theo route và event nghiệp vụ của Onboarding, Dashboard, AI Chat, tính toán sức khỏe, lịch trình, nhắc việc, xác thực, đồng bộ và lỗi.
- Lời thoại theo tone Nami/Nabi: ngắn, ấm áp, không phán xét, không lộ thuật ngữ kỹ thuật.

## Kiến trúc

```text
Feature/Screen
  └─ dispatch NabiEvent
       └─ NabiController (Riverpod)
            └─ NabiExpressionResolver
                 └─ NabiState
                      └─ NabiAssistantOverlay + NabiCharacter (Canvas)
```

Dependency direction tuân theo quy ước NanoBio:

```text
Presentation → Provider/Controller → Repository → Datasource → DAO/API
```

Module Nabi chỉ nhận UI event và không đọc trực tiếp SQLite, Supabase, Gemini hay notification. Feature sở hữu nghiệp vụ sẽ gửi `NabiEvent` sau khi use-case thành công/thất bại.

## Cài vào app

### 1. Xuất module

Module đã có barrel export:

```dart
import 'features/Nabi/Nabi.dart';
```

### 2. Bọc shell chung — bắt buộc để Nabi có mặt trên tất cả màn hình

Trong `ShellRoute.builder` hoặc widget dùng chung đang trả về `Scaffold`/`NavigationShell`, bọc `child` một lần:

```dart
return NabiAppShell(
  config: NabiOverlayConfig(
    chatRoute: '/ai-chat',
    // Dùng callback này nếu dự án đã có auth guard/analytics cho AI Chat.
    // onOpenChat: (context) => context.go('/ai-chat'),
  ),
  child: child,
);
```

> Không đặt `NabiAssistantOverlay` riêng trong Dashboard. Làm vậy Nabi sẽ biến mất khi đổi tab hoặc vào AI Chat.

### 3. Gắn `NabiRouteObserver` vào GoRouter

Trong provider hoặc nơi khởi tạo `GoRouter` có `Ref ref`:

```dart
final router = GoRouter(
  observers: <NavigatorObserver>[
    createNabiRouteObserver(ref),
  ],
  routes: routes,
);
```

Mỗi `GoRoute` nên có `name` là path hoặc semantic name chứa các keyword như `dashboard`, `onboarding`, `ai-chat`, `calculator`, `meal`, `exercise`, `task`, `schedule`, `login`, `register`.

Ví dụ:

```dart
GoRoute(
  name: '/ai-chat',
  path: '/ai-chat',
  builder: (context, state) => const AIChatScreen(),
),
```

Nếu routing hiện tại không truyền route name, gọi ở page entry:

```dart
ref.read(NabiControllerProvider.notifier).setContext(NabiContext.dashboard);
```

### 4. Bỏ FAB AI Chat cũ tại Dashboard

Xóa `floatingActionButton` đang điều hướng đến `/ai-chat`. Nabi đã kế thừa điều hướng này. Không cần tạo thêm một nút chat khác.

## Gắn biểu cảm vào flow thực tế

### Onboarding

```dart
final Nabi = ref.read(NabiControllerProvider.notifier);
Nabi.dispatch(NabiEvent.onboardingStarted);

// Sau khi user hoàn thành một step hợp lệ:
Nabi.dispatch(NabiEvent.onboardingStepCompleted);

// Sau khi lưu SQLite + tạo lịch trình AI thành công:
Nabi.dispatch(NabiEvent.onboardingCompleted);
```

### AI Chat

```dart
final Nabi = ref.read(NabiControllerProvider.notifier);
Nabi.dispatch(NabiEvent.aiChatOpened);

try {
  Nabi.setChatThinking();
  final reply = await aiChatController.send(message);
  Nabi.setChatResponded();
} catch (_) {
  Nabi.setChatFailed();
}
```

### Tính toán sức khỏe

```dart
final Nabi = ref.read(NabiControllerProvider.notifier);
Nabi.dispatch(NabiEvent.healthCalculationStarted);

final result = await calculateHealth(...);
Nabi.dispatch(NabiEvent.healthCalculationCompleted);
```

### Nhiệm vụ và thông báo

```dart
// Action "Đã làm"
ref.read(NabiControllerProvider.notifier).dispatch(NabiEvent.taskCompleted);

// Action "Bỏ qua"
ref.read(NabiControllerProvider.notifier).dispatch(NabiEvent.taskSkipped);

// Khi mở notification
ref.read(NabiControllerProvider.notifier).dispatch(NabiEvent.notificationOpened);
```

### Đồng bộ / xác thực / lỗi

```dart
Nabi.dispatch(NabiEvent.synchronizationStarted);
Nabi.dispatch(NabiEvent.synchronizationSucceeded);
Nabi.dispatch(NabiEvent.synchronizationFailed);
Nabi.dispatch(NabiEvent.authenticationRequired);
Nabi.dispatch(NabiEvent.formNeedsAttention);
Nabi.dispatch(NabiEvent.networkUnavailable);
```

## Bảng biểu cảm

| Tình huống | `NabiEmotion` | Hành vi hình thể |
|---|---|---|
| Mở app / onboarding | `greeting` | Gật đầu nhẹ, mắt sáng |
| Dashboard / động viên | `encouraging` | Mỉm cười, trái tim nhỏ |
| Người dùng hỏi AI | `listening` | Mắt mở to, tập trung |
| AI đang phản hồi / đang tính | `thinking` | Mắt nhìn lên, hạt suy nghĩ |
| Có kết quả / thực đơn | `happy` | Mắt cười, má hồng |
| Hoàn thành nhiệm vụ | `celebrating` | Mắt sao, chuyển động vui |
| Lỗi nhập / mất mạng | `concerned` | Lông mày dịu, dấu chú ý |
| Ít hoạt động lâu | `sleepy` | Mắt khép, ký hiệu Z |

## Kiểm thử

Chạy sau khi giải nén và tích hợp:

```bash
flutter pub get
flutter analyze
flutter test test/features/Nabi/application/Nabi_controller_test.dart
flutter test
```

Kiểm tra thủ công trên thiết bị:

1. Mở Dashboard → Nabi nổi, không còn FAB cũ.
2. Chuyển đủ tab, vào onboarding, calculator, AI Chat → Nabi không biến mất.
3. Kéo Nabi ở cạnh phải/trái, không chặn thao tác chính của màn hình.
4. Chạm Nabi từ bất cứ màn hình nào → mở đúng `/ai-chat`.
5. Khi AI đang chờ → Nabi `thinking`; AI trả lời → `happy`; lỗi → `concerned`.
6. Bấm “Đã làm” / “Bỏ qua” lịch trình → đúng `celebrating` / `encouraging`.
7. Kiểm tra TalkBack/VoiceOver đọc đúng semantic label.

## Lưu ý triển khai sau patch

- Module không tự tạo mock data, không thay flow V1/V2/V3.
- Nabi không lưu chat history; module chỉ là điểm vào AI Chat hiện có.
- Nabi không tự gọi Gemini/Supabase/SQLite.
- Nếu cần giữ vị trí qua lần mở app, thêm `NabiPositionRepository` dùng datasource hiện có của dự án; không đặt SharedPreferences trực tiếp trong widget.
