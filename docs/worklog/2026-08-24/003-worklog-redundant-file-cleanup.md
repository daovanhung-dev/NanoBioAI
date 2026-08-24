Commit de xuat: docs(cleanup): remove redundant project files

# Worklog - Dọn file và dữ liệu dư thừa an toàn

## Thoi gian

- Ngay: 2026-08-24
- Bat dau: 21:30
- Ket thuc: 21:35
- Timezone: Asia/Saigon (+07)

## Pham vi

- Loai task: docs-context cleanup
- Module chinh: documentation, historical visual evidence, local build caches
- Yeu cau goc: xóa tài liệu, ảnh và cache không còn giá trị sử dụng nhưng giữ asset runtime, rollback, nguồn thiết kế và hồ sơ cần truy vết.

## Da lam

- Chốt manifest trước khi xóa: 8 file cố định, 54 ảnh evidence V2/Admin và 9 preview Nabi v1; giữ `ADMIN-M18-REPORTS-002-fixed.png`.
- Xóa 71 file Git-tracked đã trùng byte, không còn tham chiếu hoặc đã được thay thế rõ ràng.
- Đồng bộ `tools/validate_docs_source_truth.py` để không giữ hai đường dẫn historical đã xóa.
- Xóa sáu cache tái tạo được: `build/`, `.dart_tool/`, `android/.gradle/`, `tools/__pycache__/`, `.codex/tools/__pycache__/`, `.flutter-plugins-dependencies`.
- Giữ nguyên Nabi V1/V2 rollback/release assets, Stitch design input, ảnh runtime, meal catalog source, `.env`, local Android config và Gradle wrapper.

## File code/docs da sua

- 71 file tracked - xóa theo manifest cleanup đã được xác nhận.
- `tools/validate_docs_source_truth.py` - bỏ `MANIFEST.txt` và `docs/IMAGE_MAPPING_AUDIT.md` khỏi lifecycle historical.
- `docs/worklog/2026-08-24/003-worklog-redundant-file-cleanup.md` - tạo bằng chứng cleanup và kiểm chứng.

## Tai lieu lien quan

- `docs/README.md`
- `docs/DD/auth_profile_sync/README.md`
- `docs/test/full-project-2026-07-28/assets/PF-028-pass.png`

## Commands

- Preflight manifest/hash/protected-file checks: PASS.
- `git rm` exact tracked manifest: PASS.
- Tracked cleanup assertions and survivor hash: PASS.
- `python3 -m py_compile tools/validate_docs_source_truth.py`: PASS.
- `python3 tools/validate_docs_source_truth.py`: BASELINE BLOCKED - chỉ thiếu `docs/audit/source_truth_manifest.json`, không phát sinh lỗi cleanup mới.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: SKIPPED - PowerShell không có trong môi trường hiện tại.
- `python3 .codex/tools/update_worklog_learning.py --write`: PASS - làm mới 19 history/task-skill deterministic file.
- Final tracked/cache/protected assertions: PASS.
- `git diff --check` và `git diff --cached --check`: PASS sau history refresh.

## Loi/Rui ro

- Da fix: loại các ảnh và tài liệu dư thừa đã có bằng chứng thay thế hoặc không còn consumer.
- Chua fix: source-truth manifest audit đang thiếu từ baseline; không thuộc phạm vi xóa file.
- Can kiem tra tiep: nếu cần retire Nabi V1 rollback hoặc Stitch reference, phải làm thay đổi runtime/design riêng với test build tương ứng.

## Ty le hoan thanh

- Hoan thanh: cleanup tracked manifest và cache local theo phạm vi đã duyệt.
- Dang do: không có.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tốt - chỉ xóa file có bằng chứng, không dùng dọn hàng loạt.
- Muc do hoan thanh task: hoàn thành theo manifest đã chốt.
- Bang chung kiem chung: preflight count/hash, survivor assertion, diff check và source-truth baseline comparison.
- Diem ton token/chua toi uu: inventory ảnh lớn cần hash/reference audit trước khi xóa.
- Cach toi uu cho phien sau: duy trì manifest allow-list và kiểm tra reference trước mọi cleanup asset.
- Task-skill can doc lan sau: `.codex/task-skills/docs-context.md`
