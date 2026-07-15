Commit de xuat: fix(schedule-ai): harden horizon routine completion and quota flow

# Fix logbug 14-7-26

## Triệu chứng

- Có thể tạo lịch mới khi lịch cũ còn nhiều ngày, hoặc hai thao tác đồng thời cùng gọi AI.
- Giờ ăn/tập/ngủ chưa có nguồn deterministic theo nhịp sinh hoạt người dùng.
- Biên đúng `+30 phút` bị khóa và camera có thể hoàn tất sau deadline mà không recheck.
- AI Chat có thể biến fallback kỹ thuật thành câu trả lời thành công hoặc commit quota không nhất quán.

## Nguyên nhân gốc

- Dashboard và service chưa dùng chung một horizon reader; thiếu fail-closed parser và single-flight.
- Chưa có hồ sơ daily routine versioned và timing resolver độc lập với nội dung AI.
- Window policy/SQL dùng so sánh half-open; controller chỉ kiểm tra trước camera.
- Runtime config giữa IDE/CLI không đồng nhất; AI/commit error chưa có typed fail-closed orchestration.

## Cách sửa

- Thêm horizon gate inclusive theo `Asia/Ho_Chi_Minh`, idempotent replay trước gate và per-user single-flight.
- Thêm `daily_routine_v1`, onboarding/editor cho user cũ, `ScheduleTimingResolver`, nap item thật và manifest 10/11 item/ngày.
- Đổi completion/undo/proof upload sang `[start, start + 30 phút]`, inject clock và recheck sau camera.
- Chuẩn hóa runtime defines file; AI Chat typed failure; quota check → AI hợp lệ → commit retry ba lần → publish assistant.
- Đồng bộ migration 16, `config.sql`, BD/DD, acceptance docs và tests.

## Verification

- `flutter analyze`: PASS, không có issue.
- Targeted daily routine/horizon/window/completion/generated-plan/AI Chat/onboarding/tooling/SQL tests: PASS.
- Full suite lần ghi JSON: 852 test PASS; còn 7 failure + 1 error baseline ngoài phạm vi. Các failure do thay đổi onboarding đã được sửa và pass riêng 8/8.
- Supabase sandbox: BLOCKED vì thiếu CLI và project ref; không chạy destructive config.

## Rủi ro còn lại

- Cần sandbox Storage/RLS/two-user/concurrency và real-device camera/notification smoke trước production.
- Không bật wellness reward rollout cho đến khi acceptance sandbox pass.
