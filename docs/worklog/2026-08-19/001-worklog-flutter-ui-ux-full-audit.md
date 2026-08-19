Commit de xuat: docs(audit): ghi nhan full Flutter UI UX audit

# Worklog - Flutter UI UX Full Audit

## Thoi gian
- Ngay: 2026-08-19
- Bat dau: 00:44
- Ket thuc: trong cung phien
- Timezone: Asia/Bangkok (UTC+7)

## Pham vi
- Loai task: find-issues / UI-UX audit
- Module chinh: toan bo presentation V1/V2/V3/Sale/Admin + shared UI/Nabi/theme/router/state cross-screen
- Yeu cau goc: audit toan bo UI/UX, khong sua runtime code, tao master report + screen inventory + duplication report.
- Baseline: `30587ab9b04d95aa621e5412502aafd0d0ca4827`

## Da lam
- Read AGENTS/.codex workflow/domain/design context.
- Reconcile V1/V2/V3/Admin route trees and guards.
- Reconcile 80-surface design registry and discover Settings tab as additional runtime surface (81 total).
- Inspect high-impact page/widget/provider sources, cross-screen state and interaction paths.
- Record 36 evidence-backed/potential issues; separate UX improvements and potential bugs.
- Create audit Markdown artifacts only; no Dart/SQL/assets modified.

## File code/docs da sua
- `docs/audit/FLUTTER_UI_UX_FULL_AUDIT.md` - tao - main audit report
- `docs/audit/UI_UX_SCREEN_INVENTORY.md` - tao - route/screen coverage ledger
- `docs/audit/UI_UX_DUPLICATION_REPORT.md` - tao - duplication/drift report
- `docs/worklog/2026-08-19/001-worklog-flutter-ui-ux-full-audit.md` - tao - session evidence

## Tai lieu lien quan
- `.codex/workflows/find-issues.md`
- `.codex/task-skills/find-issues.md`
- `.codex/domains/ui-nami.md`
- `.codex/design/12_UI_FILE_DESIGN_MATRIX.md`

## Commands / validation
- GitHub authenticated connector reads: PASS - baseline source inspected.
- Local report structural validation: PASS - required headings, issue IDs and 81 screen entries generated.
- ZIP integrity check: PASS (performed after artifact generation).
- `flutter analyze/test/build`: SKIPPED - audit-only, no checkout/runtime edit.
- `.codex/tools/validate_codex_integrity.ps1`: SKIPPED - no local repository checkout and no `.codex` file modified in artifact package.
- `git diff --check`: SKIPPED - Git clone unavailable due environment DNS; package contains new docs only.

## Loi/Rui ro
- Da fix: none; task audit-only.
- Chua fix: all BUG-UI-* remain TODO by design.
- Can kiem tra tiep: runtime/golden/device QA for Potential Issues, especially 320/360px, textScale 1.5, keyboard dialogs, dark mode and rapid double-tap flows.

## Ty le hoan thanh
- Hoan thanh: route/surface audit report and evidence consolidation complete for baseline.
- Dang do: runtime device verification not possible in connector-only environment; explicitly labeled rather than inferred.

## Tu danh gia va toi uu phien sau
- Chat luong dau ra: tot - issue da phan tach confirmed/potential/recommendation, co source va fix direction.
- Muc do hoan thanh task: cao; artifact docs complete, runtime QA remains separate evidence layer.
- Bang chung kiem chung: router/source/provider/design reads at locked commit; local artifact checks.
- Diem ton token/chua toi uu: GitHub connector khong co code-search/archive nen phai doc nhieu file targeted.
- Cach toi uu cho phien sau: clone repo/local rg first when network checkout is available; generate machine inventory from AST/rg then deep-read only suspicious hits.
- Task-skill can doc lan sau: `.codex/task-skills/find-issues.md`