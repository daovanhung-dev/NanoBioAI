# Worklog — triển khai logbug 14-7-26

## Thông tin

| Trường | Giá trị |
|---|---|
| Ngày | 2026-07-15 (`Asia/Saigon`) |
| Workflow | coding + DD delta + Supabase contract |
| Module | M01, M02, M03, M07, M09 |
| Nguồn | Kế hoạch logbug 14-7-26 do người dùng cung cấp |

## Kết quả

- Hoàn thiện schedule horizon reader/gate, shared dashboard state, idempotent replay và single-flight.
- Thêm daily routine weekday/weekend, validation/editor/onboarding/legacy flow, local `survey_answers` + outbox và timing resolver.
- Timeline dùng giờ resolver, thêm nap item thật; SQL reward manifest chấp nhận 10/11 item/ngày.
- Window completion/proof/undo inclusive; inject clock, boundary timer và recheck sau camera.
- AI Chat fail closed với typed error; quota commit retry tối đa ba lần cùng request id; không publish assistant trước commit.
- Chuẩn hóa VS Code/run/build qua `.dart_tool/nanobio_defines.json`.
- Cập nhật BD/DD M01/M02/M03/M07/M09, Supabase docs/config/contracts, logbug/checklists/fix note.

## Verification evidence

- `flutter analyze` → PASS, `No issues found`.
- Targeted bundle daily routine/horizon/window/completion/generated plan/AI Chat/onboarding → PASS (46 test ở bundle đầu; các regression bổ sung cũng pass).
- `test/services/ai/ai_service_test.dart`, generated-plan single-flight/gate và AI quota retry → PASS (59 test trong bundle).
- Tool launcher/build contract → PASS 3/3.
- Supabase wellness rewards contract → PASS 11/11.
- `test/widget_test.dart` sau cập nhật onboarding 9 bước → PASS 8/8.
- Final targeted regression bundle (routine, horizon, completion, generated plan, AI, onboarding, tooling và SQL) → PASS 115/115.
- Full suite JSON run → 852 success, 7 failure, 1 error. Các lỗi còn lại là baseline/ngoài phạm vi: Admin/localization copy, auth sync expectation, Advanced Health coming-soon, FamilyPlus copy, version-boundary hiện hữu và raw Scaffold của proof gallery.

## Blocker và việc còn lại

- Không có `supabase/config.toml` và `supabase` CLI; không xác minh được sandbox project ref, do đó không apply migration/config.
- Cần sandbox RLS/Storage/two-user/concurrency, pending→available và real-device camera/notification.
- Giữ `wellness_rewards_rollout.enabled = false`; tiến độ logbug hiện 90%, không claim production acceptance.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tốt — business gate, source, SQL, DD và test evidence được nối xuyên suốt, không ghi đè file dirty của người dùng.
- Muc do hoan thanh task: runtime/DD/static contract hoàn tất; sandbox/production acceptance còn blocked có bằng chứng.
- Bang chung kiem chung: analyzer sạch, targeted tests pass, full-suite JSON phân loại rõ baseline failure.
- Diem ton token/chua toi uu: năm module DD có nhiều nội dung lặp; lần sau nên dùng module index và delta router sớm hơn.
- Cach toi uu cho phien sau: chuẩn bị Supabase CLI + verified sandbox ref trước phiên, chạy test file reporter ngay từ đầu.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md` và `.codex/task-skills/supabase-schema.md`.
