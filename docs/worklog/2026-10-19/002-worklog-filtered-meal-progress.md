Commit de xuat: docs(worklog): ghi nhan sua tien do loc mon

# Worklog - Trạng thái và danh sách món sau lọc

## Thời gian

- Ngày: 2026-10-19
- Bắt đầu: Không ghi nhận chính xác trong lượt tiếp tục.
- Kết thúc: 11:11.
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: Triển khai bugfix và kiểm chứng theo plan đã duyệt.
- Module chính: `GeneratedPlanService`, `GeneratedPlanProgressPanel`, onboarding retry.
- Yêu cầu gốc: Hiển thị đúng trạng thái lọc và toàn bộ món còn lại trên panel; không báo rỗng trước khi lọc xong; giữ fail-closed và luồng món riêng chờ duyệt.

## Đã làm

- Thêm trạng thái `notStarted`, `filtering`, `complete` cùng tổng số món catalog vào progress.
- Báo đang lọc trước preflight ở cả onboarding guest và member, rồi phát kết quả lọc trước AI.
- Thêm log chỉ gồm tổng số món, món còn lại và lỗi phân loại.
- Panel không hiện `0` trước khi lọc xong; kết quả hoàn tất hiển thị số còn lại trên tổng catalog và lý do nếu rỗng.
- Tự mở buổi và loại bữa đầu tiên có món. Test xác nhận tên món xuất hiện ngay trên màn hẹp và cỡ chữ lớn.
- Luồng khôi phục onboarding dùng panel chung và xử lý món riêng chờ duyệt; lỗi phân loại được hiển thị bằng thông báo có nghĩa.
- Trên Xiaomi Android 11, cài debug giữ dữ liệu. Trang đầu báo có phiên dở dang; tiếp tục request đó một lần. Luồng dừng ở `ScheduleMealClassificationException` trước lọc cá nhân hóa. Không lặp request và không thay đổi trạng thái duyệt.

## File code/docs đã sửa

- `lib/app_versions/v1/services/ai/generated_plan_service.dart` - trạng thái, callback progress, kiểm tra nhãn và log đếm an toàn.
- `lib/shared/widgets/generated_plan_progress_panel.dart` - trạng thái chờ/lọc/xong, số lượng, thông báo rỗng và tự mở nhóm đầu tiên có món.
- `lib/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart` - cập nhật progress trong luồng khôi phục.
- `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_entry_page.dart` - panel chung, tiếp tục món riêng chờ duyệt và thông báo lỗi phân loại.
- `test/app_versions/v1/features/onboarding/onboarding_schedule_progress_panel_test.dart` - trạng thái chưa lọc/đang lọc/rỗng/đủ món, tự mở nhóm và responsive.
- `test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart` - trạng thái callback, lọc rỗng với mục tiêu/sức khỏe và chặn AI khi phân loại không đạt.
- `test/app_versions/v1/features/meal_plan/meal_catalog_prefilter_test.dart` - số đếm tổng hợp từ catalog đóng gói.
- `docs/fixbug/filtered-meal-progress/001-fixbug-filtered-meal-progress.md` - nguyên nhân và kết quả kiểm chứng.

## Tài liệu liên quan

- Plan đã duyệt: sửa trạng thái và danh sách món sau lọc trên điện thoại.
- `.codex/workflows/bugfix.md`, `.codex/DOCS_WORKFLOW.md`.

## Commands

- `flutter test test/app_versions/v1/features/onboarding/onboarding_schedule_progress_panel_test.dart test/app_versions/v1/features/onboarding/onboarding_entry_page_test.dart test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart test/app_versions/v1/features/meal_plan/meal_catalog_prefilter_test.dart --reporter expanded`: PASS - toàn bộ test tập trung.
- `flutter analyze` trên các file code/test liên quan: PASS - không có vấn đề.
- `flutter build apk --debug`: PASS - build mới nhất.
- `adb install -r build/app/outputs/flutter-apk/app-debug.apk`: PASS - giữ nguyên dữ liệu ứng dụng.
- `flutter attach -d 12b304f9`: không tìm thấy VM service ở lần đầu; `flutter run -d 12b304f9` sau đó mở app debug và DTD `hot_reload`: PASS.
- Thao tác UI: tiếp tục phiên hiện có một lần; dừng vì lỗi phân loại, không gọi lại.
- `adb install -r build/app/outputs/flutter-apk/app-debug.apk`: PASS lần cuối; mở lại app tới trang đầu có nút tiếp tục phiên. Không bấm lại.
- `git diff --check`: PASS sau khi cập nhật docs và history.

## Lỗi/Rủi ro

- Đã sửa: panel không còn coi danh sách rỗng ban đầu là kết quả lọc; retry không còn ẩn panel và lỗi phân loại.
- Chưa sửa theo chủ ý fail-closed: catalog đóng gói có 3.163 lỗi nhãn theo validator; không thể hiển thị kết quả lọc trên điện thoại cho tới khi dữ liệu phân loại được xử lý.
- Cần kiểm tra tiếp: sau khi nhãn catalog hợp lệ, chạy một request mới theo sự đồng ý của người dùng để xác minh số sau lọc thực tế và tiến độ panel trên Android.

## Tỷ lệ hoàn thành

- Hoàn thành: trạng thái progress, UI, kiểm thử service/widget, log an toàn, build debug, cài giữ dữ liệu và một lần xác minh request hiện có.
- Chưa hoàn tất nghiệm thu đầu-cuối trên điện thoại: chốt phân loại dừng trước bộ lọc và AI theo đúng chính sách đã duyệt.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - trạng thái không gây hiểu nhầm; fail-closed giữ nguyên; lỗi phân loại được nhìn thấy.
- Muc do hoan thanh task: code và kiểm thử hoàn tất; danh sách lọc thực tế chưa thể hiện trên điện thoại do catalog không qua preflight.
- Bang chung kiem chung: focused Flutter tests, targeted analyzer, APK debug, adb install -r, hot reload và một lần tiếp tục request đang dở.
- Diem ton token/chua toi uu: màn hình sau cài lại mở trang có phiên chưa hoàn tất thay vì bước review dự kiến; phải theo resume CTA để không tạo request trùng.
- Cach toi uu cho phien sau: giải quyết nhãn catalog trước, sau đó thử bằng hồ sơ tổng hợp và request mới có chủ đích.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`.
