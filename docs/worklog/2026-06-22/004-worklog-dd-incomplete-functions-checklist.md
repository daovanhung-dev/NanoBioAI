Commit de xuat: docs(dd): ghi nhan chuc nang DD chua hoan thanh

# Worklog - DD incomplete functions checklist

## Thoi gian

- Ngay: 2026-06-22
- Bat dau: 07:37
- Ket thuc: 07:39
- Timezone: Asia/Saigon (+07:00)

## Pham vi

- Loai task: docs-dd
- Module chinh: `docs/DD/product_flow`, `docs/checklist`
- Yeu cau goc: Doc toan bo DD va xac dinh chuc nang chua hoan thanh, note don gian vao `docs/checklist/checklist_create_DD.md`.

## Da lam

- Doc workflow `.codex/workflows/docs-dd.md`, task-skill `.codex/task-skills/docs-dd.md`, `.codex/DOCS_WORKFLOW.md`, domain access/membership/referral.
- Kiem ke `docs/DD`; working tree hien co chi con `docs/DD/product_flow/*`.
- Doc 17/17 file DD product flow va doi chieu BD/checklist nguon.
- Xac dinh cac nhom chuc nang chua duoc xac nhan hoan thanh theo DD vi van `Status: Draft`, con Q-01..Q-10, con dependency thieu, hoac test matrix van `Draft`.
- Them muc "Chuc nang chua hoan thanh theo DD" vao checklist global.

## File code/docs da sua

- `docs/checklist/checklist_create_DD.md` - sua - cap nhat ngay va them bang ghi chu chuc nang chua hoan thanh theo DD.
- `docs/worklog/2026-06-22/004-worklog-dd-incomplete-functions-checklist.md` - tao - ghi nhan phien docs-dd.

## Tai lieu lien quan

- `docs/DD/product_flow/00_READ_FIRST.md`
- `docs/DD/product_flow/01_DOCUMENT_MAP.md`
- `docs/DD/product_flow/02_MODULE_OVERVIEW.md`
- `docs/DD/product_flow/03_DATA_MODEL_SUPABASE_RLS_AND_MIGRATIONS.md`
- `docs/DD/product_flow/04_FEATURE_GUEST_ONBOARDING_INITIAL_SCHEDULE.md`
- `docs/DD/product_flow/05_FEATURE_AUTH_MEMBERSHIP_ACCESS_GATE.md`
- `docs/DD/product_flow/06_FEATURE_FREE_QUOTA_AI_CHAT_AND_SCHEDULE.md`
- `docs/DD/product_flow/07_FEATURE_HEALTH_SCORE_SCHEDULE_COMPLETION.md`
- `docs/DD/product_flow/08_FEATURE_PLUS_GOAL_ROADMAP_ADVANCED_TRACKING.md`
- `docs/DD/product_flow/09_FEATURE_FAMILYPLUS_MEMBER_HEALTH_AND_SCHEDULE.md`
- `docs/DD/product_flow/10_FEATURE_SALE_REFERRAL_REGISTRATION.md`
- `docs/DD/product_flow/11_FEATURE_PAYMENT_COMMISSION_TWO_LEVEL.md`
- `docs/DD/product_flow/12_FEATURE_NOTIFICATION_SCHEDULE_REMINDERS.md`
- `docs/DD/product_flow/13_ERROR_HANDLING_SECURITY_AND_PRIVACY.md`
- `docs/DD/product_flow/14_FLUTTER_LAYER_CONTRACTS.md`
- `docs/DD/product_flow/15_TEST_ACCEPTANCE_AND_TRACEABILITY.md`
- `docs/DD/product_flow/16_IMPLEMENTATION_ORDER.md`
- `docs/BD/project_flow/BD_Product_Flow_Membership_Sale.md`
- `docs/BD/project_flow/checklist_create_DD_product_flow_membership_sale.md`
- `docs/BD/authentication/BD_Authentication_Registration_Login_NanoBio.md`

## Commands

- `rg --files docs/DD`: PASS - inventory DD hien co.
- `Get-Content -Raw docs/DD/product_flow/*.md`: PASS - doc 17 file DD theo tung nhom.
- `rg -n "Status:|Draft|Ready for implementation|Implemented|TC-PF" docs/DD/product_flow`: PASS - doi chieu status va test matrix.
- `git status --short`: PASS - phat hien `docs/DD/authentication/*` dang bi xoa trong working tree; khong khoi phuc vi khong phai thay doi cua phien nay.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`: PASS - refresh history/task-skills tu 28 worklog.
- `git diff --check -- <changed docs/history/task-skill files>`: PASS - khong con trailing whitespace trong pham vi da sua.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: FAIL - stale path `docs/DD/authentication/00_READ_FIRST.md` vi Auth DD dang bi xoa trong working tree hien tai.

## Loi/Rui ro

- Da fix: checklist global khong con chi noi DD da tao; da co muc rieng cho chuc nang chua hoan thanh theo DD.
- Chua fix: khong audit source runtime, nen ket luan duoc ghi la "chua duoc xac nhan hoan thanh theo DD", khong phai ket luan code chua co. Integrity validation dang fail do Auth DD dependency bi xoa san trong working tree.
- Can kiem tra tiep: neu can danh gia implementation thuc te, can workflow coding/test/find-issues va doc source/test lien quan.

## Ty le hoan thanh

- Hoan thanh: Doc toan bo DD hien co va cap nhat checklist theo yeu cau.
- Dang do: Chua chay Flutter/test runtime vi day la docs-only task.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - ghi chu ngan, tach ro DD da tao voi chuc nang chua Ready/Implemented.
- Muc do hoan thanh task: hoan thanh voi pham vi DD hien co trong working tree.
- Bang chung kiem chung: inventory DD, doc 17 file DD, `rg` status/test matrix, diff checklist.
- Diem ton token/chua toi uu: doc toan bo DD la yeu cau goc; co the toi uu hon bang script tong hop status neu user chi can summary.
- Cach toi uu cho phien sau: neu muc tieu la code readiness, chuyen sang workflow test/find-issues va chi doc source theo phase trong `16_IMPLEMENTATION_ORDER.md`.
- Task-skill can doc lan sau: `.codex/task-skills/docs-dd.md`
