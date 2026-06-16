# BioAI Codex Context

Thu muc `.codex` nay la bo context nen doc dau tien trong cac phien lam viec sau. Muc tieu la giup Codex hieu nhanh du an ma khong can quet lai toan bo repo tu dau.

## Thu tu doc khuyen nghi

1. `handoff_prompt.md` - prompt ngan de nap dung "vai" va cach tiep can du an.
2. `project_context.md` - tong quan san pham, tech stack, trang thai hien tai.
3. `architecture.md` - kien truc Flutter/Riverpod/GoRouter, luong phu thuoc, module.
4. `features_and_workflows.md` - cac feature dang co va luong nghiep vu quan trong.
5. `data_and_storage.md` - SQLite schema, datasource, DAO, model, SharedPreferences.
6. `api_reference.md` - Supabase, Gemini AI, env vars, service contract.
7. `design_system.md` - theme/design system, component primitive, cach dung.
8. `testing_and_quality.md` - test suite, lenh chay, test nao co chu dich fail.
9. `known_gaps_and_refactor_notes.md` - no ky thuat, lech tai lieu-vs-code, refactor uu tien.

## Nguon su that

- Code hien tai trong `lib/` la nguon uu tien khi mau thuan voi tai lieu cu.
- `README.md` mo ta app hien tai voi meal plan 7 ngay.
- `docs/DD/DD_Module` mo ta tam nhin product theo chu ky 30 ngay.
- `test/architecture_preservation_property_test.dart` ghi cac hanh vi can giu khi refactor.
- `test/architecture_violation_exploration_test.dart` co chu dich fail tren code chua refactor het; dung nhu bo check kien truc sau refactor.

## Ghi chu nhanh

- App la Flutter health/nutrition app ten BioAI / `nano_app`.
- Offline-first: SQLite local la trung tam du lieu suc khoe va meal plan.
- Supabase hien chu yeu dung cho auth.
- Gemini dung cho sinh thuc don va AI chat.
- `.env` co secret that, khong doc/ghi vao tai lieu. Dung `.env.example` va `api_reference.md`.
