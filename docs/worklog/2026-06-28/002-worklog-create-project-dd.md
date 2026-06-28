Commit de xuat: docs(dd): tao DD toan du an tu BD v2

# Worklog - Create project DD from BD v2

## Thoi gian

- Ngay: 2026-06-28
- Bat dau: trong phien Codex hien tai
- Ket thuc: trong phien Codex hien tai
- Timezone: Asia/Saigon

## Pham vi

- Loai task: docs-dd
- Module chinh: docs/DD M01-M19
- Yeu cau goc: Tao bo DD toan du an tu `docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md` theo `docs/DD/DD_Module_Template/`.

## Da lam

- Tao `docs/DD/README.md` lam entry point DD toan du an.
- Tao 19 DD module folder M01-M19, moi folder co README, Overall, List_Features, Function_List, Views, Import_File, diagrams README, assets README va history CHANGELOG.
- Cap nhat checklist tao DD cho `BD-BIOAI-PRODUCT-FLOW-002`.
- Cap nhat `.codex/MAP_TREE.md` de them inventory DD module.
- Giu tat ca module o `Status: Draft` vi BD con Q-01..Q-18.

## File code/docs da sua

- `docs/DD/README.md` - tao - entry point DD toan du an.
- `docs/DD/<module>/...` - tao - DD module M01-M19.
- `docs/checklist/checklist_create_DD.md` - sua - them checklist BD v2.0.
- `.codex/MAP_TREE.md` - sua - them inventory DD module.
- `docs/worklog/2026-06-28/002-worklog-create-project-dd.md` - tao - ghi nhan phien.

## Tai lieu lien quan

- `.codex/AGENTS.md`
- `.codex/workflows/docs-dd.md`
- `.codex/task-skills/docs-dd.md`
- `.codex/skills/create-dd-from-bd/SKILL.md`
- `.codex/skills/create-dd-from-bd/references/dd-module-from-bd.md`
- `docs/DD/DD_Module_Creation_Guide_EN.md`
- `docs/DD/DD_Module_Template/README.md`
- `docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md`

## Commands

- `rg "\{\{|\[MODULE_CODE\]" docs/DD -g '!docs/DD/DD_Module_Template/**' -g '!docs/DD/DD_Module_Creation_Guide_EN.md' -g '!DD_Module_Template/**' -g '!DD_Module_Creation_Guide_EN.md'`: PASS - generated DD files have no template placeholders.
- `rg -n "tầng 2|5%|cây Sale" docs/DD -g '!DD_Module_Template/**'`: PASS_WITH_NOTES - matches only appear as banned/out-of-scope legacy Sale logic.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`: PASS - refreshed `.codex/history` and `.codex/task-skills`.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: PASS - after updating `.codex/PROJECT_MAP.md` to the BD v2.0 path.
- `git diff --check`: PASS - only CRLF normalization warnings from Git.

## Loi/Rui ro

- Da fix: Khong ap dung logic Sale cu hai tang trong DD moi; cap nhat stale BD path trong `.codex/PROJECT_MAP.md`; xoa trailing whitespace trong checklist.
- Chua fix: Q-01..Q-18 van la open questions; Q-02..Q-10 va Q-17 chan coding tai chinh/Sale.
- Can kiem tra tiep: API contract, schema/RLS vat ly, UI mockup, payment provider, refund/chargeback policy.

## Ty le hoan thanh

- Hoan thanh: Tao baseline DD toan du an M01-M19.
- Dang do: Chua Ready for implementation cho cac module phu thuoc open decisions.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - tao du cau truc DD theo template va trace BD v2.0.
- Muc do hoan thanh task: hoan thanh baseline docs-only; can PO/Tech Lead review de chot open questions.
- Bang chung kiem chung: placeholder check PASS, Sale legacy check PASS_WITH_NOTES, history refresh PASS, codex integrity PASS, git diff check PASS.
- Diem ton token/chua toi uu: tao 19 module trong mot phien ton nhieu noi dung lap; lan sau co the chia theo module uu tien.
- Cach toi uu cho phien sau: doc `docs/DD/README.md` truoc, sau do mo dung module can implement.
- Task-skill can doc lan sau: `.codex/task-skills/docs-dd.md`
