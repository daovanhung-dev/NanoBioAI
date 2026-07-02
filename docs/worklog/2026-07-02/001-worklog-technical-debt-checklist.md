Commit de xuat: docs(worklog): ghi nhan phien technical debt checklist

# Worklog - Technical debt checklist

## Thoi gian

- Ngay: 2026-07-02
- Bat dau: 14:00
- Ket thuc: 14:15
- Timezone: Asia/Saigon

## Pham vi

- Loai task: docs-context
- Module chinh: docs/checklist, technical debt audit summary
- Yeu cau goc: Tao checklist no ky thuat toan du an tu `.codex`, issue/todo hien co, analyzer/test/format va targeted scan; khong sua runtime code, khong tao issue docs rieng, khong doc/in noi dung `.env`.

## Da lam

- Nap lai context NanoBio qua `.codex/AGENTS.md`, `.codex/PROJECT_MAP.md`, `.codex/history/LEARNED_SKILLS.md`, workflow `docs-context`, `DOCS_WORKFLOW`, task-skill `docs-context`, va open risk register.
- Rerun evidence checks theo plan: `git status --short`, `flutter analyze`, `flutter test`, format dry-run, targeted `rg` cho env/security/logging/architecture/TODO/planned debt.
- Tao `docs/checklist/checklist_technical_debt.md` gom cac no ky thuat uu tien P0/P1/P2, evidence, impact, suggested next action va link issue/todo/risk hien co.
- Khong sua runtime code, schema, route, test code, hoac noi dung `.env`.

## File code/docs da sua

- `docs/checklist/checklist_technical_debt.md` - tao - checklist no ky thuat toan repo.
- `docs/worklog/2026-07-02/001-worklog-technical-debt-checklist.md` - tao - ghi nhan phien docs-context.

## Tai lieu lien quan

- `.codex/workflows/docs-context.md`
- `.codex/DOCS_WORKFLOW.md`
- `.codex/history/OPEN_RISKS.md`
- `docs/todo/issue-todo-checklist/001-todo-issue-todo-checklist.md`
- `docs/checklist/checklist_task_coding.md`
- `docs/issues/ai-raw-payload-logging/001-issue-ai-raw-payload-logging.md`
- `docs/issues/onboarding-sensitive-snapshot-logging/001-issue-onboarding-sensitive-snapshot-logging.md`

## Commands

- `git status --short`: PASS - worktree da co nhieu thay doi san co truoc phien; phien nay khong revert/cham vao cac thay doi ngoai checklist/worklog/history.
- `flutter analyze`: FAIL_EXPECTED - 97 issues; dung lam evidence cho release/analyzer debt.
- `flutter test`: FAIL_EXPECTED - 438 pass / 27 fail; dung lam evidence cho release/test debt.
- `dart format --output=none --set-exit-if-changed lib test`: FAIL_EXPECTED - 21 Dart files would change; dung lam evidence format debt, khong ghi file.
- `rg` targeted cho `.env`, logging, architecture violations, TODO/planned markers: PASS - thu thap duoc evidence line/path cho checklist.

## Loi/Rui ro

- Da fix: Chua fix runtime debt; chi tao checklist tai lieu.
- Chua fix: Tat ca debt trong `docs/checklist/checklist_technical_debt.md` van open/tracked/needs verification.
- Can kiem tra tiep: Sau khi refresh history, chay docs integrity, `git diff --check`, va targeted `rg` de xac nhan link/path checklist.

## Ty le hoan thanh

- Hoan thanh: Checklist technical debt va worklog session.
- Dang do: Validation docs/context va history refresh can chay tiep sau khi ghi file.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - checklist gom du evidence command/path/line, tach debt theo priority, khong dua secret/log tho vao docs.
- Muc do hoan thanh task: Da tao artifact chinh; chua fix debt vi ngoai scope.
- Bang chung kiem chung: `flutter analyze`, `flutter test`, format dry-run, targeted `rg`; validation docs/context se chay sau worklog.
- Diem ton token/chua toi uu: `flutter test` log rat dai; lan sau nen dung reporter/summary neu chi can so lieu pass/fail va fail group.
- Cach toi uu cho phien sau: Doc checklist technical debt truoc khi tao issue/fix; chon tung debt theo priority thay vi audit lai toan repo.
- Task-skill can doc lan sau: `.codex/task-skills/docs-context.md`
