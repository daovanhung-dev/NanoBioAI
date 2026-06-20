# Hướng dẫn đọc DD Authentication

## Với developer nhận task

1. Mở `00_READ_FIRST.md`.
2. Xác định task thuộc feature nào trong `01_DOCUMENT_MAP.md`.
3. Đọc đúng feature DD, sau đó đọc listed dependencies.
4. Đọc `14_FLUTTER_LAYER_CONTRACTS.md` trước khi sửa production code Flutter.
5. Đọc `15_TEST_ACCEPTANCE_AND_TRACEABILITY.md` trước khi test/finalize.

## Với reviewer/tech lead

1. `02_MODULE_OVERVIEW.md` để nắm invariant.
2. `03_DATA_MODEL_RLS_AND_MIGRATIONS.md` để review security/database.
3. DD feature đang change.
4. `15_TEST_ACCEPTANCE_AND_TRACEABILITY.md` để check evidence.

## Với DBA/Supabase operator

1. `03_DATA_MODEL_RLS_AND_MIGRATIONS.md`.
2. `database/README.md`.
3. Migration relevant.
4. Verify query and RLS two-user smoke test.

## Với Codex

Không tự suy đoán từ tên file. Đọc theo scope task. Không đọc `references/BD_AUTH_001.md` nếu DD feature và dependency đã đủ. Khi DD mâu thuẫn với BD, dừng coding, ghi rõ xung đột vào worklog và yêu cầu quyết định product/technical owner.
