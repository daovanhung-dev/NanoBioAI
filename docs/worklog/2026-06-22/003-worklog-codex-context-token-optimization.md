Commit de xuat: docs(codex): toi uu context va bridge auto-discovery

# Worklog - Codex context token optimization

## Thoi gian

- Ngay: 2026-06-22
- Bat dau: 07:20
- Ket thuc: 07:26
- Timezone: Asia/Saigon (+07:00)

## Pham vi

- Loai task: docs-context
- Module chinh: `.codex`, root `AGENTS.md`, `.agents` skill bridge
- Yeu cau goc: Cap nhat `.codex` de AI agent lam viec hieu qua hon, tiet kiem token hon, danh gia diem chua toi uu va dua thong tin Codex official vao context layout.

## Da lam

- Them root `AGENTS.md` lam bridge auto-discovery ngan, tro ve `.codex/AGENTS.md` va router `.codex/PROJECT_MAP.md`.
- Them `.agents/skills/nanobio-project-agent/` lam repo-discovered skill wrapper, tro ve canonical skill trong `.codex/skills/nanobio-project-agent/`.
- Cap nhat read-pack de khong doc `.codex/history/RISK_HISTORY.md`, `.codex/MAP_TREE.md`, raw worklog, raw source/test, hoac toan bo DD neu workflow khong yeu cau.
- Rut gon `.codex/MAP_TREE.md` tu full inventory lon/stale thanh compact routing map va lenh `rg --files`.
- Mo rong `.codex/tools/validate_codex_integrity.ps1` de bat bridge thieu va stale concrete backticked paths.

## File code/docs da sua

- `AGENTS.md` - tao - bridge auto-discovery chinh thuc cho Codex.
- `.agents/skills/nanobio-project-agent/SKILL.md` - tao - repo skill wrapper.
- `.agents/skills/nanobio-project-agent/agents/openai.yaml` - tao - metadata cho skill wrapper.
- `.codex/README.md` - sua - read-pack toi thieu va risk/history rule.
- `.codex/AGENTS.md` - sua - ghi ro root bridge va cac file khong doc mac dinh.
- `.codex/CHECKLIST.md` - sua - them rule khong doc inventory/raw risk mac dinh.
- `.codex/MAP_TREE.md` - sua - compact inventory, loai bo stale full tree.
- `.codex/workflows/context-read.md` - sua - `OPEN_RISKS.md` thanh conditional read.
- `.codex/workflows/docs-context.md` - sua - rule cho `MAP_TREE.md` va `RISK_HISTORY.md`.
- `.codex/skills/nanobio-project-agent/SKILL.md` - sua - ghi ro bridge `.agents`.
- `.codex/skills/nanobio-project-agent/references/context-router.md` - sua - read-pack toi thieu.
- `.codex/tools/validate_codex_integrity.ps1` - sua - bridge va stale concrete path validation.
- `.codex/history/*` - regenerate - cap nhat bang history refresh.
- `.codex/task-skills/*` - regenerate - cap nhat bang history refresh.
- `docs/worklog/2026-06-22/003-worklog-codex-context-token-optimization.md` - tao/cap nhat - ghi nhan phien docs-context.

## Tai lieu lien quan

- OpenAI Codex best practices: dung `AGENTS.md` ngan, thuc te, tach file task-specific khi lon.
- OpenAI Codex AGENTS.md: auto-discovery theo root/current directory va project-doc budget.
- OpenAI Codex skills: repo skills dung `.agents/skills` va progressive disclosure.
- OpenAI Codex prompting/context: context phai vua context window, agent nen lay context co muc tieu.

## Commands

- `powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: PASS - validator moi pass truoc khi ghi worklog.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`: PASS - cap nhat tu 27 worklog files; chay lai sau khi cap nhat worklog.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: FAIL/PASS - lan dau bat `.codex/config.toml` va `.codex/rules` trong raw `RISK_HISTORY.md`; da loai raw evidence khoi stale-path check va chay lai PASS.
- `MAP_TREE task-skill stale check`: PASS - 2 concrete task-skill refs, 0 stale refs.
- `MAP_TREE size check`: PASS - 4.29 KB, duoi muc 8 KB.
- `git diff --check`: PASS - khong co whitespace error; chi co Git CRLF warnings.

## Loi/Rui ro

- Da fix: `MAP_TREE.md` co stale legacy task-skill entries va thieu file `.codex` hien co; da compact va validator da them stale path check.
- Da fix: Validator stale-path ban dau quet ca raw `RISK_HISTORY.md`; da bo qua file raw evidence nay cho backticked-path validation.
- Chua fix: Khong them `.codex/config.toml` hoac `.codex/rules` vi ngoai pham vi token/context.
- Can kiem tra tiep: Khong co trong pham vi hien tai.

## Ty le hoan thanh

- Hoan thanh: 100% theo pham vi docs/context.
- Dang do: khong co.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - thay doi dung pham vi docs/context, bridge nho, khong doi runtime.
- Muc do hoan thanh task: hoan thanh cac hang muc trong plan.
- Bang chung kiem chung: validator moi da PASS truoc worklog; history refresh PASS; validator sau refresh PASS sau khi fix raw evidence false positive; stale MAP_TREE check PASS; `git diff --check` PASS.
- Diem ton token/chua toi uu: diff full cua old `MAP_TREE.md` rat lon; phien sau dung `git diff --stat` hoac file cu the thay vi full diff khi map lon.
- Cach toi uu cho phien sau: doc root bridge -> `.codex/AGENTS.md` -> `PROJECT_MAP.md` -> workflow/task-skill; chi mo `MAP_TREE.md` khi can inventory.
- Task-skill can doc lan sau: `.codex/task-skills/docs-context.md`
