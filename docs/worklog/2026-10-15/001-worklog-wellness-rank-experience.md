Commit de xuat: feat(wellness-rank): implement task experience and personal ranks

# Worklog - Hạng cá nhân theo EXP nhiệm vụ

## Thời gian

- Ngày: 2026-10-15
- Bắt đầu: khoảng 00:20
- Kết thúc: khoảng 01:05
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: coding, Supabase schema, SQLite migration, UI, BD/DD/checklist/context.
- Module chính: M03 DASHBOARD_SCHEDULE, M08 HEALTH_SCORE_HABITS; shared wellness rank.
- Yêu cầu gốc: triển khai plan đã được duyệt cho rank cá nhân theo EXP, trừ EXP tuần, Dashboard/Settings và cache offline.

## Đã làm

- Thêm forward migration và canonical SQL với account, experience ledger, task-state reconciliation dưới per-item advisory lock, trigger trên proof/check-in, weekly decay tuần tự có sàn 0 và RPC `get_my_wellness_rank_summary()` chỉ dùng `auth.uid()`.
- Mỗi schedule item active cộng 10 EXP một lần; undo chỉ thu hồi khi evidence cuối cùng của item không còn active. Các kỳ giảm được áp dụng trước khi xử lý event hoặc trả summary.
- Thêm shared model/repository/provider/card. Dashboard và Settings dùng chung; khách có lối đăng nhập; lỗi có retry; offline dùng snapshot theo user cùng thời điểm đồng bộ. Có kiểm tra session đổi user trước khi cache response.
- Thêm SQLite v33 cache, DAO và migration sau v32; cập nhật phiên bản trong `.codex` và giữ nguyên schema v32.
- Bổ sung BD v1.0, một DD delta được M03/M08 cùng tham chiếu, checklist và map; không đổi điều kiện đổi quà.
- Giữ các chỉnh sửa bẩn có sẵn; chỉ cập nhật assertion current DB version trong test v32 để tương thích v33.

## File code/docs đã sửa

- `supabase/migrations/20261015090000_wellness_rank_experience.sql`, `docs/supabase/01_build_system.sql`, `docs/supabase/README.md` — schema, trigger, RPC và hướng dẫn forward migration.
- `lib/shared/wellness_rank/**`, `lib/core/storage/localdb/{database_service.dart,database_version.dart,daos/wellness_rank_summary_cache_dao.dart,migrations/migration_v33.dart,tables/wellness_rank_cache_table.dart}` — domain/data/UI/cache v33.
- `lib/app_versions/v1/features/dashboard/**`, `lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart` — hiển thị hạng và refresh sau khi trở về lịch.
- `test/shared/wellness_rank/**`, `test/core/storage/localdb/migrations/migration_v33_test.dart`, `test/docs/supabase_wellness_rank_experience_contract_test.dart`, `test/core/storage/localdb/migrations/migration_v32_test.dart` — coverage widget/repository/SQL contract/version/migration.
- `docs/BD/wellness_rewards/BD_BioAI_Wellness_Rank_Experience_v1.0.md`, `docs/DD/dashboard_schedule/Implementation_Delta_2026-10-15_Wellness_Rank_Experience.md`, hai README DD M03/M08, checklist, `.codex/AGENTS.md`, `.codex/README.md`, `.codex/domains/sqlite.md`, `.codex/MAP_TREE.md` — tài liệu và version map.
- `.codex/history/*` — cập nhật bằng script sau khi thêm worklog; giữ lại các thay đổi đã có trước phiên này.

## Tài liệu liên quan

- BD `BD-BIOAI-WELLNESS-RANK-EXPERIENCE-001` v1.0.
- DD delta M03/M08 và migration `20261015090000_wellness_rank_experience.sql`.
- Workflow `coding`, `supabase-schema`, `docs-dd`, `docs-context`; task-skills tương ứng.

## Commands

- `dart format` các Dart source/test thuộc thay đổi: PASS.
- `flutter analyze` source/test mục tiêu: PASS, không có issue.
- 8 file test Dart (14 test): PASS — rank card guest/loading/offline/error, repository cache theo user/auth đổi, SQL contract, DB version contract, SQLite v32/v33, Settings auth reactivity và Dashboard recovery.
- PostgreSQL 17 disposable cluster: PASS — áp dụng và chạy lại migration; cộng một lần; hợp nhất hai nguồn evidence; undo; 3 kỳ decay quá hạn không lặp; sàn EXP; đủ ngưỡng 600/1.200/2.600/5.200; FamilyPlus nhiều subject cùng account; độc lập với wallet; RPC không lộ user khác và grants đúng.
- `LD_LIBRARY_PATH=/tmp/nanobio-sqlite-test/runtime/usr/lib/x86_64-linux-gnu flutter test` cho 8 file mục tiêu: PASS, 14 test. SQLite shared library được giải nén tạm vào `/tmp`, không cài vào hệ thống.
- Dart Tooling Daemon `hot_restart`: PASS; runtime error query: không có lỗi.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: FAIL do thiếu `docs/audit/source_truth_manifest.json` và stale paths có sẵn trong history/task-skill cũ; không chỉ ra lỗi ở file delta mới.
- `git diff --check`: PASS.

## Lỗi/Rủi ro

- Đã xử lý: trigger gộp proof/check-in theo user và schedule item để không cộng hai lần; kiểm tra auth trước/sau RPC tránh cache nhầm khi phiên đăng nhập đổi.
- Chưa xác minh: Supabase sandbox/production RLS và tương tác UI thực tế trên thiết bị.
- Repository context validator hiện vẫn bị chặn bởi source-truth manifest thiếu và stale path lịch sử ngoài phạm vi rank.
- Cần kiểm tra tiếp: review/apply forward migration trên Supabase sandbox riêng rồi xác minh hosted state theo quy trình dự án.

## Tỷ lệ hoàn thành

- Hoàn thành: implementation source, test source, tài liệu BD/DD/checklist và disposable PostgreSQL smoke.
- Đang dở: hosted Supabase sandbox và tương tác UI acceptance; không có migration nào được áp dụng lên Supabase.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt — server làm nguồn tính EXP; trigger hội tụ nhiều loại evidence và có thể kiểm tra ngưỡng/decay trực tiếp trên PostgreSQL tạm.
- Mức độ hoàn thành task: source implementation và SQLite migration tests hoàn tất; hosted/device acceptance còn thiếu.
- Bằng chứng kiểm chứng: analyzer sạch, 14 Dart tests pass, PostgreSQL disposable smoke pass, hot restart/no runtime errors, diff whitespace sạch.
- Điểm tốn token/chưa tối ưu: cần giải nén native SQLite vào `/tmp` để chạy sqflite FFI trên máy này.
- Cách tối ưu cho phiên sau: tiếp tục hosted sandbox acceptance; test source hiện chạy được khi cung cấp `libsqlite3.so` qua `LD_LIBRARY_PATH`.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`, `.codex/task-skills/supabase-schema.md`, `.codex/task-skills/docs-dd.md`, `.codex/task-skills/docs-context.md`.
