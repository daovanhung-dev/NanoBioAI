Commit de xuat: docs(worklog): ghi nhan phien admin-ai-notification-reliability

# Worklog - Ưu tiên Admin, khôi phục luồng AI và harden thông báo

## Thoi gian

- Ngay: 2026-07-19
- Bat dau: trong phiên Codex hiện tại
- Ket thuc: trong phiên Codex hiện tại
- Timezone: Asia/Saigon

## Pham vi

- Loai task: coding/bugfix/test/docs
- Module chinh: M02 `PERSONAL_SCHEDULE_AI`, M05 `AUTH_PROFILE_SYNC`, M06 `MEMBERSHIP_QUOTA`, M07 `AI_CHAT`, M09 `SCHEDULE_NOTIFICATIONS`, M15 `ADMIN_DASHBOARD`
- Yeu cau goc: Admin vào Admin ngay sau đăng nhập; sửa chat AI/lịch cá nhân và Settings sau login; kiểm tra, cô lập chủ thể và harden deep-link/action thông báo.

## Da lam

- Thêm `AppSurface.automatic`; Admin-only và dual-role đều mặc định vào Admin. Dual-role chỉ vào user surface sau thao tác chủ động và Admin không mount onboarding khi identity/access còn đang resolve.
- Đổi auth change thành `Stream<String?>` lấy trực tiếp từ session event. `currentAuthUserIdProvider` dùng identity event nên Settings bỏ card “Đăng nhập để giữ hành trình lâu dài” ngay khi session đến.
- Chat giữ thứ tự quota check → Gemini hợp lệ → quota commit → accept assistant turn. Không còn câu trả lời local giả; lỗi session/quota/RPC/config/xác thực/quá tải/response invalid được phân loại để UI hiển thị thông báo có thể hành động.
- Bổ sung provenance `generationSource` cho lịch. Bất kỳ chunk catalog local nào làm toàn bộ lịch thành “lịch gợi ý cơ bản”, lưu/replay provenance qua SQLite v16 và không commit quota thành viên. Lỗi scheduling notification sau khi lịch đã lưu không rollback lịch hoặc quota hợp lệ.
- Chỉ log metadata RPC an toàn (RPC, stage, status, error type), không log key hoặc prompt.
- Notification chỉ schedule lịch của subject hoạt động; refresh hủy OS notification và xóa pending rows của subject cũ hoặc source đã mất. Nếu OS cancel lỗi, pending row được giữ để retry thay vì mất tín hiệu cleanup. Tap notification User A sau khi chuyển User B bị fail-closed.
- Thêm iOS plugin registrant callback và `UNUserNotificationCenter` delegate; action hiển thị là “Mở nhiệm vụ” và “Để sau”; legacy `done` chỉ mở nhiệm vụ.
- Thêm exact V1 lifestyle route vào V3 standalone router để deep-link từ notification không lỗi.
- Serialize bootstrap notification để tránh double initialization/race giữa post-launch và auth refresh.

## File code/docs da sua

- `lib/app/app_surface_controller.dart`, `lib/app/bio_ai_app.dart` - automatic admin surface và loading shell khi identity chưa rõ.
- `lib/app_versions/v2/features/auth/` - auth identity stream, Settings reactivity và refresh/cleanup reminder theo phiên.
- `lib/app_versions/v1/services/ai/` - typed chat failure, acknowledge sau quota, provenance lịch và quota logging.
- `lib/core/storage/localdb/` - SQLite v16 `generation_source` cho personal schedule AI request.
- `lib/app_versions/v1/services/notifications/`, `ios/Runner/AppDelegate.swift`, `lib/app_versions/v3/router/v3_router.dart` - chủ thể active, cleanup, native iOS callback/action và deep-link.
- `test/` - regression Admin/Auth/Settings, AI/quota/migration, iOS/deep-link/action và User A → User B notification.
- `docs/checklist/` và `docs/fixbug/admin-ai-notification-reliability/` - evidence và backlog live.

## Tai lieu lien quan

- `docs/supabase/README.md` - contract sandbox; `config.sql` chỉ dùng cho local/sandbox disposable, không chạy production.
- `docs/checklist/checklist_complete_DD.md`
- `docs/checklist/checklist_task_coding.md`

## Commands

- `powershell -ExecutionPolicy Bypass -File tools/run_v2.ps1 -ValidateOnly`: PASS - runtime variables bắt buộc có mặt, không in secret.
- `flutter analyze`: PASS - `No issues found`.
- `flutter test` auth/admin/settings/router bundle: PASS - 10 tests.
- `flutter test test/services/notifications`: PASS - 44 tests.
- `flutter test` AI/quota/migration bundle: PASS - 81 tests.
- `flutter test test/services/ai/gemini_rest_client_test.dart`: PASS - 6 tests, gồm regression prepared turn chỉ vào context sau acknowledgement.
- `powershell -ExecutionPolicy Bypass -File tools/run_v2.ps1 -DeviceId 12b304f9`: PASS - build debug, cài và bootstrap trên Android thật; manual role/login/chat/permission cases chưa thể chạy.
- `powershell -ExecutionPolicy Bypass -File tools/test_gemini_connection.ps1 -TimeoutSec 20`: BLOCKED - mọi model trả HTTP 401; không lộ key.
- Kiểm tra Supabase tooling: BLOCKED - không có `supabase` CLI, `supabase/config.toml` hay project sandbox được chỉ định.

## Loi/Rui ro

- Da fix: race identity Settings, auto Admin surface, assistant turn ẩn khi quota commit lỗi, notification bootstrap race, stale subject action và V3 notification deep-link.
- Chua fix tu code: credential trong `.env` bị Gemini endpoint từ chối HTTP 401. App đã hiển thị lỗi xác thực đúng; cần cấp key Gemini hợp lệ từ Google AI Studio, rebuild qua launcher rồi smoke lại.
- Can kiem tra tiep: Supabase sandbox quota/RLS/idempotency, Android manual Admin/login/chat/schedule/permission/exact-alarm/reboot, và iOS foreground/background/terminated action trên thiết bị thật. Không triển khai hay chạy SQL production trong phiên này.

## Ty le hoan thanh

- Hoan thanh: toàn bộ thay đổi mã nguồn, regression local và hardening trong phạm vi yêu cầu.
- Dang do: acceptance phụ thuộc credential Gemini hợp lệ, sandbox chuyên dụng và thiết bị/account thực để chạy manual smoke.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tốt - tách rõ lỗi code đã sửa với dependency external bị từ chối, không che lỗi bằng fallback chat.
- Muc do hoan thanh task: code/test hoàn tất; live acceptance còn blocker được ghi bằng bằng chứng cụ thể.
- Bang chung kiem chung: full analyzer sạch; 10 auth/admin/settings/router + 44 notification + 81 AI/quota/migration tests pass; Gemini preflight HTTP 401 an toàn.
- Diem ton token/chua toi uu: output Flutter có log của test negative case và plugin mock; lần sau capture summary sớm hơn sau khi đã xác định bundle cần chạy.
- Cach toi uu cho phien sau: nhận sandbox project/CLI và credential Gemini đã xác nhận trước, sau đó chạy acceptance matrix thay vì đọc lại code.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
