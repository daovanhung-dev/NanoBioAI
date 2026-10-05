# List Features — M32 / Chế độ luyện tập

## Feature inventory

| ID | Feature | Actor | Trigger | Priority | Functions | Views | Decision |
|---|---|---|---|---|---|---|---|
| M32-F01 | Xác minh người trưởng thành và intake | Guest/Member | Mở chế độ | P0 | FN01 | V01-V02 | Draft; pilot code present |
| M32-F02 | Catalog và chọn môi trường/nguồn thực phẩm | Guest/Member | Sau review profile | P0 | FN02 | V03-V04 | Draft; pilot code present |
| M32-F03 | Tạo, xem trước, áp chương trình 4 tuần | Guest/Member | Submit intake | P0 | FN03-FN04 | V05-V06 | Draft; pilot code present |
| M32-F04 | Check-in và điều chỉnh tuần còn lại | Guest/Member | Cuối mỗi tuần | P1 | FN05 | V07 | Draft; pilot code present; Guest replan unavailable |

## M32-F01 — Xác minh tuổi và intake

Người dùng rà soát hồ sơ onboarding. Pilot tính tuổi trên thiết bị từ ngày sinh đầy đủ tự khai; thiếu DOB, DOB tương lai hoặc dưới 18 tuổi bị chặn trước quota/AI. Đây có thể bị giả mạo, không phải proof tin cậy. DOB không được serialize vào Gemini; Tech/Privacy cần duyệt cách xác minh, consent, residency, retention và xóa trước phát hành.

Acceptance: profile is visible for review and confirmation; DOB can be entered/changed locally; missing/future/under-18 date is blocked; DOB is excluded from Gemini payload; consent and offline/error states have clear handling. Server-trusted age proof remains a release review item.

## M32-F02 — Catalog và lựa chọn

Cho chọn Gym hoặc home. Gym hiển thị 10 equipment cards có hình gốc; home dùng danh sách bài tập home-compatible. Chọn nhóm thực phẩm: protein, carbohydrate, vegetables/fruit, fat sources; thiết lập allergy/diet and meal windows. Catalog pilot: 24 exercises, 10 equipment, 35 recipes, 47 ingredient candidates.

Acceptance: catalog có metadata và provenance; pilot có 24 bài tập, 10 thiết bị, 35 món ăn và 47 ứng viên nguyên liệu; bài tập/recipe chỉ xuất hiện khi qua filters; không kết quả phù hợp thì dừng thay vì AI invent.

## M32-F03 — Generate, preview, apply

Sau kiểm tra quota, backend Gemini chọn các ID đã lọc và lập tuần 1-4; metric M04 được tính cục bộ. Lưu full program; preview 28 ngày; apply tuần hiện tại vào lịch 7 ngày chỉ sau confirm. Guest dùng atomic one-time initial-plan rule; Member dùng existing M02 check/commit gateway.

Acceptance: sai schema/ID/restriction không ghi program/schedule và không commit quota; transaction chỉ thay task tập/ăn/ngủ tương lai chưa hoàn thành.

## M32-F04 — Weekly check-in/replan

Cuối tuần hỏi mức gắng sức và đau mỏi (1–5). Replan phần tuần còn lại dùng một quota M02, preview và confirm; nếu skip hoặc quota denied thì giữ kế hoạch đã lưu. Guest không được replan sau lượt tạo ban đầu.

Acceptance: không tự đổi lịch khi chưa confirm; program version tăng một lần; lịch cũ còn nguyên khi AI/write lỗi.

## Test inventory

| ID | Scenario |
|---|---|
| M32-TC01 | DOB cho tuổi 17, 18 và ngày sinh trong năm hiện tại |
| M32-TC02 | DOB không có trong Gemini intake payload; thiếu, tương lai hoặc dưới-18 DOB bị local pilot age gate từ chối |
| M32-TC03 | Home filter chỉ trả home-compatible movements |
| M32-TC04 | Gym filter giới hạn gear đã chọn |
| M32-TC05 | Allergy/restriction và catalog rỗng |
| M32-TC06 | Guest one-time và Member quota M02; Plus/Family entitlement remains pending acceptance review |
| M32-TC07 | Invalid JSON, unknown catalog ID, out-of-range workout/nutrition |
| M32-TC08 | Gemini/network failure, retry và idempotency |
| M32-TC09 | Preview cancel không ghi program hoặc schedule |
| M32-TC10 | Apply tuần giữ completed và unrelated health tasks |
| M32-TC11 | DB transaction failure rollback và notification reschedule |
| M32-TC12 | Weekly check-in consumes quota; quota denied preserves active plan |
| M32-TC13 | Confirm replan only applies remaining/current week |
| M32-TC14 | YouTube private/embedding disabled/unavailable fallback |
| M32-TC15 | Catalog provenance, source IDs, required content counts and asset review status |
| M32-TC16 | Android/iOS accessibility, text scale, screen reader, IFrame availability and YouTube fallback smoke |
