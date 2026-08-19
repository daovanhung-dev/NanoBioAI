Commit de xuat: fix(ui): khac phuc UI UX audit toan he thong

# Worklog - Fix UI UX full audit

## Thoi gian

- Ngay: 2026-08-19
- Bat dau: phien hien tai
- Ket thuc: phien hien tai
- Timezone: Asia/Saigon

## Pham vi

- Loai task: bugfix
- Module chinh: V1 UI, V2 auth/access, V3 FamilyPlus/Advanced Tracking, Admin, Sale, shared router/theme/design docs
- Yeu cau goc: thuc thi plan fix 36 issue tu `FLUTTER_UI_UX_FULL_AUDIT.md`.
- Baseline: `30587ab9b04d95aa621e5412502aafd0d0ca4827`

## Da lam

- Fix cac issue P1 ve stale state, time-boundary, trusted Sale error va duplicate mutation.
- Bien Quick Care va Weekly Summary thanh UI co user job/data source that thay vi dead/static surface.
- Sua navigation/back/return-intent va route duplication.
- Hop nhat Meal Replacement picker.
- Sua responsive cho Features Hub, Nutrition, Meal Plan va Admin dialog/touch target.
- Sua AI Chat auto-scroll/system bars va AI Voice back-stack.
- Tach Supabase Storage upload khoi Admin presentation dung Clean Architecture.
- Bo fake onboarding health score va Splash fail-open.
- Cap nhat Settings design registry va canonical consumer naming.
- Them source regression guard suite cho cac invariant co nguy co tai phat.

## File code/docs da sua

- Xem package ban giao `NanoBioAI_UI_UX_Fix.zip`; moi file trong ZIP la file moi/da sua va giu nguyen duong dan tu root repository.
- Chi tiet issue/file mapping: `docs/fixbug/ui-ux-audit/001-fixbug-ui-ux-full-audit.md`.

## Tai lieu lien quan

- `docs/audit/FLUTTER_UI_UX_FULL_AUDIT.md`
- `.codex/AGENTS.md`
- `.codex/workflows/bugfix.md`
- `.codex/task-skills/bugfix.md`
- `.codex/domains/ui-nami.md`
- `.codex/domains/access-membership-referral.md`
- `.codex/design/12_UI_FILE_DESIGN_MATRIX.md`

## Commands

- Custom source invariant scan: PASS - 40/40 guards.
- Custom Dart lexical balance scan: PASS - 0 delimiter/string/comment error.
- Targeted forbidden-pattern `grep`: PASS.
- `dart format`: SKIPPED/BLOCKED - container khong co Dart executable.
- `flutter analyze`: SKIPPED/BLOCKED - container khong co Flutter executable.
- `flutter test`: SKIPPED/BLOCKED - container khong co Flutter executable.
- quick/full/native check: SKIPPED/BLOCKED - container khong co Flutter/PowerShell project runtime.
- GitHub branch/push: BLOCKED - connector tra 403 khi tao branch.

## Loi/Rui ro

- Da fix: 36 audit issue o source overlay theo mapping fixbug.
- Chua fix: khong co issue audit nao duoc co y bo qua trong overlay scope.
- Can kiem tra tiep: analyzer/widget test/debug APK tren workstation co Flutter SDK truoc khi release.

## Ty le hoan thanh

- Hoan thanh source implementation: 100% theo 36 audit issue.
- Runtime verification: bi chan boi toolchain cua environment, khong duoc tinh la PASS.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - fix theo batch, giu trusted boundaries va bo production fake data.
- Muc do hoan thanh task: source implementation day du; runtime validation can chay tren may co Flutter SDK.
- Bang chung kiem chung: 40 source guards, lexical scan, targeted pattern checks, exact baseline GitHub reads.
- Diem ton token/chua toi uu: repo khong clone duoc va GitHub write bi 403 nen phai doc file muc tieu qua connector va tao local overlay.
- Cach toi uu cho phien sau: neu co writable checkout, chay targeted format/analyze/test ngay sau tung batch va commit nho theo nhom issue.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`
