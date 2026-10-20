Commit de xuat: fix(meal-plan): phan loai mon tai cho va hien du ung vien

# Fixbug: Catalog món chưa được phân loại tại chỗ

## Triệu chứng

- Trên Android, preflight báo cả 3.163 món đủ điều kiện bị phân loại sai hoặc thiếu, nên dừng trước khi danh sách sau lọc xuất hiện.
- Catalog nguồn lưu `meal_type=unclassified`; panel bị chặn dù nhiều tên món có thể được xếp nhóm bằng quy tắc cục bộ.
- Hồ sơ có mục tiêu hoặc lưu ý sức khỏe có thể nhận 0 lựa chọn cá nhân hóa vì catalog chưa có bằng chứng dinh dưỡng/sức khỏe đã xác minh.

## Nguyên nhân đã xác nhận

- Validator chỉ nhìn nhãn `meal_type` lưu trong catalog và chưa chấp nhận phân loại xác định được từ tên/nguyên liệu.
- Catalog 3.163 dòng gồm 163 món nguồn nhập cũ và 3.000 ứng viên riêng đang chờ rà soát. Ứng viên không được đánh dấu đã duyệt, không có dinh dưỡng xác minh và không đủ bằng chứng để cá nhân hóa theo bệnh lý.
- Một số tên trùng hoặc không đủ dấu hiệu xác định nhóm cần được bỏ khỏi tập gửi AI thay vì gán nhãn tùy tiện.

## Đã sửa

- Cho phép bộ phân loại Dart suy luận buổi và loại bữa tại chỗ cho nhãn `unclassified`; không ghi đè nhãn nguồn. Loại tên mơ hồ, giữ lỗi cho nhãn rõ ràng nhưng không hỗ trợ.
- Khử trùng lặp theo mã và tên trước khi tạo danh sách. Khi số lựa chọn cá nhân hóa dưới 50 cho một khung thời gian, dùng quy tắc wellness chung trong cùng khung để tăng độ phủ; không dùng chúng làm bằng chứng y tế.
- Món có dị ứng/món cần tránh vẫn cần bằng chứng an toàn phù hợp; dữ liệu không xác minh tiếp tục bị loại. Nếu số lượng còn thiếu ngưỡng, dừng trước quota và lời gọi AI.
- Khi dùng gợi ý wellness chung, loại mục tiêu và tình trạng sức khỏe khỏi phần cá nhân hóa món gửi cho AI. Tiến độ ghi tổng hợp số đầu vào, số còn lại và số theo khung; không ghi mã/tên món hay hồ sơ.
- Panel thể hiện rõ gợi ý chung chưa xác minh mức phù hợp dinh dưỡng/sức khỏe.

## Kiểm chứng dữ liệu cục bộ

- Catalog đầu vào: 3.163.
- Xếp được nhóm theo quy tắc tại chỗ, bỏ mã/tên trùng và tên mơ hồ: 3.113.
- Với hồ sơ tổng hợp có mục tiêu sức khỏe tim mạch và các lưu ý tiêu hóa, sau khi áp dụng gợi ý wellness chung: Sáng 680, Trưa 597, Chiều/Tối 1.836; mỗi khung vượt ngưỡng 50.
- Đây là kết quả của quy tắc cục bộ trên bundle hiện tại, không phải xác minh lâm sàng hay thay đổi trạng thái duyệt của catalog.

## Kiểm thử

- `flutter test test/app_versions/v1/features/meal_plan/meal_catalog_prefilter_test.dart test/app_versions/v1/features/meal_plan/meal_candidate_selector_test.dart test/app_versions/v1/features/onboarding/onboarding_schedule_progress_panel_test.dart test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart test/app_versions/v1/features/onboarding/onboarding_entry_page_test.dart --reporter compact`: PASS, 55/55.
- `flutter test test/app_versions/v1/features/meal_plan/meal_catalog_prefilter_test.dart --plain-name 'filters the complete bundled 3,163-meal catalog locally' --reporter expanded`: PASS; xác nhận số lượng chính xác theo ba khung.
- Phân tích tĩnh các service, prefilter, UI và test liên quan: PASS, không có lỗi.
- `flutter build apk --debug`: PASS.

## Xác minh trên điện thoại

- Thiết bị `220333QPG`, Android 11. Sau khi người dùng cho phép cài qua USB, `adb install -r` hoàn tất thành công và giữ nguyên dữ liệu ứng dụng.
- Màn hình khởi động có phiên chưa hoàn tất. Đã chọn **Thử lại phiên gần nhất** đúng một lần để tiếp tục request đó, không tạo request/lịch thứ hai.
- Panel chuyển từ trạng thái đang kiểm tra sang kết quả trước khi có sự kiện nào được lưu: **3.113/3.163 món**, Sáng **680**, Trưa **597**, Chiều/Tối **1.836**. Cả ba khung đều lớn hơn ngưỡng 50; danh sách đã qua lọc hiển thị trên điện thoại thay cho lỗi phân loại 3.163 món.
- Tiến độ lúc quan sát là `0/77` sự kiện, giai đoạn sắp xếp lịch. Khi thử cuộn trong lúc AI cục bộ đang chạy, Android 11 hiện hộp thoại **Nabi không phản hồi**. Chọn **Đợi** giữ ứng dụng và request sống; đây là giới hạn nghiệm thu tương tác trong lúc suy luận, không làm thay đổi số đếm đã hiện. Chưa xác nhận tên món khi cuộn hoặc lịch hoàn chỉnh được lưu.

## Giới hạn

- Các ứng viên wellness 3.000 món vẫn ở trạng thái chưa duyệt. Chúng chỉ có thể dùng làm gợi ý chung, không khẳng định phù hợp bệnh lý hay dinh dưỡng cá nhân.
- Hồ sơ có dị ứng hoặc món cần tránh mà catalog chưa có bằng chứng xác minh có thể còn dưới 50 món ở một khung; luồng giữ fail-closed thay vì nới bộ lọc.
- Số đếm và trạng thái lọc đã được xác nhận trực tiếp trên thiết bị với request đang lưu. Việc cuộn danh sách và hoàn tất 77 sự kiện chưa được xác nhận vì thiết bị báo ứng dụng không phản hồi trong lúc suy luận cục bộ.
