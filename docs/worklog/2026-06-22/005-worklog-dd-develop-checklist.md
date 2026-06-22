Commit de xuat: docs(checklist): ghi nhan DD chua coding

# Worklog - DD develop checklist

## Thoi gian

- Ngay: 2026-06-22
- Bat dau: 07:40
- Ket thuc: 07:47
- Timezone: Asia/Saigon (+07:00)

## Pham vi

- Loai task: docs-dd
- Module chinh: `docs/DD/product_flow`, `docs/checklist/checklist_develop_DD.md`, source access/membership/quota/v3/sale.
- Yeu cau goc: Doc toan bo DD, xac dinh chuc nang nao chua duoc coding, note don gian vao `docs/checklist/checklist_develop_DD.md`.

## Da lam

- Doc lai 17 file DD hien co trong `docs/DD/product_flow`.
- Kiem tra `docs/checklist/checklist_develop_DD.md` va xac nhan file dang rong.
- Doi chieu DD voi source bang `rg` va doc cac file source muc tieu trong v1/v2/v3/sale_referral/supabase docs/tests.
- Phan loai cac muc `chua coding`, `coding mot phan`, hoac `co draft SQL nhung chua app-wiring`.
- Cap nhat checklist develop bang bang ngan 16 nhom chuc nang chua coding/chua coding day du.

## File code/docs da sua

- `docs/checklist/checklist_develop_DD.md` - sua - them checklist chuc nang DD chua coding.
- `docs/worklog/2026-06-22/005-worklog-dd-develop-checklist.md` - tao - ghi nhan phien audit/checklist.

## Tai lieu lien quan

- `docs/DD/product_flow/00_READ_FIRST.md`
- `docs/DD/product_flow/01_DOCUMENT_MAP.md`
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
- `lib/main.dart`, `lib/main_v2.dart`
- `lib/app_versions/v1/services/ai/generated_plan_service.dart`
- `lib/app_versions/v1/router/v1_router.dart`
- `lib/app_versions/v2/features/README.md`
- `lib/app_versions/v3/README.md`
- `lib/sale_referral/README.md`

## Commands

- `rg --files docs/DD`: PASS - 17 DD product_flow file.
- `Get-Content -Raw docs/DD/product_flow/*.md`: PASS - doc DD theo working tree hien tai.
- `rg -n "quota|membership|subscription|referral|commission|payment|FamilyPlus|Plus" ...`: PASS - doi chieu source co lien quan.
- `Get-Content -Raw <targeted source files>`: PASS - doc v1 onboarding/generated plan/route, v2 auth/quota/scoring, v3, sale_referral, notification.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`: PASS - refresh history/task-skills tu 29 worklog.
- `rg -n "Chuc nang chua duoc coding theo DD|Guest sinh lich trinh|Free quota|Sale/referral|TC-PF-01" docs/checklist/checklist_develop_DD.md`: PASS - xac nhan checklist da co noi dung.
- `git diff --check -- <changed docs/history/task-skill files>`: PASS - khong co whitespace error trong pham vi da sua.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: FAIL - stale path `docs/DD/authentication/00_READ_FIRST.md` do Auth DD dang bi xoa trong working tree.

## Loi/Rui ro

- Da fix: checklist develop khong con rong; da co note don gian ve cac chuc nang DD chua coding/chua coding day du.
- Chua fix: khong chay full Flutter test/analyze; khong ket luan production runtime. Integrity validation van fail do stale Auth DD path co san trong working tree.
- Can kiem tra tiep: neu can ket luan "da code nhung fail" thi can workflow test/find-issues va chay targeted tests.

## Ty le hoan thanh

- Hoan thanh: Cap nhat checklist develop theo yeu cau.
- Dang do: Chua sua code runtime.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - bang ngan, co phan biet placeholder/SQL draft/implementation.
- Muc do hoan thanh task: hoan thanh trong pham vi DD va source hien co.
- Bang chung kiem chung: doc DD, source search, targeted file reads, checklist diff.
- Diem ton token/chua toi uu: doc toan bo DD sinh output lon va bi truncate; lan sau co the dung script trich heading/status/dependency truoc.
- Cach toi uu cho phien sau: neu tiep tuc coding theo checklist, di theo phase trong `16_IMPLEMENTATION_ORDER.md` va bat dau tu Guest V1/Free quota.
- Task-skill can doc lan sau: `.codex/task-skills/docs-dd.md`
