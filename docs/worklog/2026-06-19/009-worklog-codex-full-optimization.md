Commit de xuat: docs(worklog): ghi nhan phien codex full optimization

# Worklog - Codex full optimization

## Thoi gian
- Ngay: 2026-06-19
- Bat dau: Khong ghi nhan tu dong
- Ket thuc: Khong ghi nhan tu dong
- Timezone: Asia/Saigon

## Pham vi
- Loai task: docs
- Module chinh: `.codex`
- Yeu cau goc: Implement ke hoach toi uu `.codex` cho NanoBio/BioAI, giu workflow hien co, cap nhat repo map, tiet kiem token va mo ta `.codex` sau khi sua.

## Da lam
- Kiem tra trang thai dirty hien co de khong cham vao `.codex.zip`, `.env`, `docs/todo` dang bi xoa, hoac docs/DD ngoai scope.
- Cap nhat `.codex` theo huong lean: entrypoint ngan, read order ro, context strategy inventory -> hotspot, va stop condition.
- Cap nhat `PROJECT_MAP.md` theo feature folders hien co trong repo.
- Giu workflow mode hien co: `coding`, `test`, `find-issues`, `create-issues`, `create-todo`, `fix-issues`.
- Chuan hoa prompt mau 00-09 sang ASCII de tranh loi hien thi encoding trong terminal.
- Bo sung playbook AI cho AI Chat, dotenv/API key va context/token growth.

## File code/docs da sua
- `.codex/README.md` - sua - entry point ngan va mo ta cau truc `.codex`.
- `.codex/AGENTS.md` - sua - read order, context strategy, mode separation va DoD.
- `.codex/PROJECT_MAP.md` - sua - map du source/test/docs/features hien co.
- `.codex/TOKEN_SAVING_RULES.md` - sua - 3 muc lay context, stop conditions, budget theo task.
- `.codex/DOCS_WORKFLOW.md` - sua - template/workflow docs ASCII, giu vi tri file.
- `.codex/ISSUE_TODO_WORKFLOW.md` - sua - tach mode issue/todo/fix ro hon.
- `.codex/CHECKLIST.md` - sua - checklist mode/module/playbook/docs/test.
- `.codex/prompts/*.md` - sua - prompt mau gon, ASCII, dong bo mode.
- `.codex/playbooks/ai_service.md` - sua - them AI Chat/dotenv/context token notes.
- `docs/worklog/2026-06-19/009-worklog-codex-full-optimization.md` - tao - ghi nhan phien.

## Tai lieu lien quan
- Khong phat sinh feature/fixbug/test/issue/todo rieng.

## Commands
- `git status --short`: PASS - xac dinh dirty files truoc khi sua.
- `Get-ChildItem -Recurse -File .codex`: PASS - kiem tra cau truc `.codex`.
- `git diff -- .codex`: PASS - doi chieu thay doi co san truoc khi sua.
- `Get-Content .codex\README.md`: PASS - smoke read file chinh.
- `Get-Content .codex\AGENTS.md`: PASS - smoke read file chinh.
- `Get-Content .codex\PROJECT_MAP.md`: PASS - smoke read file chinh.
- `Select-String -Path .codex\*.md,.codex\playbooks\*.md,.codex\prompts\*.md -Pattern '<mojibake-markers>'`: PASS - khong thay marker mojibake.
- `git diff --check -- .codex docs\worklog\2026-06-19\009-worklog-codex-full-optimization.md`: PASS - khong co whitespace error; Git canh bao LF se duoc thay bang CRLF khi cham file tren Windows.
- `dart format --set-exit-if-changed .`: SKIPPED - chi sua Markdown `.codex`.
- `flutter analyze`: SKIPPED - chi sua Markdown `.codex`.
- `flutter test`: SKIPPED - chi sua Markdown `.codex`.

## Loi/Rui ro
- Da fix: `.codex` co read order va project map ro hon; prompt mau het phu thuoc vao chuoi Unicode de tranh mojibake terminal.
- Chua fix: Cac thay doi dirty ngoai scope van giu nguyen, gom `.codex.zip`, docs/DD moi, va 2 file `docs/todo` dang bi xoa.
- Can kiem tra tiep: Neu muon chuan hoa line ending toan repo, nen lam task rieng de tranh diff lon.
