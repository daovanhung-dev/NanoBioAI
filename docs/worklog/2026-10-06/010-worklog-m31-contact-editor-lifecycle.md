Commit de xuat: fix(ui): sửa vòng đời hộp thoại liên hệ an toàn

# Worklog — M31 sửa lỗi khi thoát chỉnh sửa liên hệ

## Thời gian

- Ngày: 2026-10-06
- Bắt đầu: Không ghi nhận chính xác
- Kết thúc: 18:44
- Múi giờ: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: bugfix.
- Module chính: M31 `SLEEP_SAFETY_MONITORING`.
- Yêu cầu gốc: sửa màn hình Flutter assertion khi thoát chỉnh sửa liên hệ mà
  không lưu; giữ nguyên dữ liệu liên hệ và phiên giám sát.

## Đã làm

- Chuyển form sửa liên hệ thành widget có state riêng, quản lý các controller
  theo vòng đời của hộp thoại; chỉ gửi bản nháp khi chọn **Lưu**.
- Hủy, Back hệ thống và chạm ngoài không ghi dữ liệu. Đóng route danh sách trở
  về màn giám sát mà không làm mất trạng thái đang hoạt động trong regression
  test.
- Bổ sung stack trace Flutter debug đã lọc nội dung lỗi nhạy cảm.
- Tạo widget regression tests cho Hủy/Back/chạm ngoài, quay lại bằng mũi tên và
  nhánh Lưu.

## File code/docs đã sửa

- `lib/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_safety_contacts_page.dart`
  — chuyển quyền sở hữu form/controller vào dialog state.
- `lib/core/utils/logger/app_error_capture.dart` — thêm stack trace debug với
  nội dung exception/context bị loại khỏi bản dump.
- `test/app_versions/v1/features/sleep_tracking/presentation/sleep_safety_contacts_page_test.dart`
  — thêm kiểm thử route và hành vi bỏ thay đổi.
- `test/core/utils/logger/app_error_capture_test.dart` — xác nhận stack trace có
  mặt nhưng payload riêng tư không bị ghi ra.
- `docs/fixbug/sleep-safety-contact-editor/001-fixbug-m31-contact-editor-dismissal.md`
  — ghi nhận hiện tượng, xử lý và giới hạn nghiệm thu.

## Lệnh và kết quả

- `dart format` trên 4 file Dart: PASS.
- `flutter analyze --no-pub` trên 4 file Dart: PASS, 0 issue.
- Test trang liên hệ và logger: PASS, 5/5.
- Test presentation M31, controller M31 và logger: PASS, 38/38.
- `flutter build apk --debug --no-pub`: PASS. Gradle 8.14.0, AGP 8.11.1 và
  Kotlin 2.2.20 phát cảnh báo tương thích tương lai của Flutter.
- `adb install -r build/app/outputs/flutter-apk/app-debug.apk`: PASS trên
  Xiaomi 220333QPG / Android 11; dữ liệu ứng dụng không bị xóa.
- Mở app sau cài đặt: PASS; spinner khởi động chuyển sang Dashboard. Ảnh mới
  nhất không có màn hình assertion; logcat không có `_dependents.isEmpty`,
  `E/flutter` hoặc `FATAL EXCEPTION` trong lượt khởi động này.
- Thao tác thủ công trong UI: UNVERIFIED; ADB/UIAutomator không thao tác chạm
  được, nên chưa mở được trang M31 để lặp lại thao tác sửa liên hệ.
- `git diff --check`: PASS.
- `pwsh -NoProfile -File .codex/tools/update_worklog_learning.ps1`: PASS; làm mới
  19 file history/task-skill và thêm mục worklog này vào index.
- `pwsh -NoProfile -File .codex/tools/validate_codex_integrity.ps1`: FAIL do
  thiếu `docs/audit/source_truth_manifest.json` và các đường dẫn cũ trong
  `.codex/history/WORKLOG_2026-08-16_meal_nutrition_estimation.md` cùng
  `.codex/task-skills/nabi-character/SKILL.md`; không thuộc phạm vi thay đổi.

## Lỗi/Rủi ro

- Stack trace gốc của assertion không được lưu trước khi sửa nên nguyên nhân
  widget chính xác chưa được xác nhận bằng runtime.
- Luồng sửa liên hệ rồi thoát chưa được thao tác lại bằng tay trên thiết bị;
  widget regression tests bao phủ các cách đóng hộp thoại và route.
- Không thay đổi hoặc xóa liên hệ thật, không thực hiện cuộc gọi.

## Tỷ lệ hoàn thành

- Hoàn thành: sửa quyền sở hữu form, regression tests, analyzer, build và cài
  bản debug giữ dữ liệu.
- Chưa xác nhận: thao tác thủ công trên UI Xiaomi do môi trường không nhận
  thao tác chạm tự động.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt — form chỉ lưu theo kết quả rõ ràng và tài nguyên được
  quản lý tại widget sở hữu chúng.
- Mức độ hoàn thành task: code và kiểm tra tự động hoàn tất; nghiệm thu UI máy
  thật chưa hoàn tất.
- Bằng chứng kiểm chứng: 38 test PASS, analyzer 0 issue, debug APK cài thành
  công; Dashboard hiển thị sau startup, nhưng chưa phải bằng chứng hoàn tất
  luồng chỉnh sửa liên hệ.
- Điểm tốn token/chưa tối ưu: thiếu thao tác UI máy thật để tái hiện lỗi gốc và
  đọc stack ban đầu.
- Cách tối ưu cho phiên sau: sau khi app vào được trang M31, lặp lại Hủy/Back
  trên Xiaomi và thu stack nếu assertion còn xuất hiện.
- Task-skill cần đọc lần sau: `.codex/task-skills/bugfix.md`.
