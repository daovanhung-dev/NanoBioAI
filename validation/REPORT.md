# Validation report — Supabase meal catalog source fidelity

Date: 2026-08-14
Repository: `daovanhung-dev/NanoBioAI` (`main`)

## Vị trí file đã xác định

- Source of truth: `docs/note/Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md`
- Supabase schema: `docs/supabase/setup.sql`
- Supabase seed: `docs/supabase/seed_data.sql`
- Existing canonical JSON: `assets/data/meal_catalog_v1.json`
- Existing importer: `tools/import_meal_catalog.py`
- Existing validator: `tools/validate_meal_catalog.py`
- Local SQLite schema: `lib/core/storage/localdb/tables/meal_catalog_table.dart`

## Evidence

- Markdown declares 64 topics and 163 recipes across 11 chapters.
- Existing JSON catalog declares the same 163/64/11 contract and uses source-faithful structured fields.
- Current `seed_data.sql` source block starts with `src_c01_thieu_mau_01_canh_thit_bo_rau_cai_bo_xoi` and ends with `src_c13_benh_tang_sinh_xuong_03_nuoc_hat_dau_nanh_vung_den` before `commit;`.
- SQL rows carry per-recipe `source_hash`, `source_page`, `source_chapter`, `source_topic`, and `source_recipe_order`.
- Source rows are marked `nutrition_status='missing_source_data'`, `constraint_metadata_status='awaiting_professional_review'`, `metadata_status='source_imported'`, `is_plan_eligible=false`.
- Numeric nutrition fields use `0` sentinel in SQL. This matches NanoBio local SQLite's `NOT NULL DEFAULT 0` schema; therefore the patch intentionally does not change those columns to NULL.

## Improvement delivered

The new deterministic sync tool removes manual editing of the 163 SQL statements. Re-running it regenerates all source-derived SQL fields directly from Markdown and updates every source/metadata field on conflict. `--check` makes source drift detectable in CI/review.

The SQL assertion file provides runtime count/state guards after a destructive local/sandbox rebuild.

## Limitation of this session

Direct `git clone` from the execution container was blocked by DNS (`Could not resolve host: github.com`). Repository inspection was therefore performed through the connected GitHub API. The ZIP contains an apply-ready deterministic patch rather than claiming an unperformed local Git commit.
