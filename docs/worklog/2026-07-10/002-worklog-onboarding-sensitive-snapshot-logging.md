Commit de xuat: docs(worklog): ghi nhan phien fix onboarding sensitive logging

# Worklog - Fix onboarding sensitive snapshot logging

## Thoi gian

- Ngay: 2026-07-10
- Bat dau: 14:00
- Ket thuc: 14:20
- Timezone: Asia/Saigon

## Pham vi

- Loai task: fix-issues
- Module chinh: v1 onboarding, AppLogger
- Yeu cau goc: Tim va fix no ky thuat/bug an trong toan du an; chon todo da co ve onboarding sensitive logging.

## Da lam

- Doc checklist no ky thuat, issue va todo `onboarding-sensitive-snapshot-logging`.
- Xac minh source hien tai khong con block raw SQLite snapshot sau onboarding save.
- Sua `AppLogger` de chi bat logging trong debug/test build bang `kDebugMode`.
- Them regression test datasource that, capture `debugPrint` khi save onboarding co PII/health note va assert khong log raw PII/snapshot.
- Cap nhat checklist, todo va them fixbug doc.

## File code/docs da sua

- `lib/core/utils/logger/app_logger.dart` - sua - gate logging bang `kDebugMode`.
- `test/app_versions/v1/features/onboarding/onboarding_local_datasource_test.dart` - sua - them regression test khong log raw PII/snapshot.
- `docs/checklist/checklist_technical_debt.md` - sua - danh dau debt da fixed.
- `docs/todo/onboarding-sensitive-snapshot-logging/001-todo-onboarding-sensitive-snapshot-logging.md` - sua - tick checklist va link ket qua.
- `docs/fixbug/onboarding-sensitive-snapshot-logging/001-fixbug-onboarding-sensitive-snapshot-logging.md` - tao - tom tat fix.
- `docs/worklog/2026-07-10/002-worklog-onboarding-sensitive-snapshot-logging.md` - tao - ghi nhan phien.

## Tai lieu lien quan

- `.codex/workflows/find-issues.md`
- `.codex/workflows/fix-issues.md`
- `.codex/task-skills/find-issues.md`
- `.codex/domains/onboarding.md`
- `docs/issues/onboarding-sensitive-snapshot-logging/001-issue-onboarding-sensitive-snapshot-logging.md`
- `docs/todo/onboarding-sensitive-snapshot-logging/001-todo-onboarding-sensitive-snapshot-logging.md`

## Commands

- `flutter test test/app_versions/v1/features/onboarding/onboarding_local_datasource_test.dart test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart`: PASS.
- `dart analyze lib/core/utils/logger/app_logger.dart lib/app_versions/v1/features/onboarding/data/datasource/onboarding_local_datasource.dart lib/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart test/app_versions/v1/features/onboarding/onboarding_local_datasource_test.dart test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart`: PASS.
- `rg "ONBOARDING SAVED TO SQLITE|User ID|debugPrint\\(|jsonEncode|jsonEncode\\(|snapshot" ...`: PASS - khong thay raw snapshot log trong onboarding source; chi con JSON encode de luu DB.

## Loi/Rui ro

- Da fix: Onboarding datasource/controller co regression tests chong raw PII/snapshot log; release build khong phat debug logs tu `AppLogger`.
- Chua fix: Mot so module khac van co the truyen raw error vao `AppLogger.error` trong debug/test build.
- Can kiem tra tiep: AI raw payload logging va P0 `.env` tracking/asset packaging trong checklist no ky thuat.

## Ty le hoan thanh

- Hoan thanh: Todo onboarding sensitive logging.
- Dang do: Muc tieu lon toan du an van tiep tuc; con nhieu debt trong checklist.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - fix nho, dung issue/todo, co regression test va evidence.
- Muc do hoan thanh task: hoan thanh mot debt P1 trong objective lon.
- Bang chung kiem chung: targeted tests/analyze PASS va source grep khong con raw snapshot log.
- Diem ton token/chua toi uu: Ket qua `rg` dau tien qua rong; lan sau nen grep source-only va exclude docs/test ngay tu dau.
- Cach toi uu cho phien sau: Chon debt tiep theo tu checklist theo thu tu P0/P1 va chay targeted evidence truoc khi patch.
- Task-skill can doc lan sau: `.codex/task-skills/fix-issues.md`
