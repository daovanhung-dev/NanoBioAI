Commit de xuat: fix(onboarding): hien ro trang thai loc mon

# Fixbug: Trạng thái và danh sách món sau lọc

## Triệu chứng

- Panel tiến độ khởi tạo danh sách món rỗng trước khi bộ lọc chạy nên có thể báo `0 món` quá sớm.
- Khi có món, cả nhóm buổi và nhóm chính/phụ đều thu gọn nên tên món không xuất hiện ngay.
- Luồng tiếp tục phiên onboarding không gửi callback tiến độ tới panel và thay lỗi phân loại catalog bằng thông báo chung.

## Nguyên nhân đã xác nhận

- `GeneratedPlanProgress` không phân biệt danh sách chưa được lọc, đang lọc và đã lọc xong.
- Luồng member kiểm tra phân loại trước quota nhưng chưa phát trạng thái tiến độ trong bước preflight.
- Luồng khôi phục onboarding gọi tạo lịch không kèm progress panel.
- Kiểm thử catalog đóng gói cho thấy 3.163 món đầu vào, 3.113 món có thể được quy tắc hiện tại xếp nhóm khi phân loại tại chỗ, và 3.163 lỗi nhãn trong phép kiểm tra nghiêm. Không sửa nhãn, nguồn hoặc trạng thái duyệt để vượt qua chốt này.

## Đã sửa

- Bổ sung trạng thái lọc và tổng số món catalog vào progress bất biến.
- Phát trạng thái đang lọc trước bước tải/kiểm tra catalog; chỉ phát hoàn tất cùng số món sau khi bộ lọc trả về, trước lời gọi AI đầu tiên.
- Hiển thị `số còn lại / tổng catalog`, tránh số 0 khi chưa có kết quả và giải thích rõ khi bộ lọc hoàn tất nhưng rỗng.
- Tự mở buổi và loại bữa đầu tiên có món; nhóm còn lại vẫn có thể mở thủ công.
- Log tổng hợp số lượng catalog, kết quả lọc và lỗi nhãn; không ghi mã/tên món, hồ sơ, prompt hoặc nội dung AI.
- Luồng khôi phục onboarding dùng cùng panel tiến độ, giữ món riêng ở bước duyệt và hiện lỗi phân loại thay vì chỉ báo thất bại chung.

## Kết quả trên điện thoại

- Cài APK debug bằng `adb install -r`, giữ nguyên dữ liệu ứng dụng.
- Trang đầu hiển thị một phiên chưa hoàn tất. Đã bấm nút tiếp tục đúng một lần để dùng lại request đã lưu; không tạo request mới và không bấm thử lại lần hai.
- Lần tiếp tục dừng ở `ScheduleMealClassificationException` trước khi bộ lọc cá nhân hóa chạy. Vì vậy điện thoại chưa có kết quả `0 / 3.163` để hiển thị. Chốt fail-closed được giữ nguyên và không có căn cứ để bật món chưa xác minh.
- Catalog chỉ có thể hiện danh sách sau khi nhãn phân loại đủ điều kiện được sửa/duyệt theo chính sách hiện tại. Không xác nhận inference hoặc lưu lịch trên lần chạy này.

## Kiểm chứng

- `flutter test test/app_versions/v1/features/onboarding/onboarding_schedule_progress_panel_test.dart test/app_versions/v1/features/onboarding/onboarding_entry_page_test.dart test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart test/app_versions/v1/features/meal_plan/meal_catalog_prefilter_test.dart --reporter expanded`: PASS.
- `flutter analyze` trên service, panel, onboarding controller/page và test liên quan: PASS, không có vấn đề.
- `flutter build apk --debug`: PASS; build mới nhất được ghi nhận trong worklog.
- `adb install -r`: PASS, dữ liệu ứng dụng được giữ nguyên.
- Hot reload trên ứng dụng debug: PASS.

## Giới hạn

Danh sách sau lọc không được hiển thị trên điện thoại ở lần xác minh này vì kiểm tra nhãn đã dừng luồng trước bước lọc. Cần xử lý dữ liệu phân loại trước khi kiểm tra trạng thái 0 món trên thiết bị; không nới quy tắc bằng cách tự xác nhận dinh dưỡng, sức khỏe hay dị ứng.
