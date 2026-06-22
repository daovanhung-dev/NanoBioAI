# NABI_INTEGRATION_GUIDE

## 1. Khai báo asset

Bổ sung vào `pubspec.yaml` (nếu chưa có):

```yaml
flutter:
  assets:
    - assets/images/nabi/
    - assets/config/nabi/
```

Sau đó chạy `flutter pub get`.

## 2. Nguyên tắc kiến trúc

Giữ hướng phụ thuộc hiện có của dự án:

`Presentation → Provider/Controller → Repository → Datasource → DAO/API`

- Widget chỉ nhận `NabiVisualState` hoặc `NabiAssetDescriptor`; không tự kiểm tra SQLite/Supabase.
- Controller/Provider lấy dữ liệu use case: onboarding state, task completion, last open, sync state, quota, membership.
- Repository/Datasource trả về dữ liệu nghiệp vụ. Controller chuyển dữ liệu thành `NabiVisualState` theo `nabi_state_matrix.yaml`.
- Không hard-code đường dẫn asset rải rác ở màn hình. Chỉ đọc từ manifest/config hoặc một registry typed.

## 3. Gợi ý typed contract

```dart
enum NabiVisualState {
  defaultIdle,
  welcome,
  aiListening,
  aiGenerating,
  taskDone,
  taskSkipped,
  away3d,
  welcomeBack,
  offline,
  syncSuccess,
}

class NabiAssetDescriptor {
  const NabiAssetDescriptor({
    required this.path,
    required this.motionId,
    required this.semanticLabel,
  });

  final String path;
  final String motionId;
  final String semanticLabel;
}
```

## 4. UI usage

- Hero/empty state: 160–240dp.
- Chat avatar: 32–48dp.
- Inline task feedback: 72–120dp.
- Notification: dùng copy/câu chữ, **không** dùng full PNG trong push notification.
- Dùng `Semantics(label: ...)` cho ảnh khi ảnh mang ý nghĩa; `excludeFromSemantics: true` nếu chỉ trang trí.

## 5. Trạng thái ưu tiên

1. Lỗi hệ thống/ngoại tuyến.
2. Đang tạo lịch/đang xử lý AI.
3. Kết quả nhiệm vụ: complete/skip/streak.
4. Context màn hình: onboarding/chat/daily.
5. Engagement band: new/regular/away/welcome back.
6. Idle mặc định.

## 6. Test tối thiểu

- Unit test chọn đúng asset theo `NabiVisualState`.
- Widget test kiểm tra `Image.asset` nhận đúng path.
- Test không hiển thị asset celebration khi task bị skip.
- Test away 3d/7d không dùng copy trách móc.
- Golden test cho màn onboarding, chat empty/loading và dashboard empty state.
