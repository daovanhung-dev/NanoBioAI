Commit de xuat: docs(worklog): ghi nhan phien Auth V2 Admin M05 completion

# Worklog - Auth V2, Admin và M05 completion

## Thời gian

- Ngày: 2026-07-12
- Bắt đầu: phiên hiện tại, không có timestamp tự động từ repo
- Kết thúc: 09:18
- Timezone: Asia/Bangkok

## Phạm vi

- Loại task: coding
- Module chính: M05 AUTH_PROFILE_SYNC, M12 REFERRAL_DIRECT, M15-M16 Admin access
- Yêu cầu gốc: đọc `AGENTS.md`, coding theo plan hoàn thiện Auth V2/Admin, sửa hai lỗi P0 đồng bộ, bổ sung Guest consent, migration/test/docs và đóng gói zip.

## Đã làm

- Đọc root/`.codex` context, project map, coding workflow, task-skill, domain access/referral và checklist M05.
- Hoàn thiện Auth V2 callback coordinator, callback result, reactive router, safe error copy, sign-out preflight và user-data invalidation.
- Tắt Flutter deep-link handler mặc định trên Android để tránh xử lý callback hai lần.
- Chuẩn hóa toàn bộ lỗi Auth V2 sang copy an toàn và map lỗi trigger signup chung khi có referral về yêu cầu sửa/xóa mã.
- Chuyển referral + fingerprint vào metadata signup; bỏ attach-after-signup.
- Tạo migration atomic signup/referral và đồng bộ vào `config.sql` mà không chạy remote.
- Khôi phục request ledger vào snapshot/map/serializer và sửa trigger list theo `request_id`.
- Thêm authenticated single-flight sync state/coordinator, push-before-pull, durable retry và transaction race guard.
- Thêm Guest fresh/established-cloud consent, Settings sync status/retry và dashboard pending/error banner.
- Tách Admin storage key, thêm `AdminAccessState`, auth-event role check, gate và safe support state.
- Admin gate chủ động gọi lại server khi vào từng route được bảo vệ để phát hiện role bị thu hồi hoặc token hết hạn.
- Thêm unit/contract/regression test source và cập nhật acceptance/checklist/worklog/history context.

## File code/docs đã sửa

- `lib/app_versions/v2/features/auth/` - sửa/tạo - Auth lifecycle, deep link, referral metadata, sign-out preflight.
- `lib/app_versions/v2/features/cloud_sync/` - sửa/tạo - state/outcome, consent, single-flight, push-before-pull.
- `lib/core/storage/localdb/sync/` và `lib/services/supabase/cloud_sync/` - sửa/tạo - request ledger/outbox/durable retry/coalesced triggers.
- `lib/app_versions/admin/features/admin_panel/` và `lib/main_admin.dart` - sửa/tạo - separate session và Admin access gate.
- `docs/supabase/15-auth-sync-completion.sql`, `docs/supabase/config.sql` - tạo/sửa - atomic signup contract.
- `test/app_versions/v2/`, `test/app_versions/admin/`, `test/docs/` - sửa/tạo - regression/contract coverage.
- `docs/features/`, `docs/fixbug/`, `docs/test/`, `docs/checklist/`, `docs/worklog/` - tạo/sửa - traceability và acceptance backlog.

## Tài liệu liên quan

- `.codex/workflows/coding.md`
- `.codex/task-skills/coding.md`
- `.codex/domains/access-membership-referral.md`
- `docs/DD/auth_profile_sync/`
- `docs/test/v2-admin-regression/001-test-v2-admin-regression.md`

## Commands

- YAML parse `pubspec.yaml`: PASS.
- Local/relative Dart package import existence scan: PASS.
- Changed Dart delimiter/static source scan: PASS.
- SQL marker/token/config mirror checks: PASS.
- Static repository validation: PASS 17/17 (YAML, XML, imports, delimiters, contracts, SQL mirror, Markdown links và history).
- `.codex/tool/codex_quick_check.sh`: BLOCKED tại `flutter pub get` với exit 127; script được chuẩn hóa CRLF tạm thời để chạy trên Linux.
- History refresh: PASS bằng bản tương thích Python do môi trường không có PowerShell; 70 worklog được index.
- `dart format`: BLOCKED - không có Dart SDK trong môi trường.
- `flutter analyze`: BLOCKED - không có Flutter SDK trong môi trường.
- `flutter test`: BLOCKED - không có Flutter SDK trong môi trường.
- Debug APK V2/Admin: BLOCKED - không có Flutter SDK và không có `adb`; Java có sẵn nhưng không đủ để build/chạy Flutter.
- `git diff --check`: archive không chứa `.git`; `git diff --no-index --check --ignore-space-at-eol` PASS, không có cảnh báo khoảng trắng.
- Supabase sandbox/device `12b304f9`: BLOCKED - không có quyền/kết nối từ môi trường hiện tại.

## Lỗi/Rủi ro

- Đã fix: request ledger bị thiếu snapshot; pull có thể ghi đè write chưa push; race local write trong lúc pull; referral attach sau signup; Admin/user session dùng chung; Admin role/session expiry chưa có gate chủ động.
- Chưa fix: merge concurrent đa thiết bị nằm ngoài contract đã khóa.
- Cần kiểm tra tiếp: compile/API compatibility bằng Flutter SDK, atomic rollback thực tế trên Supabase sandbox, RLS/idempotency và toàn bộ evidence device.

## Tỷ lệ hoàn thành

- Hoàn thành: implementation + test source + SQL migration + docs theo plan trong phạm vi repository.
- Đang dở: runtime/sandbox/device acceptance và debug APK do môi trường thiếu tool/quyền.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - ưu tiên hai lỗi mất dữ liệu, giữ backward contract và không claim bằng chứng chưa chạy.
- Mức độ hoàn thành task: hoàn thành source-level; production acceptance còn blocker rõ ràng.
- Bằng chứng kiểm chứng: static source/YAML/import/SQL checks và regression test source.
- Điểm tốn token/chưa tối ưu: phạm vi xuyên nhiều module cần diff review lớn.
- Cách tối ưu cho phiên sau: chạy targeted Flutter suite trước, sau đó sandbox seed/device matrix theo đúng case ID.
- Task-skill cần đọc lần sau: `.codex/task-skills/test.md` cho phase nghiệm thu.
