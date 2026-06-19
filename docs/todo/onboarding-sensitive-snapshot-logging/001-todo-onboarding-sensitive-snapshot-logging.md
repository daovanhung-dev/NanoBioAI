Commit de xuat: docs(todo): lap todo fix onboarding sensitive snapshot logging

# Todo - Go log snapshot nhay cam sau onboarding

## Issue goc
- Issue: [Onboarding log toan bo snapshot ho so suc khoe](../../issues/onboarding-sensitive-snapshot-logging/001-issue-onboarding-sensitive-snapshot-logging.md)
- Severity: high
- Trang thai: todo

## Muc tieu fix
- Khong log PII/du lieu suc khoe/raw snapshot sau khi luu onboarding.
- Neu can debug, chi log summary count an toan va gate ro rang.

## Khong lam trong todo nay
- Khong doi schema onboarding.
- Khong doi logic luu profile/goals/habits neu khong can.
- Khong log userId/email/phone/raw answer thay cho snapshot.

## Cac viec can lam
1. [ ] Doc `lib/features/onboarding/data/datasource/onboarding_local_datasource.dart` va logger lien quan.
2. [ ] Xac dinh block query/log snapshot sau khi save.
3. [ ] Xoa block snapshot hoac thay bang summary count khong nhay cam.
4. [ ] Kiem tra `AppLogger` co can gate debug/release khong.
5. [ ] Them/cap nhat test neu hien co test log/onboarding datasource.
6. [ ] Cap nhat docs fixbug/worklog sau khi fix.

## File du kien anh huong
- `lib/features/onboarding/data/datasource/onboarding_local_datasource.dart` - go raw snapshot logging.
- `lib/core/utils/logger/app_logger.dart` - dieu chinh logging gate neu can.

## Command can kiem chung
- `flutter test test/features/onboarding` - kiem tra onboarding neu co test folder.
- `flutter analyze` - kiem tra lint.
- `rg "ONBOARDING SAVED TO SQLITE|snapshot|debugPrint" lib/features/onboarding lib/core/utils/logger` - xac nhan khong con raw snapshot.

## Rui ro can de y
- Van can giu kha nang debug loi save onboarding bang thong tin khong nhay cam.
- Khong de user-facing thay thuat ngu database/table/query.
