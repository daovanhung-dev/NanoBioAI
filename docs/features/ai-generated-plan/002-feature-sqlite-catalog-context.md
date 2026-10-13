Commit đề xuất: feat(ai): dùng catalog SQLite khi tạo lịch cá nhân

# Catalog SQLite cho lịch trình AI

## Mục tiêu

- Dùng nội dung catalog món ăn và bài tập từ SQLite làm ngữ cảnh để AI lựa chọn.
- Giữ mã catalog làm đầu ra của AI; ứng dụng xác thực mã và nạp bản ghi chuẩn để tạo lịch.

## Nguồn dữ liệu

- Danh mục 163 món được nạp từ `assets/data/meal_catalog_v1.json` khi tạo SQLite mới và khi nâng cấp bằng migration v29.
- Seeder kiểm tra số lượng, mã duy nhất, `source_hash` và dữ liệu đã ghi trong SQLite.
- Mọi catalog update sau này cần cập nhật asset cùng migration phát hành tương ứng.
- App không đọc/làm mới `meal_catalog` từ Supabase lúc chạy. Bảng Supabase được giữ làm bản dự phòng; đồng bộ kế hoạch và nhật ký dinh dưỡng cá nhân không đổi.

## Ngữ cảnh gửi cho AI

- Món ăn: mã, loại, tên, nguyên liệu, khẩu phần, dinh dưỡng, chủ đề sức khỏe, nhãn dị ứng/điều kiện cần tránh và trạng thái dữ liệu.
- Bài tập: mã, nhóm, tên, mô tả, đơn vị, cường độ và giới hạn/mục tiêu.
- Hồ sơ gửi kèm có mục tiêu, tình trạng sức khỏe và dữ liệu dị ứng người dùng để đối chiếu với catalog.
- Chỉ gửi các mục đang hoạt động. Món `unclassified` và `is_plan_eligible=false` vẫn được gửi theo lựa chọn sản phẩm.
- Số liệu ước tính và metadata chưa rà soát phải được nhận diện là chưa xác minh; prompt không yêu cầu AI tuyên bố an toàn y khoa.
- Schema kết quả vẫn dùng `meal_code`/`exercise_code`; normalizer xác thực và nạp dữ liệu từ catalog SQLite.

## Kiểm chứng

- Migration v29 thay thế catalog cũ bằng 163 bản ghi từ asset và giữ nguyên ánh xạ mã/hash.
- Unit/contract tests xác nhận seed trên cài mới/nâng cấp, prompt chỉ gửi mục hoạt động, và AI không được gọi khi thiếu catalog món.
- Kiểm tra không còn đường làm mới catalog món từ Supabase trong khởi động, onboarding hoặc tạo lịch bổ sung.
