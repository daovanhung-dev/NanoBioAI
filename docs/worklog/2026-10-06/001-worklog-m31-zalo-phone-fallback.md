# Worklog — M31 Zalo alert + offline phone fallback

- Ngày: 2026-10-06
- Loại task: coding
- Module chính: M31 SLEEP_SAFETY_MONITORING
- Yêu cầu gốc: Đọc `docs/plans/M31_ZALO_PHONE_FALLBACK_CODEX_PLAN.md` rồi thực thi; sửa plan cho phép rollout production sau staging/QA.

## Mục tiêu

Đọc và thực thi `docs/plans/M31_ZALO_PHONE_FALLBACK_CODEX_PLAN.md`; mở rộng M31
bằng Zalo best-effort qua Edge Function, hành động gọi qua system dialer và retry
cloud giới hạn theo freshness window. User cho phép production rollout sau staging
và QA dần; plan đã được sửa theo hướng additive migration, staging-first.

## Implementation

- Tạo branch `feature/m31-zalo-phone-fallback`, bảo toàn plan người dùng đã đưa.
- Thêm contact opt-in cho Zalo/phone; SQLite v26 migration giữ cache cũ và thêm
  hai default an toàn.
- Thêm typed dispatch result/error, connectivity/phone gateways và local outbox
  metadata retry với idempotency không đổi, timeout 8 giây, retry hữu hạn, xử lý
  reconnect, crash khi request đang `sending` và event quá freshness.
- Flutter UI giữ local alert, mở dialer chỉ sau thao tác người dùng và không ghi
  dialer mở thành accepted/answered. Android notification dùng `ACTION_DIAL`; iOS
  notification chỉ hiện action call khi runtime flag/contact hợp lệ.
- Edge ZBS adapter gửi template đã cấu hình bằng token server-side; malformed/
  failed Zalo config hoặc API không chặn voice/SMS. Dispatch evidence không lộ
  phone; `submitted` không có nghĩa delivered.
- Cập nhật canonical SQL và tạo migration cộng thêm
  `supabase/migrations/20261006090000_m31_zalo_phone_fallback.sql`. Hai cờ mới
  mặc định false; live không dùng SQL rebuild/seed.
- Tái hiện và sửa validator contact E.164 bằng migration cộng thêm
  `20261006100000_m31_contact_phone_regex_fix.sql`; ghi root cause/evidence ở
  `docs/fixbug/sleep-safety-contact/001-fixbug-sleep-safety-phone-validator.md`.
- Cập nhật BD v1.2, DD v1.3, feature doc, Supabase deployment guide, checklist,
  plan và SQLite version reference.

## Research và safety boundary

- Zalo Developers phone-template API, OA token lifecycle và moderation notice
  được ghi liên kết trong plan/BD. Adapter hiện chưa có refresh-token rotation
  bền vững hoặc webhook delivery receipt; giữ `zalo_enabled=false` ở staging và
  production cho tới khi các điều kiện này được xử lý.
- Không thêm auto-call, `ACTION_CALL`, Call Log hoặc SMS permission. Không gửi
  audio/transcript/phone cho AI; outbox chỉ giữ event/idempotency/timestamps.
- Credential provider đã bị lộ trong hội thoại trước đó; phải revoke/rotate
  trước khi cấu hình môi trường thật. Không ghi lại giá trị credential ở đây.

## Verification

| Area | Evidence |
|---|---|
| Flutter tests | Focused controller, repository, phone fallback contract, migration v26 và M31 Supabase contract chạy lại sau regex fix — 21 passed, 0 failed. Lệnh dùng Flutter 3.47.1 với `--no-pub`; migration test dùng symlink tạm `/tmp/nanobio-m31-sqlite/libsqlite3.so` tới system `libsqlite3.so.0`. |
| Flutter analyze | Full `/home/daovanhung/development/Flutter/flutter/bin/flutter analyze --no-pub` — `No issues found!` (11.4s). |
| Android build/install | Debug APK build hiện tại PASS (`flutter build apk --debug --no-pub`). Bản debug trước đó đã được cài lại bằng `adb install -r` sau lần integration runner; không cài đè lần nữa khi người dùng đang đăng nhập lại. APK cài trên máy là version 1.0.1/code 4. |
| Android runtime | Xiaomi 220333QPG, Android 11/API 30, package `com.nanobioai.app` mở `MainActivity`; `RECORD_AUDIO` hiện granted theo `dumpsys`. `adb shell input tap` bị Android từ chối do thiếu `INJECT_EVENTS`. Một lần chạy Flutter integration test thất bại trước khi vào được `SleepTrackingPage` (harness handler conflict và framework ListTile warning); runner làm reset local app sandbox/session/cache. App debug bình thường đã được khôi phục bằng `adb install -r`; chưa có contact, monitoring, alert, dialer hay cuộc gọi được xác nhận sau khi reset. Người dùng đang đăng nhập lại. Không chạy integration runner lần nữa. |
| Deno Edge | `deno test ...sleep_safety_zalo_provider_test.ts ...handler_test.ts` — 6 passed, 0 failed. |
| Deno format | `deno fmt --check` trên 5 file Edge thay đổi — pass. |
| Diff whitespace | `git diff --check` — pass tại lần kiểm tra cuối. |
| iOS | Chưa build/smoke; kiểm thử mục tiêu hiện tại chỉ yêu cầu Android. |
| Supabase staging | Project/ref/name/ACTIVE đã xác minh. Migration `20261006090000` và forward fix `20261006100000` đã apply; remote history xác nhận. Validator mẫu E.164 đúng, table constraint đã sửa, hai RPC upsert đã sửa; không có row contact cũ sai định dạng. PITR tắt, physical backups rỗng; recovery path là additive forward-fix và kill switch. |
| Container/Postgres | Docker không có; không có local Supabase/Postgres runtime để validate migration. |

