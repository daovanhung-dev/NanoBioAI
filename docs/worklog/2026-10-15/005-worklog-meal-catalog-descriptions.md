Commit de xuat: docs(worklog): ghi nhan cap nhat mo ta mon an

# Worklog - Mô tả dinh dưỡng cho danh mục món ăn

## Thời gian

- Ngày: 2026-10-15
- Bắt đầu: khoảng 21:20
- Kết thúc: 22:30
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: coding
- Module chính: meal catalog, meal plan prompt, SQLite v35.
- Yêu cầu gốc: nghiên cứu nguồn web và cập nhật description cho 163 mã món; ghi form nghiên cứu theo mã; dùng tóm tắt trong ngữ cảnh AI và hiển thị nội dung chi tiết an toàn.
- Ranh giới: chỉ sửa trường description; giữ nguyên benefits, thẻ bệnh/dị ứng, dữ liệu dinh dưỡng, trạng thái duyệt, cờ đủ điều kiện, cloud/API và schema bảng.

## Đã làm

- Thay mô tả cũ gắn lợi ích bệnh lý bằng tóm tắt thành phần/dinh dưỡng và phần giải thích nguyên liệu, cách chế biến cùng giới hạn chứng cứ. Mô tả không suy ra số liệu hoặc khẩu phần và không gán khả năng điều trị/cải thiện bệnh cho món riêng lẻ.
- Tạo form CSV đủ 163 mã, có tên món, thẻ bệnh cũ, nguyên liệu, mô tả cũ/mới, câu tóm tắt AI, cơ sở dinh dưỡng, giới hạn khẳng định sức khỏe, nguồn và ngày truy cập.
- Cập nhật prompt lịch để chỉ đưa câu tóm tắt đầu tiên của description vào catalog AI.
- Mở hiển thị description mới ở chi tiết món; các trường topic, benefits, avoid-condition, nguồn và dinh dưỡng vẫn theo cổng duyệt hiện tại.
- Thêm SQLite migration v34→v35, xác thực 163 mã và chỉ cập nhật cột description. Không gọi seeder, không thay schema/API/cloud và không bật is_plan_eligible.
- Đồng bộ snapshot phiên bản SQLite trong `.codex/AGENTS.md` và `.codex/domains/sqlite.md` lên v35.

## File code/docs đã sửa

- `assets/data/meal_catalog_v1.json` - cập nhật duy nhất `description` của 163 bản ghi.
- `docs/meal_catalog/meal_description_research_v1.csv` - tạo form truy nguyên theo mã món.
- `lib/core/storage/localdb/seeders/source_meal_catalog_loader.dart` - thêm bộ đọc map mã → description đã kiểm tra trùng/missing.
- `lib/core/storage/localdb/migrations/migration_v35.dart` - migration chỉ update description và kiểm tra đủ mã.
- `lib/core/storage/localdb/database_service.dart`, `lib/core/storage/localdb/database_version.dart` - nối migration và bump phiên bản SQLite.
- `lib/app_versions/v1/services/ai/prompts/meal_plan_prompt.dart` - thêm summary dinh dưỡng vào catalog prompt.
- `lib/app_versions/v1/features/meal_plan/presentation/utils/meal_detail_content_formatter.dart` - hiển thị description đã biên tập, giữ cổng các claim khác.
- `.codex/AGENTS.md`, `.codex/domains/sqlite.md` - cập nhật snapshot phiên bản.
- `docs/worklog/2026-10-15/005-worklog-meal-catalog-descriptions.md` - ghi lại phạm vi và bằng chứng phiên này.

## Tài liệu liên quan

- USDA FoodData Central mô tả cơ sở dữ liệu thành phần thực phẩm; liên kết tra cứu trong CSV chỉ làm căn cứ tham khảo cho nguyên liệu, không được dùng để suy ra lượng trên một khẩu phần công thức.
- WHO Healthy diet hướng dẫn mô hình ăn uống tổng thể, không chứng minh hiệu quả bệnh lý của một món riêng.
- NIH ODS được dùng có chọn lọc cho vai trò sắt heme, vitamin C, carotenoid/vitamin A, kẽm và omega-3; NCCIH được dùng cho cảnh báo nha đam, cam thảo và tương tác nhân sâm.

## Commands

- `dart format` trên 6 tệp Dart đã sửa: PASS - không còn thay đổi định dạng.
- Dart MCP `analyze_files` trên 6 tệp Dart đã sửa: PASS - không có lỗi.
- Kiểm tra JSON/CSV theo mã: PASS - đủ 163 mã duy nhất và mô tả trong CSV khớp JSON.
- So sánh JSON với HEAD ngoài description: PASS - không thay đổi trường nào khác.
- DTD discovery: PASS - tìm được daemon; không có ứng dụng đang kết nối.
- Dart hot restart: BLOCKED - DTD không có app connection hoạt động.
- Kiểm tra SQLite v34→v35 trên DB/device: SKIPPED - chưa chạy ứng dụng; migration được kiểm tra tĩnh.
- Focused tests: SKIPPED - không chạy test suite trong task này.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`: PASS - cập nhật 19 file history/task-skill được sinh tự động.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: FAIL - thiếu `docs/audit/source_truth_manifest.json` và báo stale path ở history/task-skill cũ ngoài phạm vi.
- `git diff --check`: PASS.

## Lỗi/Rủi ro

- Đã fix: mô tả cũ dùng cùng một khẳng định bệnh cho nhiều món khác nguyên liệu; mô tả mới tách theo mã và loại nguyên liệu, không gán lợi ích bệnh lý chưa có chứng cứ.
- Chưa fix: chưa có khẩu phần/định lượng dinh dưỡng đáng tin cậy trong asset; mô tả nêu rõ giới hạn thay vì tự thêm số.
- Cần kiểm tra tiếp: migration trên DB SQLite thật và xác minh chi tiết món trên app đang chạy; môi trường hiện không có app kết nối DTD. Validator context cũng đang bị chặn bởi manifest thiếu và stale path có sẵn ở file ngoài phạm vi.

## Tỷ lệ hoàn thành

- Hoàn thành: cập nhật 163 mô tả và CSV; nối prompt, UI detail, migration v35 và context version; kiểm tra tĩnh mã nguồn/CSV/JSON.
- Đang đo: persistence/migration runtime và giao diện trên ứng dụng/device.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - mỗi mã có form truy nguồn, summary ngắn cho AI và mô tả chi tiết có giới hạn chứng cứ; không đụng eligibility.
- Mức độ hoàn thành task: hoàn tất source/docs; runtime SQLite và hot restart chưa xác minh do không có app kết nối.
- Bằng chứng kiểm chứng: targeted Dart analyzer pass; JSON/CSV đủ 163 mã; diff JSON ngoài description rỗng; các thao tác runtime chưa chạy.
- Điểm tốn token/chưa tối ưu: cần nhiều lượt rà ngữ nghĩa để loại nhầm tên nguyên liệu gần giống.
- Cách tối ưu cho phiên sau: bắt đầu bằng canonical alias map có ranh giới từ tiếng Việt và rà mẫu nguyên liệu hiếm trước khi sinh cả danh mục.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
