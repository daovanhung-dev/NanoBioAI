# AI Chat FAB Widget

## Mô tả
Floating Action Button (FAB) để mở màn hình AI Chat. Widget này có animation mượt mà, hiệu ứng glow và ripple effect khi nhấn.

## Cách sử dụng

### 1. Thêm vào Scaffold bất kỳ

```dart
import 'package:nano_app/shared/widgets/ai_chat_fab.dart';

Scaffold(
  // ... other properties
  floatingActionButton: const AIChatFAB(),
  floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
)
```

### 2. Sử dụng với custom location

```dart
Scaffold(
  floatingActionButton: const AIChatFAB(),
  floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
)
```

### 3. Thêm vào Dashboard Page

Đã được tích hợp sẵn trong `MainNavigationPage` (menu_page.dart).

## Tính năng

- ✅ Animation xuất hiện mượt mà (elastic bounce)
- ✅ Pulse effect liên tục
- ✅ Glow shadow với animation
- ✅ Ripple effect khi nhấn
- ✅ Haptic feedback
- ✅ Rotating outer ring
- ✅ Online indicator (pulse dot)
- ✅ Tuân thủ 100% Design System (AppColors, AppGradients, AppIcons)

## Design tokens sử dụng

- **Gradient**: `AppGradients.ai` (primary + secondary blend)
- **Icon**: `AppIcons.aiChat`
- **Animation Duration**: `AppDuration.slow`
- **Shadow**: Custom với `AppColors.primary` và `AppColors.secondary`

## Animation timeline

1. **0-300ms**: Delay trước khi xuất hiện
2. **300-1000ms**: Entrance animation (elastic out)
3. **3000ms+**: Pulse animation bắt đầu lặp lại

## Navigation

Khi nhấn vào FAB, sẽ navigate tới `/ai-chat` route sử dụng `context.push()` từ GoRouter.

## Responsive

- Size: 64x64 dp (optimal touch target)
- Icon size: 28 dp
- Glow radius: adaptive theo animation value
- Scale on press: 0.9x (feedback rõ ràng)

## Accessibility

- Minimum touch target: 64x64 (theo Material Design guidelines)
- Haptic feedback: Medium impact on tap, selection click on press
- Visual feedback: Scale animation khi nhấn

## Performance

- Sử dụng `SingleTickerProviderStateMixin` cho animation controller duy nhất
- Animation chỉ chạy khi widget mounted
- Tự động dispose controller khi widget unmount
