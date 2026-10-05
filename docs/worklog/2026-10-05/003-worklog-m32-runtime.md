Commit de xuat: feat(m32): implement fitness training pilot

# Worklog — M32 fitness-training runtime pilot

## Thời gian

- Ngày: 2026-10-05
- Bắt đầu: Tiếp tục phiên coding đang dang dở; thời điểm bắt đầu ban đầu không được ghi nhận.
- Kết thúc: 12:30 Asia/Ho_Chi_Minh.
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: coding / test / cập nhật BD-DD-handoff
- Module chính: M32 FITNESS_TRAINING
- Yêu cầu gốc: theo chỉ đạo PO, triển khai pilot Gemini Gym-first trong FeatureHub; không chờ reviewer sign-off, không ghi giả phê duyệt.

## Đã làm

- Nối FeatureHub, router và Guest allowlist với luồng M32 cho Android/iOS.
- Thêm rà soát hồ sơ, tuổi tự khai tại thiết bị, mục tiêu, kinh nghiệm, lịch tập/ngủ, hạn chế vận động, dị ứng/nhóm thực phẩm, lựa chọn nhà/gym và thiết bị; thêm consent AI, preview, xác nhận, lịch 28 ngày và check-in/replan tuần.
- Đưa catalog pilot vào runtime: 24 bài tập (16 gym/8 tại nhà), 10 thiết bị, 35 món ăn, 47 ứng viên nguyên liệu FDC, 9 atlas minh họa gốc; metadata giữ ID, FDC provenance, filter và trạng thái review. Không tải video/thumbnail bên thứ ba; hiện không có video được duyệt để nhúng.
- Thêm service M32 dùng Gemini backend hiện có với hai operation allowlist; Gemini key vẫn ở Edge Function. DOB/tên/ghi chú/đo đạc trực tiếp không nằm trong AI intake. Response strict-schema validation, catalog/gear/allergen/movement filters, ranges, request reuse và M02 quota behavior được bổ sung.
- Thêm SQLite v25 cho program 28 ngày và transaction áp tuần vào lịch 7 ngày; xóa chỉ các mục M32 tương lai chưa hoàn thành, giữ mục đã hoàn thành, quá giờ và nguồn sức khỏe/khác.
- Bổ sung đồng bộ snapshot Member self/RLS source. Guest lưu cục bộ. FamilyPlus dependent-subject selection/storage/sync chưa được thực hiện.
- Cập nhật tài liệu trạng thái để phản ánh pilot code và bằng chứng hiện có; DD vẫn Draft, Tech/Privacy, Clinical và QA pending. Không triển khai Supabase lên sandbox/production.
- Rà soát trước khi giao commit: sửa câu “runtime absent” đã lỗi thời trong `.codex/MAP_TREE.md` và nối tiếp changelog M32 bằng trạng thái pilot hiện tại, vẫn giữ DD Draft và các phê duyệt ở trạng thái pending.

## File code/docs đã sửa

- `lib/app_versions/v1/features/fitness_training/` — domain, application, provider, catalog/profile/program SQLite adapters, UI và IFrame fallback.
- `lib/app_versions/v1/features/features_hub/`, `lib/app_versions/v1/router/` — shortcut, route và Guest allowance.
- `lib/core/storage/localdb/`, `lib/app_versions/v2/features/cloud_sync/` — SQLite v25, outbox/snapshot mapping cho Member self.
- `assets/data/fitness_training/` — catalog pilot cùng 9 illustration atlas.
- `supabase/functions/nabi-ai-generate/` — allowlist operation generate/replan và tests.
- `pubspec.yaml`, `pubspec.lock`, `macos/Flutter/GeneratedPluginRegistrant.swift` — youtube_player_iframe wrapper dependency/registrant.
- `docs/BD/fitness_training/`, `docs/DD/fitness_training/`, `docs/features/fitness-training/`, `docs/checklist/`, `docs/DD/README.md` — ghi đúng lựa chọn tuổi tự khai, implementation In Progress và reviewer status.
- `docs/test/fitness-training/001-test-fitness-training-m32.md` — kết quả kiểm tra có giới hạn và nội dung chưa xác minh.
- `.codex/history/` và `.codex/task-skills/` — làm mới theo worklog bằng script NanoBio.
- `.codex/MAP_TREE.md`, `docs/DD/fitness_training/history/CHANGELOG.md` — sửa ghi nhận trạng thái M32 bị lỗi thời.

## Tài liệu liên quan

