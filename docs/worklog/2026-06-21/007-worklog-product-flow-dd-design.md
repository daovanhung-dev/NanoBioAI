Commit de xuat: docs(dd): tao DD product flow membership sale

# Worklog - Product Flow DD Design

## Thoi gian

- Ngay: 2026-06-21
- Bat dau: khong ghi nhan tu dong
- Ket thuc: khong ghi nhan tu dong
- Timezone: Asia/Saigon

## Pham vi

- Loai task: docs
- Module chinh: Product Flow, Membership, Quota, FamilyPlus, Sale/referral, DD workflow.
- Yeu cau goc: Doc BD product flow, tao checklist DD, tao bo DD trong `docs/DD`, cap nhat checklist global va duc ket rule vao `.codex`.

## Da lam

- Tao folder `docs/DD/product_flow/` voi 17 DD theo module folder style.
- Mapping BR-01..08, AC-01..11, UC-01..15 vao DD feature/test.
- Giu cac phan phu thuoc Q-01..Q-10 o `Status: Draft` va ghi open decisions.
- Tao checklist source canh BD va cap nhat checklist global.
- Tao playbook `.codex/playbooks/dd_creation.md`.
- Cap nhat `.codex` context de cac phien sau biet quy trinh tao/doc DD.

## File code/docs da sua

- `docs/DD/product_flow/` - tao - bo DD Product Flow/Membership/Sale.
- `docs/BD/project_flow/checklist_create_DD_product_flow_membership_sale.md` - tao - checklist source theo BD.
- `docs/checklist/checklist_create_DD.md` - sua - checklist global tao DD.
- `.codex/playbooks/dd_creation.md` - tao - playbook tao DD tu BD.
- `.codex/README.md` - sua - them playbook DD creation.
- `.codex/AGENTS.md` - sua - them read order/playbook DD creation.
- `.codex/PROJECT_MAP.md` - sua - them routing DD product flow.
- `.codex/DOCS_WORKFLOW.md` - sua - them rule tao DD/checklist.
- `.codex/CHECKLIST.md` - sua - them checklist DD creation.
- `.codex/MAP_TREE.md` - sua - cap nhat tree docs/.codex.
- `docs/worklog/2026-06-21/007-worklog-product-flow-dd-design.md` - tao - ghi nhan phien.

## Tai lieu lien quan

- `docs/BD/project_flow/BD_Product_Flow_Membership_Sale.md`
- `docs/BD/project_flow/checklist_create_DD_product_flow_membership_sale.md`
- `docs/checklist/checklist_create_DD.md`
- `docs/DD/product_flow/00_READ_FIRST.md`

## Commands

- `rg --files docs/DD/product_flow docs/BD/project_flow docs/checklist .codex`: PASS - xac nhan co DD product_flow, checklist va playbook `.codex`.
- `rg "BD-BIOAI-PRODUCT-FLOW-001|BR-0|AC-0|UC-" docs/DD/product_flow docs/BD/project_flow docs/checklist`: PASS - xac nhan trace BD/BR/AC/UC trong DD va checklist.
- `git diff --check`: PASS - khong co whitespace error; Git chi canh bao line-ending LF/CRLF tren Windows.
- `flutter analyze` / `flutter test`: SKIPPED - docs-only, khong sua runtime code.

## Loi/Rui ro

- Da fix: Truoc do chua co bo DD product flow/membership/sale tach rieng theo BD moi.
- Chua fix: Q-01..Q-10 van la open decisions, cac DD lien quan chua Ready for implementation.
- Can kiem tra tiep: PO/Tech Lead can chot Q-01..Q-10 truoc khi code cac phan phu thuoc.

## Ty le hoan thanh

- Hoan thanh: 100% pham vi tao DD/checklist/.codex/worklog theo plan.
- Dang do: chua chot open decisions Q-01..Q-10 va chua implement runtime code.
