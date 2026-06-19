Commit de xuat: docs(todo): lap todo fix release format dry run new pages

# Todo - Format 6 page moi truoc release

## Issue goc
- Issue: [Dart format dry-run fail o 6 page moi](../../issues/release-format-dry-run-fails-new-pages/001-issue-release-format-dry-run-fails-new-pages.md)
- Severity: medium
- Trang thai: todo

## Muc tieu fix
- Chay format cho 6 file page moi va xac nhan dry-run pass.

## Khong lam trong todo nay
- Khong sua logic UI/persistence cua cac page nay.
- Khong format ca repo neu chi can 6 file, tru khi user yeu cau.
- Khong gom voi analyze/test failures khac.

## Cac viec can lam
1. [ ] Chay `dart format` cho dung 6 file duoc neu trong issue.
2. [ ] Chay lai `dart format --output=none --set-exit-if-changed` tren 6 file hoac toan repo neu can gate.
3. [ ] Kiem tra git diff de dam bao chi la format.
4. [ ] Cap nhat docs fixbug/worklog sau khi fix.

## File du kien anh huong
- `lib/features/body_metrics/presentation/pages/body_metrics_page.dart` - format.
- `lib/features/gentle_care_mode/presentation/pages/gentle_care_mode_page.dart` - format.
- `lib/features/personal_goals/presentation/pages/personal_goals_page.dart` - format.
- `lib/features/quick_care/presentation/pages/quick_care_page.dart` - format.
- `lib/features/water_tracking/presentation/pages/water_tracking_page.dart` - format.
- `lib/features/weekly_summary/presentation/pages/weekly_summary_page.dart` - format.

## Command can kiem chung
- `dart format --output=none --set-exit-if-changed lib/features/body_metrics/presentation/pages/body_metrics_page.dart lib/features/gentle_care_mode/presentation/pages/gentle_care_mode_page.dart lib/features/personal_goals/presentation/pages/personal_goals_page.dart lib/features/quick_care/presentation/pages/quick_care_page.dart lib/features/water_tracking/presentation/pages/water_tracking_page.dart lib/features/weekly_summary/presentation/pages/weekly_summary_page.dart` - xac nhan format pass.

## Rui ro can de y
- Format-only diff nen khong lam thay doi behavior.
- Neu formatter version khac, can ghi ro moi truong trong worklog.
