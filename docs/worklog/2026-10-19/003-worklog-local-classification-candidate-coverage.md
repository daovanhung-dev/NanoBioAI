Commit de xuat: docs(worklog): ghi nhan phan loai va do phu mon

# Worklog - Phân loại món tại chỗ và độ phủ danh sách

## Phạm vi

- Module chính: `MealCatalogPrefilter`, `MealCandidateSelector`, `GeneratedPlanService`, panel tiến độ tạo lịch.
- Mục tiêu: loại bỏ lỗi cả catalog 3.163 món bị chặn do nhãn `unclassified`, hiển thị số món sau lọc và có tối thiểu 50 gợi ý cho mỗi khung khi không vướng ràng buộc an toàn bắt buộc.
- Giữ nguyên dữ liệu duyệt, dinh dưỡng, sức khỏe và dị ứng; không ghi mã/tên món hoặc hồ sơ vào log.

## Đã làm

- Suy luận nhãn buổi/loại bữa bằng quy tắc cố định từ tên và nguyên liệu, chỉ chạy tại chỗ; bỏ tên mơ hồ và không sửa dữ liệu nguồn.
- Bổ sung gợi ý wellness chung khi kết quả cá nhân hóa dưới ngưỡng 50/khung; giữ chốt dị ứng/món cần tránh và không gửi mục tiêu sức khỏe vào lời nhắc món khi có dùng gợi ý chung.
- Đưa tổng số sau lọc và số lượng mỗi khung vào tiến độ/log an toàn; panel cảnh báo rõ dữ liệu ứng viên chưa được xác minh chuyên môn.
- Điều chỉnh test món riêng để dùng ngưỡng tối thiểu bằng 0 trong fixture rỗng, giữ kiểm chứng luồng món riêng chờ duyệt bên cạnh chốt ngưỡng 50 mặc định ở production.

## Kết quả

- Catalog: 3.163 đầu vào, 3.113 giữ lại sau phân loại/loại trùng và mơ hồ.
- Hồ sơ tổng hợp: Sáng 680, Trưa 597, Chiều/Tối 1.836; kiểm thử xác nhận từng khung đạt ít nhất 50.
- Trên điện thoại Android 11 sau `adb install -r` thành công: tiếp tục phiên chưa hoàn tất đúng một lần; panel thực tế hiển thị 3.113/3.163 món và cùng số lượng theo khung là 680/597/1.836 trước sự kiện lưu đầu tiên.
- Targeted tests: PASS, 55/55.
- Phân tích tĩnh: PASS, không có lỗi.
- Debug APK: build thành công.
- Trong lúc suy luận sau khi panel đã hiện kết quả, Android báo `Nabi không phản hồi` khi thử cuộn; chọn `Đợi` để không hủy request. Số lượng lọc đã xác nhận, nhưng chưa xác nhận cuộn tới tên món hoặc hoàn tất lịch 77 sự kiện.

## File trong phạm vi

- `lib/app_versions/v1/features/meal_plan/domain/services/meal_catalog_prefilter.dart`
- `lib/app_versions/v1/features/meal_plan/domain/services/meal_candidate_selector.dart`
- `lib/app_versions/v1/services/ai/generated_plan_service.dart`
- `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_entry_page.dart`
- `lib/app_versions/v1/features/onboarding/presentation/widgets/onboarding_schedule_progress_panel.dart`
- `test/app_versions/v1/features/meal_plan/meal_catalog_prefilter_test.dart`
- `test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart`
- `test/app_versions/v1/features/onboarding/onboarding_schedule_progress_panel_test.dart`
- `docs/fixbug/filtered-meal-progress/002-fixbug-local-classification-and-candidate-coverage.md`

## Bước còn lại

- Nếu xử lý tiếp ANR trong lúc chạy Qwen, cần lấy lại stack trace/runtime evidence và tách thành task hiệu năng riêng; không nới ngưỡng lọc để né lỗi này.

## Lệnh đã chạy

- `flutter test test/app_versions/v1/features/meal_plan/meal_catalog_prefilter_test.dart test/app_versions/v1/features/meal_plan/meal_candidate_selector_test.dart test/app_versions/v1/features/onboarding/onboarding_schedule_progress_panel_test.dart test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart test/app_versions/v1/features/onboarding/onboarding_entry_page_test.dart --reporter compact`: PASS.
- `flutter test test/app_versions/v1/features/meal_plan/meal_catalog_prefilter_test.dart --plain-name 'filters the complete bundled 3,163-meal catalog locally' --reporter expanded`: PASS.
- MCP Dart analyzer trên các file liên quan: PASS, không lỗi.
- `flutter build apk --debug`: PASS.
- `adb install -r build/app/outputs/flutter-apk/app-debug.apk`: PASS sau khi người dùng cho phép cài USB; dữ liệu ứng dụng được giữ.
- Thiết bị: khôi phục request dở dang một lần; xác nhận panel lọc hiển thị 3.113/3.163 món và Sáng 680, Trưa 597, Chiều/Tối 1.836.
