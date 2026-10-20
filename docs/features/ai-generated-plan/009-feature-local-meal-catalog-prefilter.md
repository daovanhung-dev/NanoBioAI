Commit de xuat: feat(ai): loc mon cuc bo truoc khi tao lich

# Lọc món cục bộ trước khi tạo lịch

## Mục tiêu

Giảm danh sách cần xét cho lịch cá nhân bằng quy tắc Dart chạy trên catalog cục bộ trước lượt AI đầu tiên. Màn chờ cho người dùng xem toàn bộ món qua bộ lọc; shortlist theo giới hạn ngữ cảnh vẫn được tạo riêng cho từng lượt AI.

## Phân loại và lọc

- Giữ nguyên các cờ duyệt nguồn, `is_plan_eligible` và trạng thái dinh dưỡng/dị ứng hiện có. Tên và nguyên liệu chỉ dùng để suy đoán nhóm bữa; không biến suy đoán thành metadata đã xác minh.
- Ưu tiên loại bữa có sẵn. Với món `unclassified`, áp dụng quy tắc hữu hạn theo tên/nguyên liệu; món không đủ dấu hiệu được loại.
- Ánh xạ năm suất: bữa sáng và phụ sáng vào **Sáng**; bữa trưa vào **Trưa**; phụ chiều và bữa tối vào **Chiều/Tối**. Sáng, trưa, tối là món **Chính**; hai bữa phụ là món **Phụ**.
- Loại món xung đột với hồ sơ dị ứng, món cần tránh, tình trạng sức khỏe hoặc mục tiêu đang hoạt động. Khi hồ sơ có ràng buộc liên quan mà bằng chứng món chưa xác minh, món bị loại. Không dùng dinh dưỡng ước tính làm bằng chứng.
- Khử trùng mã và tên chuẩn hóa để không đưa các món trùng vào danh sách. Nếu một trong năm suất không đủ số món độc nhất cho số ngày cần tạo, dừng trước AI và trước khi lưu/commit quota.

## Tiến độ và giao diện

- `GeneratedPlanProgress` mang danh sách bất biến gồm mã, tên, loại suất, nhóm thời gian và vai trò bữa. Dịch vụ phát danh sách sau lọc trước lượt AI đầu tiên; giới hạn token tiếp tục được áp dụng sau đó.
- Onboarding và tạo thêm lịch dùng chung panel trong màn chờ. Panel nêu tổng số món và việc AI có thể dùng shortlist nhỏ hơn, nhóm theo thời gian rồi theo Chính/Phụ, và dùng danh sách cuộn tải lười.
- Nếu thiếu món, giao diện nhận thông báo thân thiện; lịch đang có được giữ nguyên và yêu cầu bị dừng không gọi AI hoặc commit quota.

## Đo trên catalog hiện tại

Với hồ sơ rỗng, bộ lọc đọc 3.163 món từ hai asset; 3.113 món còn lại sau khi bỏ món trùng/không phân loại rõ:

| Suất | Món còn lại |
|---|---:|
| Sáng — Chính | 639 |
| Sáng — Phụ | 41 |
| Trưa — Chính | 597 |
| Chiều/Tối — Phụ | 89 |
| Chiều/Tối — Chính | 1.747 |

Đây là phân loại theo quy tắc tên/nhãn, không phải xác nhận chuyên môn. Số lượng thực tế thay đổi theo hồ sơ. Catalog mới vẫn chưa được duyệt quyền phân phối hoặc xác minh công thức, dinh dưỡng và dị ứng; không dùng kết quả này để khẳng định an toàn y khoa.

## Kiểm chứng và giới hạn

- Test trên toàn bộ asset: 3.163 món vào, 3.113 món được giữ cho hồ sơ rỗng; từng suất đủ món duy nhất cho lịch 7 ngày.
- Test selector/prompt/service: các ràng buộc chưa xác minh bị loại; thiếu ứng viên dừng trước AI và commit; callback có preview; panel bao phủ danh sách rỗng và màn hình rộng 360 logical px.
- Analyzer, hot reload và kết quả kiểm tra runtime cụ thể được ghi trong worklog cùng ngày.
- Chưa xác minh inference trên thiết bị Android hoặc quota trong Supabase sandbox.

## Tài liệu liên quan

- M02: `docs/checklist/checklist_complete_DD.md`.
- Handoff: `docs/checklist/checklist_task_coding.md`.
- Worklog: `docs/worklog/2026-10-18/004-worklog-local-meal-catalog-prefilter.md`.