- `docs/DD/fitness_training/Review_Packet.md` — Tech/Privacy, Clinical và QA vẫn Pending.
- `docs/supabase/01_build_system.sql` — source schema/RLS/snapshot cho Member self; chưa apply.
- `.codex/design/15_CODING_PLAN.md` — coding theo workflow NanoBio và record approval gate.

## Commands

- `flutter pub get`: PASS.
- `dart format <touched Dart paths>`: PASS.
- `flutter analyze <17 targeted runtime/test paths>`: PASS, 0 issues.
- Focused M32/FeatureHub/router `flutter test`: PASS, 28/28 (SQLite host shim via `/tmp/nanobio_m32_sqlite_lib`).
- `deno test supabase/functions/nabi-ai-generate/handler_test.ts`: PASS, 12/12.
- Catalog/reference integrity check: PASS, inventory, FDC IDs, ingredient/image/atlas links and runtime/review-pack parity verified.
- `flutter build apk --debug`: PASS after the final same-day schedule guard.
- `flutter build apk --release`: PASS before the final same-day schedule guard, 154.8 MB package containing configured ABIs; final source verified by the split-per-ABI release build. Android build emits Gradle/AGP/Kotlin upcoming compatibility warnings.
- `flutter build apk --release --split-per-abi`: PASS after the final same-day schedule guard; rebuilt APKs for armeabi-v7a, arm64-v8a and x86_64.
- M05/cloud-sync contract suites (`cloud_sync_contract_test`, authenticated repository, SQLite sync proof and outbox): PASS, 16/16.
- Android install/device navigation: SKIPPED; a NanoBio package is already installed on the connected personal handset and no isolated QA profile/device was provided. No user data was replaced/read.
- iOS/Xcode, Supabase sandbox/RLS, live Gemini and quota acceptance: SKIPPED / unavailable; no external service was contacted.
- `git diff --check`: PASS.
- `pwsh -NoProfile -File .codex/tools/validate_codex_integrity.ps1`: FAIL on repository baseline: missing `docs/audit/source_truth_manifest.json` and stale Supabase/Nabi-character paths in generated `.codex/history`/task-skill files; no M32-specific path failure.
- `pwsh -NoProfile -File .codex/tools/update_worklog_learning.ps1`: PASS; updated 19 deterministic history/task-skill files; `python3 .codex/tools/update_worklog_learning.py --check` confirms 19/19 current.

## Lỗi/Rủi ro

- Đã fix: Guest initial-plan quota is preflighted before Gemini and consumed atomically with a valid preview; strict schema rejects extra/missing structures; applying a week mid-day no longer reinserts same-day tasks whose start time has passed.
- Chưa fix: Feature is still a PO-directed pilot, not release-approved; self-declared DOB can be spoofed; FamilyPlus dependent subject support is absent; server Edge operation does not independently enforce M02 quota/catalog semantics; candidate nutrition/exercise content has not received clinical review.
- Cần kiểm tra tiếp: sync/quota/RLS on disposable Supabase sandbox; Android on an isolated QA device; iOS/Xcode and native IFrame; accessibility/crop review; Tech/Privacy, Clinical and QA sign-offs; decide if server-side M02 enforcement and FamilyPlus subject ownership are required before release.

## Tỷ lệ hoàn thành

- Hoàn thành: source pilot flow, local catalog, SQLite schedule/program path, Gemini named operations, quota integration, FeatureHub reachability and local test/build evidence.
- Đang dở: release acceptance, FamilyPlus dependent subject, server/Supabase/device/iOS acceptance, content reviews and role sign-offs.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt — feature path is layered, catalog filters and response validation are fail-closed, local schedule apply is transactional, and remaining boundary is stated without marking reviewers approved.
- Mức độ hoàn thành task: pilot source implemented; full release completion is not achieved while FamilyPlus support, sandbox/device evidence and reviewer decisions remain open.
- Bằng chứng kiểm chứng: 44 focused Flutter tests, 12 Edge tests, targeted analyzer 0 issues, catalog provenance/reference integrity and Android debug/release builds (including split-per-ABI) passed. Android physical-device, iOS and Supabase acceptance are unverified.
- Điểm tốn token/chưa tối ưu: broad DD output exposed stale “absent/no-runtime” statements; targeted M32 paths plus grep resolved them. The first catalog check used wrong JSON field names and was corrected before evidence was recorded.
- Cách tối ưu cho phiên sau: isolate family subject context and sync contract before changing M05/RLS; use disposable test account and device to close native acceptance; keep catalog review status distinct from release status.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