## Deployment status

Supabase CLI đã xác thực; project/ref/name/ACTIVE state khớp project staging
được cung cấp và config trong repo. Cả migration M31
`20261006090000_m31_zalo_phone_fallback.sql` và migration sửa validator
`20261006100000_m31_contact_phone_regex_fix.sql` đã apply và được xác minh qua
remote migration history. Kiểm tra chỉ đọc xác nhận đúng một hàng `default`,
`enabled=true`, `phone_fallback_enabled=false`, `zalo_enabled=false`. Cờ phone
được khôi phục về false sau khi QA bị gián đoạn; Zalo luôn false. Không có PITR
hoặc physical backup; schema migration transactional và không đổi contact rows,
nên recovery là kill switch + forward-fix. Không deploy Edge Function hoặc gọi
dispatch cloud. Không ghi credential, số liên hệ hoặc audio vào worklog.

Trong lúc tái hiện form thêm liên hệ, đọc lại contract trên staging cho thấy
validator SQL cũ dùng escape sai và từ chối E.164 hợp lệ. Thêm migration cộng
thêm có guard để thay check constraint và đúng hai overload RPC; migration chỉ
sửa source canonical `docs/supabase/01_build_system.sql` và không ghi/insert dữ
liệu người dùng. Kiểm tra remote: regex mẫu hợp lệ được chấp nhận, constraint
đúng, hai RPC đã sửa, không còn function dùng pattern lỗi.

## Commands

- Focused Flutter suite với `flutter test --no-pub` và 5 file M31: PASS, 21/21.
- `flutter analyze --no-pub`: PASS, không có analyzer issue.
- `flutter build apk --debug --no-pub`: PASS.
- Deno provider/handler tests và format: PASS, 6/6 và 5 file sạch (bằng chứng từ lượt trước; Edge source không đổi trong lần sửa validator).
- `git diff --check`: PASS sau khi cập nhật docs.
- `supabase db query --linked --project-ref …` read-only check: PASS; một hàng `default`, phone/Zalo flags đều `false`.
- `validate_codex_integrity.ps1`: FAIL do missing `docs/audit/source_truth_manifest.json` và stale paths trong historical worklog/task-skill (unrelated to M31).
- Android contact/monitoring/dialer/call smoke: INCOMPLETE; integration runner không vào được màn hình đích và reset local session/cache.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot; phone fallback source, staging validator fix và evidence được cập nhật; chưa có bằng chứng gọi thật.
- Muc do hoan thanh task: partial; coding, source tests, staging migrations và build xong; Android acceptance còn mở.
- Bang chung kiem chung: 21 focused tests, full analyzer sạch, APK build PASS, staging history/constraint/RPC xác minh, hai cờ tắt.
- Diem ton token/chua toi uu: phải dò đường dẫn Flutter do PATH không có `flutter`; integration runner là lựa chọn sai cho đăng nhập UI trên máy thật và làm reset app sandbox.
- Cach toi uu cho phien sau: không gọi Flutter integration runner trên device; để người vận hành đăng nhập/cấp quyền/thao tác UI, Codex chỉ dùng ADB đọc trạng thái. Tiếp tục từ app session do người dùng khôi phục.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`.

- Con lai:
  - Người dùng đăng nhập lại QA account; thêm/xác minh contact bằng UI
  Auth/OTP bình thường (không ghi trực tiếp DB), bật cờ phone chỉ trong thời gian
  kiểm thử; xác nhận monitoring, controlled stimulus, alert, dialer và cuộc gọi
  hai chiều 10 giây. Sau đó xử lý alert, khôi phục cờ/mạng, quét logcat và cập
  nhật evidence đã khử PII. Chưa đạt device acceptance; không gọi thật trong
  phiên hiện tại.
  - Sự cố: integration-test runner trên device làm reset local session/cache;
  đã báo người dùng và khôi phục APK debug bình thường. Không tái chạy runner.
