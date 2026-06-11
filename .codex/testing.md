# Testing

## Trạng thái hiện tại
**Hầu như không có test.** Đây là điểm yếu lớn nhất của dự án.

## File test tồn tại
- `test/widget_test.dart` — **file rỗng** (không có nội dung)

## Test framework available
- `flutter_test` (SDK) — đã khai báo trong `pubspec.yaml` dev_dependencies
- Không có test runner custom, không có integration test setup

## Coverage
- Unit tests: 0%
- Widget tests: 0%
- Integration tests: 0%

## Chạy test
```bash
flutter test
# → sẽ không chạy gì vì widget_test.dart rỗng
```

## Phần cần test nhất (ưu tiên cao)

1. **`OnboardingController`** — business logic phức tạp nhất (state management, validation, data mapping)
2. **`OnboardingRemoteDatasource.saveOnboarding()`** — transaction SQLite nhiều bảng, dễ có bug edge case
3. **`AIService.generateMealPlan()`** — parse JSON từ AI, có retry logic
4. **`NutritionPrompt.generateMealPlan()`** — prompt building
5. **`RouteGuards`** — auth/guest guard logic
6. **`OnboardingState.canSave`** — validation condition
7. **`OnboardingState.bmi`** — tính toán số học

## Ghi chú
- `analysis_options.yaml` dùng `package:flutter_lints/flutter.yaml` — linter đang hoạt động
- Không có mock infrastructure (Mocktail, Mockito) được khai báo
