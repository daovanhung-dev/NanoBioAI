Commit de xuat: docs(worklog): ghi nhan sua candidate pool onboarding

# Worklog - M02 onboarding schedule candidate pool

## Thoi gian

- Ngay: 2026-10-16
- Bat dau: tiep tuc tu ngu canh truoc; khong co timestamp bat dau tin cay
- Ket thuc: 11:52
- Timezone: Asia/Ho_Chi_Minh

## Pham vi

- Loai task: bugfix, test tap trung, cap nhat handoff
- Module chinh: M02 personal schedule AI, onboarding
- Yeu cau goc: fix khong tao duoc lich ca nhan sau onboarding; giu cổng rights/data cua catalog 3.000 mon.

## Da lam

- Xac nhan source cause: strict meal candidate filter loai ca 163 mon legacy cho profile co muc tieu/condition can evidence nutrition hoac constraint da review; tap ma theo tung slot rong lam generation va fallback cung that bai.
- Them policy rieng `wellnessSchedule` cho `GeneratedPlanService` personal schedules (initial guest va additional); `strict` van la mac dinh cho caller khac.
- Giu allergy/avoid fail-closed, chi dung condition-conflict tag de loai mon khi metadata condition da verified; tang huong dan prompt de tranh khang dinh y khoa/dinh duong chua co evidence.
- Tang staging prompt version len `personal_schedule_v11_wellness_candidate_policy` de khong resume chunk duoc tao theo prompt/policy cu.
- Them selector regression tren asset 163 mon va synthetic service regression cho profile `lose_weight` + `diabetes`; prompt regression cho cac gioi han wellness.
- Khong dua 3.000 candidate vao asset, SQLite hoac prompt vi rights va du lieu chua duoc xac nhan; giu nguyen JSON goc.

## File code/docs da sua

- `lib/app_versions/v1/features/meal_plan/domain/services/meal_candidate_selector.dart` - tach strict vs wellness selection.
- `lib/app_versions/v1/services/ai/generated_plan_service.dart` - initial schedule dung wellness policy va invalidate staging prompt version.
- `lib/app_versions/v1/services/ai/prompts/meal_plan_prompt.dart` - noi ro gioi han goi y khi thieu evidence.
- `test/app_versions/v1/features/meal_plan/meal_candidate_selector_test.dart` - kiem chung asset legacy va allergy fail-closed.
- `test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart` - fake onboarding schedule voi goal/condition va assert ma du dieu kien moi slot.
- `test/app_versions/v1/services/ai/prompts/meal_plan_prompt_test.dart` - prompt safety regression.
- `docs/fixbug/onboarding-unverified-catalog-block/002-fixbug-onboarding-schedule-empty-candidate-pool.md` - root cause, patch, evidence va boundary.
- `docs/checklist/checklist_task_coding.md` - cap nhat handoff M02.
- `.codex/history/*`, `.codex/task-skills/*` - refresh generated project context tu worklog (19 files deterministic).

## Tai lieu lien quan

- `docs/fixbug/onboarding-unverified-catalog-block/001-fixbug-onboarding-unverified-catalog-block.md`
- `docs/meal_catalog/3000_recipe_dataset_intake.md`
- `docs/meal_catalog/3000_recipe_dataset_review_2026-10-16.md`

## Commands

- `flutter test test/app_versions/v1/features/meal_plan/meal_candidate_selector_test.dart test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart test/app_versions/v1/features/meal_plan/meal_plan_unclassified_catalog_test.dart test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart test/app_versions/v1/services/ai/prompts/meal_plan_prompt_test.dart test/app_versions/v1/features/meal_plan/presentation/utils/meal_catalog_candidate_asset_gate_test.dart test/features/meal_plan/data/meal_plan_ai_normalizer_test.dart --reporter compact`: PASS, 52 tests.
- `dart analyze lib/app_versions/v1/features/meal_plan/domain/services/meal_candidate_selector.dart lib/app_versions/v1/services/ai/generated_plan_service.dart lib/app_versions/v1/services/ai/prompts/meal_plan_prompt.dart test/app_versions/v1/features/meal_plan/meal_candidate_selector_test.dart test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart test/app_versions/v1/services/ai/prompts/meal_plan_prompt_test.dart`: PASS, no issues.
- `dart format --set-exit-if-changed` on the six touched Dart files: PASS, no changes required.
- `git diff --check`: PASS.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`: PASS, refreshed 19 deterministic history/task-skill files.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: FAIL on existing repository-wide issues: missing `docs/audit/source_truth_manifest.json` and stale backticked paths in generated history/task-skill files; no new path from this fix was reported.
- Device/Gemini integration: SKIPPED; only fake backend and synthetic profiles used.
- SQLite catalog v36 / 3.163-row runtime bundle: SKIPPED; rights and review intake gate remains unmet.

## Loi/Rui ro

- Da fix: empty candidate set caused solely by unverified wellness nutrition/condition evidence no longer blocks general initial schedules.
- Chua fix: explicit or ambiguous food constraints without reviewed catalog metadata still stop generation by design; raw allergy-note parsing was not changed.
- Can kiem tra tiep: device acceptance with a disposable synthetic QA profile; collect rights and field review for all 3.000 candidate recipes before runtime integration.

## Ty le hoan thanh

- Hoan thanh: source fix, synthetic regression coverage, focused tests/analyze, documentation.
- Dang do: device acceptance; requested runtime integration of 3.000 new recipes remains gated on per-recipe rights/data evidence.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - general wellness generation is separated from medical-evidence filtering, while explicit food constraints remain fail-closed.
- Muc do hoan thanh task: source-level onboarding bug fix complete; device result and 3.000 candidate runtime import incomplete.
- Bang chung kiem chung: 52 focused Flutter tests and targeted Dart analysis pass; no Gemini, real health profile, SQLite v36, or device schedule generation.
- Diem ton token/chua toi uu: loaded nearby fixbug/worklog after resolving the actual root cause; initial combined test output was noisy due diagnostic prints.
- Cach toi uu cho phien sau: use the existing QA package/synthetic health profile, confirm onboarding state and catalog contents before device acceptance; run rights intake validator before migration work.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
