Commit de xuat: feat(m09-m10): hoan tat coding notifications va advanced tracking

# Worklog - M09/M10 coding 100 percent

## Thoi gian

- Ngay: 2026-06-30
- Bat dau: 15:00
- Ket thuc: 15:43
- Timezone: Asia/Saigon (+07:00)

## Pham vi

- Loai task: coding
- Module chinh: M09 `SCHEDULE_NOTIFICATIONS`, M10 `ADVANCED_TRACKING_GOALS`
- Yeu cau goc: Implement plan dua M09/M10 len 100% theo code + targeted tests, khong claim Supabase sandbox production evidence.

## Da lam

- M09: mo rong `NotificationPayload` len v2 voi subject/actor/family/correlation metadata, van parse payload cu.
- M09: reminder row id va notification id da co subject key de tranh collision giua package member; refresh chi cancel/delete pending row dung subject.
- M09: action handler bo qua action da xu ly, chan payload source mismatch, subject mismatch va source-owner mismatch truoc khi complete/skip.
- M10: them v3 feature `advanced_tracking` voi domain commands, use cases, repository, SQLite datasource, Riverpod providers va page `/v3/advanced-tracking`.
- M10: hydration la metric dau tien, goal code `advanced_hydration`, target 2000 ml/day, storage dung `health_goals`, progress doc tu `health_tracking_logs.water_ml`, khong tang SQLite version.
- Cap nhat checklist coding progress M09/M10 len 100% theo code+test acceptance va ghi sandbox/real-device smoke la production-readiness evidence rieng.

## File code/docs da sua

- `lib/app_versions/v1/services/notifications/*` - sua - subject-aware payload/scheduling/action handling.
- `lib/app_versions/v3/features/advanced_tracking/` - tao - vertical slice hydration advanced tracking.
- `lib/app_versions/v3/router/*` - sua - them v3 route `/v3/advanced-tracking`.
- `test/services/notifications/*` - sua/tao - M09 payload/schedule/action tests.
- `test/app_versions/v3/features/advanced_tracking/` - tao - M10 use-case/data/provider/widget tests.
- `docs/checklist/checklist_complete_DD.md` - sua - cap nhat M09/M10 coding progress/evidence.
- `docs/checklist/checklist_task_coding.md` - sua - ghi note phien coding M09/M10 va next production evidence.
- `docs/worklog/2026-06-30/006-worklog-m09-m10-coding-100.md` - tao - ghi nhan phien nay.

## Tai lieu lien quan

- `.codex/workflows/coding.md`
- `.codex/task-skills/coding.md`
- `.codex/domains/notification.md`
- `.codex/domains/access-membership-referral.md`
- `.codex/domains/health-tracking.md`
- `docs/DD/schedule_notifications/`
- `docs/DD/advanced_tracking_goals/`

## Commands

- `dart format <touched notification/v3/test files>`: PASS.
- `flutter analyze lib\app_versions\v1\services\notifications lib\app_versions\v3\features\advanced_tracking lib\app_versions\v3\router test\services\notifications test\app_versions\v3\features\advanced_tracking`: PASS - No issues found.
- `flutter test <notification + M10 + cloud_sync_contract + architecture_version_boundary tests>`: PASS - 44 tests passed.
- `git diff --check`: PASS - only LF/CRLF working-copy warnings.
- `powershell -ExecutionPolicy Bypass -File .codex\tool\codex_quick_check.ps1`: FAIL - global quick check passed `flutter pub get` but stopped at repo-wide `dart format --set-exit-if-changed .`; it formatted 7 legacy onboarding/splash files outside M09/M10. Those accidental formatter diffs were restored.

## Loi/Rui ro

- Da fix: M09 subject/action mismatch handling, M10 missing runtime slice, M10 access gate, M10 route-only exposure.
- Chua fix: Flutter test still prints pubspec asset-folder warnings because many asset `.gitkeep` files/directories are already deleted in the dirty worktree outside this task.
- Chua fix: repo-wide quick check is not clean because legacy files outside this task need separate formatting/ownership decision before a global format gate can pass.
- Can kiem tra tiep: real-device local notification delivery/action smoke, Supabase sandbox cross-device sync, Plus/FamilyPlus access and subject/RLS smoke for M10.

## Ty le hoan thanh

- Hoan thanh: M09/M10 coding 100% theo code + targeted tests acceptance.
- Dang do: production-readiness sandbox/real-device evidence outside selected acceptance scope.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - code theo dung layer, co targeted tests cho payload/action/storage/provider/UI va khong doi production entrypoint.
- Muc do hoan thanh task: hoan thanh acceptance da chot cho M09/M10.
- Bang chung kiem chung: targeted analyze pass, targeted test batch 44 pass, `git diff --check` pass.
- Diem ton token/chua toi uu: M10 can tao nhieu file moi nen doc/patch/test ton context; da tranh doc raw worklog va raw source rong.
- Cach toi uu cho phien sau: bat dau tu production smoke M09/M10 hoac sandbox evidence theo checklist, khong mo lai DD raw neu khong can thay doi product rule.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
