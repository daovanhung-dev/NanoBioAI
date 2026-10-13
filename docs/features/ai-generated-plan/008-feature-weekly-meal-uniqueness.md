Commit de xuat: feat(ai): khong lap mon trong lich an mot tuan

# Không lặp món trong lịch ăn một tuần

## Yêu cầu

Trong một lịch 7 ngày, 35 bữa phải dùng món khác nhau. Mã catalog và tên món đã xuất hiện đều được xem là đã dùng; đổi mã nhưng giữ nguyên tên món vẫn là trùng.

## Hành vi

- `MealPlanAiNormalizer` từ chối mã hoặc tên món đã dùng trong các ngày trước, trong cùng ngày, hoặc trong phần lịch đang được kiểm tra. Tên được chuẩn hóa bằng cách trim, chuyển chữ thường và gộp khoảng trắng; tên rỗng bị từ chối vì không thể bảo đảm tính duy nhất.
- Prompt nhận cả số lần dùng mã và tên món đã dùng trước đó, rồi yêu cầu model tránh cả hai loại trùng.
- Fallback từng bữa kiểm tra mã và tên món đã dùng trước khi chọn ứng viên catalog đủ điều kiện. Fallback cả ngày cũng loại mã và tên món đã dùng xuyên tuần, đồng thời loại trùng giữa các slot của ngày đó.
- Nếu không còn đủ món catalog duy nhất và đủ điều kiện, generation dừng với lỗi có mã `meal_unique_candidates_unavailable`; không chèn lại món cũ.
- Phiên bản staging được tăng lên `personal_schedule_v8_weekly_meal_uniqueness`, để kết quả tạo dở theo quy tắc cũ không được tiếp tục dùng.
- Nếu dùng local fallback, nguồn của toàn lịch vẫn là `local_fallback` và lịch được phân loại là gợi ý cơ bản. Member không bị commit quota tạo lịch cho kết quả fallback.

## Phạm vi

Quy tắc áp dụng cho các lịch AI mới trong khoảng ngày của request. Luồng thay món thủ công hiện có không thuộc thay đổi này. Ngày đã lưu trước đó vẫn được giữ để request có thể tiếp tục sau khi điều kiện lỗi được xử lý.

## Kiểm chứng

- `dart format` trên các file Dart đã sửa: PASS.
- Analyzer cho 4 file nguồn M02: PASS, `No errors`.
- Hot reload app Flutter đang kết nối: PASS; không mở luồng tạo lịch hoặc gửi request AI.
- `git diff --check`: PASS; worklog history refresh: PASS.
- `validate_codex_integrity.ps1`: FAIL do thiếu `docs/audit/source_truth_manifest.json` và stale path trong các history/skill cũ; không có lỗi mới được báo cho tài liệu vừa thêm.
- Source review: normalizer, prompt, fallback từng slot, fallback cả ngày, staging version và error mapping đều dùng cùng chính sách không lặp mã/tên.
- Test suite, Gemini thật và Supabase sandbox: chưa chạy trong phiên này.
- Hot reload chứng minh Dart code được nạp vào app đang chạy; không phải QA chấp nhận tạo lịch trên thiết bị.

## Tài liệu liên quan

- M02: `docs/checklist/checklist_complete_DD.md`.
- Handoff coding: `docs/checklist/checklist_task_coding.md`.
- Worklog: `docs/worklog/2026-10-13/011-worklog-weekly-meal-uniqueness.md`.
