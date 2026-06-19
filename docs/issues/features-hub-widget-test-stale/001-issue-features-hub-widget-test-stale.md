Commit đề xuất: docs(issue): ghi nhận lỗi widget test features hub không khớp UI hiện tại

# Features Hub widget test tìm AI Coach không còn tồn tại

## Tóm tắt
- `flutter test` fail vì test tìm text `AI Coach`.
- UI hiện tại dùng tiếng Việt và tile AI là `Trò chuyện với Nami`.
- Test cũng kỳ vọng snackbar `Tính năng đang phát triển`, trong khi tile AI hiện điều hướng tới route chat.

## Mức độ ảnh hưởng
- Severity: medium
- Ảnh hưởng user: không trực tiếp nếu UI hiện tại là chủ đích.
- Ảnh hưởng dev/build/test: test suite đỏ, không đủ điều kiện đóng release 1.0.

## Cách tái hiện
1. Chạy `flutter test`.
2. Test `placeholder feature shows development snackbar` fail.
3. Lỗi: finder không tìm thấy widget text `AI Coach`.

## Đã xác nhận
- `test/features/features_hub/features_hub_page_test.dart:6-15` tap `AI Coach` và đợi snackbar phát triển.
- `lib/features/features_hub/presentation/pages/features_hub_page.dart:61-67` tile AI hiện là `Trò chuyện với Nami` và `context.push(RoutePaths.aiChat)`.

## Giả thuyết
- Test cũ chưa cập nhật sau khi đổi copy/behavior Features Hub.

## Workaround
- Bỏ qua test này khi audit thủ công, nhưng không nên release khi test suite vẫn đỏ.

## Hướng fix đề xuất
- Nếu behavior mới đúng: cập nhật test để tap `Trò chuyện với Nami` và assert route chat.
- Nếu placeholder vẫn là yêu cầu: đổi UI về placeholder snackbar hoặc thêm card placeholder riêng.

## Files/log liên quan
- `test/features/features_hub/features_hub_page_test.dart`
- `lib/features/features_hub/presentation/pages/features_hub_page.dart`

## Liên kết
- Worklog: ../../worklog/2026-06-19/007-worklog-release-1-0-bug-audit.md
