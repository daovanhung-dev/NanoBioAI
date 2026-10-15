Commit de xuat: docs(dd): ghi nhan delta hang EXP nhiem vu

# Implementation Delta 2026-10-15 — Hạng EXP nhiệm vụ

## Phạm vi và truy vết

Delta được thêm vào M03 `DASHBOARD_SCHEDULE` và M08 `HEALTH_SCORE_HABITS`, dựa trên `BD-BIOAI-WELLNESS-RANK-EXPERIENCE-001` v1.0 và bằng chứng lịch trình hoàn tất của M03. Delta triển khai hạng cá nhân bằng EXP từ server-confirmed task evidence.

## Hợp đồng nghiệp vụ

- Mỗi schedule item được server xác nhận active cộng 10 EXP một lần; undo bằng chứng cuối cùng đang active thu hồi tối đa 10 EXP.
- Mốc tuần đầu tiên bắt đầu ở lần cộng EXP server đầu tiên. Mỗi 7 ngày trừ 100 EXP, tối thiểu 0; các kỳ đến hạn xử lý tuần tự và có event key duy nhất.
- Hạng lấy từ EXP hiện tại: 0 / 600 / 1.200 / 2.600 / 5.200 cho hạng 1–5. Mã rank ổn định `wellness_rank_1`…`wellness_rank_5` và title được trả từ RPC.
- FamilyPlus gộp nhiệm vụ theo tài khoản người thao tác qua các subject được phép. Không có RPC nhận `user_id`; `get_my_wellness_rank_summary()` chỉ xác định tài khoản từ `auth.uid()`.
- EXP tách biệt Health Score, Điểm chăm sóc, điểm đổi quà và Điểm Sale. V1 không thay đổi quyền đổi quà.

## Thiết kế kỹ thuật

Supabase lưu account snapshot, ledger bất biến và trạng thái tác vụ để tuần tự hóa award/undo. Trigger theo dõi `schedule_completion_proofs` và `schedule_health_checkins`; helper hợp nhất active evidence theo `(user_id, schedule_item_id)` để không cộng hai lần khi cùng nhiệm vụ có nhiều nguồn. RPC đọc summary xử lý các kỳ decay đến hạn trước khi trả dữ liệu.

SQLite v33 thêm `wellness_rank_summary_cache`, khóa theo `user_id`. Repository tải RPC trước; khi mạng hoặc RPC lỗi, dùng snapshot cùng `synced_at` nếu có. Dashboard và Settings dùng chung model/provider/card. Khách thấy lời mời đăng nhập; hạng 5 hiển thị trạng thái tối đa.

## Trạng thái bằng chứng

- Targeted Flutter tests/analyze/format và PostgreSQL 17 disposable migration smoke được ghi ở worklog ngày 2026-10-15; hot restart trên app đang kết nối cũng thành công.
- Migration forward và canonical rebuild SQL được đồng bộ trong repository.
- SQLite v32→v33 tests pass bằng thư viện native giải nén tạm trong `/tmp`. Supabase sandbox/production và tương tác UI trên thiết bị chưa được xác minh; không xem migration SQL là bằng chứng đã triển khai lên backend.
- Điều kiện lọc/đổi quà theo hạng thuộc giai đoạn sau.
