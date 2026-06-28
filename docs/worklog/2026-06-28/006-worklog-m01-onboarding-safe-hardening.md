Commit de xuat: feat(onboarding): harden M01 onboarding local flow

# Worklog - M01 Onboarding Safe Hardening

## Thoi gian

- Ngay: 2026-06-28
- Bat dau: trong phien Codex hien tai
- Ket thuc: 2026-06-28 20:20:37 +07:00
- Timezone: Asia/Saigon (+07:00)

## Pham vi

- Loai task: coding
- Module chinh: M01 `ONBOARDING_PROFILE`
- Yeu cau goc: Implement plan Coding M01 safe hardening cho onboarding v1 local flow, khong code phan bi Q-14/Q-15, Supabase schema/RLS, FamilyPlus subject, consent nang cao, health formula, route/payment/admin behavior chan.

## Da lam

- Them DB injection optional cho `OnboardingLocalDatasource` de test SQLite in-memory, runtime provider van co the dung constructor const mac dinh.
- Harden logging trong onboarding controller: thay raw form values/health numbers/user marker bang status/count/provided/empty; generic save error khong noi truc tiep exception.
- Bo raw `OnboardingEntity.toDebugMap()` vi chua co caller va co nguy co expose PII/health data neu dung de log.
- Them local datasource tests cho guest save, profile/goals/conditions/lifestyle/allergy/treatment/survey answers, re-save replacement, mark completed, va durable sync outbox marker.
- Mo rong completion flow tests cho save/callback/mark completed, skipped initial plan, duplicate submit, va captured log khong chua raw sensitive markers.
- Cap nhat entry page test anchors va fixed-pump behavior de phu hop onboarding UI hien tai co animation lien tuc.
- Cap nhat checklist M01: coding progress tang cho local hardening da verify, DD status van `Draft`.

## File code/docs da sua

- `lib/app_versions/v1/features/onboarding/data/datasource/onboarding_local_datasource.dart` - sua - DB injection, safe local save logging, bo raw SQLite snapshot log.
- `lib/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart` - sua - sanitize form/save logs va safe user-facing save error.
- `lib/app_versions/v1/features/onboarding/domain/entities/onboarding_entity.dart` - sua - xoa raw debug map khong an toan.
- `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_entry_page.dart` - sua - them CTA keys de tests bam dung entry actions.
- `lib/app_versions/v1/features/onboarding/presentation/widgets/nabi_onboarding_experience.dart` - sua - giu text button khong overflow trong compact animated UI.
- `test/app_versions/v1/features/onboarding/onboarding_local_datasource_test.dart` - tao - test SQLite in-memory cho local persistence M01.
- `test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart` - sua - them handoff/duplicate submit/log sanitization coverage.
- `test/app_versions/v1/features/onboarding/onboarding_entry_page_test.dart` - sua - tranh `pumpAndSettle` timeout voi animation lien tuc.
- `docs/checklist/checklist_complete_DD.md` - sua - cap nhat M01 coding progress va next blocker.
- `docs/checklist/checklist_task_coding.md` - sua - ghi note phien coding M01.
- `docs/worklog/2026-06-28/006-worklog-m01-onboarding-safe-hardening.md` - tao - ghi nhan phien.

## Tai lieu lien quan

- `docs/checklist/checklist_complete_DD.md`
- `docs/checklist/checklist_task_coding.md`
- `.codex/workflows/coding.md`
- `.codex/domains/onboarding.md`

## Commands

- `flutter test test/app_versions/v1/features/onboarding`: PASS - 10 onboarding tests passed.
- `flutter test test/core/storage/localdb/migration_manager_test.dart test/services/supabase/cloud_sync/user_data_sync_outbox_test.dart`: PASS - 9 storage/cloud-sync tests passed.
- `flutter test test/architecture_version_boundary_test.dart test/architecture_preservation_property_test.dart`: PASS - 24 architecture tests passed.
- `powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1`: FAIL - stopped at `flutter analyze` with 47 repo-wide issues, mostly existing Nabi analyzer/case-sensitive warnings and unrelated deprecations/import warnings outside this M01 slice.

## Loi/Rui ro

- Da fix: raw onboarding save/form logs trong touched flow khong con ghi name/email/phone/concern/user id/BMI/raw snapshot/expected stack trace.
- Da fix: duplicate submit trong completion flow khong tao save/callback lan hai trong test.
- Chua fix: M01 van `Draft`; Supabase/profile sync, FamilyPlus subject/consent, health formula Q-14/Q-15 chua chot.
- Chua fix: Quick check toan cuc fail o `flutter analyze` do analyzer issues ngoai pham vi M01.
- Can kiem tra tiep: Khi Q-14/Q-15 va Supabase/FamilyPlus contract duoc chot, can them cloud sync/subject/consent acceptance tests.
- Can kiem tra tiep: Worktree da co nhieu thay doi onboarding/Nabi/cloud-sync truoc phien nay; khong revert cac thay doi khong thuoc M01 safe hardening.

## Ty le hoan thanh

- Hoan thanh: Safe local hardening cho M01 `ONBOARDING_PROFILE-F01/F02` va tests muc tieu.
- Dang do: Phan cloud/FamilyPlus/health-formula cua M01 chua code vi bi open decisions chan.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - co runtime hardening, regression tests, va checklist update theo blocker hien tai.
- Muc do hoan thanh task: hoan thanh trong pham vi safe hardening duoc phep.
- Bang chung kiem chung: onboarding tests, storage/cloud-sync targeted tests, architecture tests; quick check fail duoc ghi ro.
- Diem ton token/chua toi uu: can doc va fix test entry UI do worktree co animated onboarding UI thay doi truoc do.
- Cach toi uu cho phien sau: chot scope blocker truoc, sau do chi doc/validate phan cloud sync hoac FamilyPlus duoc unlock.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
