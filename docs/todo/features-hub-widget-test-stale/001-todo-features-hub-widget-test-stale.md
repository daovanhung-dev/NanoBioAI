Commit de xuat: docs(todo): lap todo fix features hub stale widget test

# Todo - Cap nhat Features Hub widget test cu

## Issue goc

- Issue: [Features Hub widget test tim AI Coach khong con ton tai](../../issues/features-hub-widget-test-stale/001-issue-features-hub-widget-test-stale.md)
- Severity: medium
- Trang thai: todo

## Muc tieu fix

- Dua widget test ve dung behavior hien tai cua Features Hub: tile AI hien la `Tro chuyen voi Nabi` va dieu huong den AI Chat.

## Khong lam trong todo nay

- Khong doi UI ve copy cu `AI Coach` neu behavior moi la dung.
- Khong gom chung voi viec them route expansion neu user chi yeu cau fix test stale.
- Khong bo test de lam suite xanh gia.

## Cac viec can lam

1. [ ] Doc `test/features/features_hub/features_hub_page_test.dart` va `features_hub_page.dart`.
2. [ ] Xac dinh behavior dung: AI tile dieu huong hay placeholder snackbar.
3. [ ] Neu behavior moi dung, cap nhat finder sang copy tieng Viet hien tai.
4. [ ] Assert dieu huong route AI Chat bang router/test harness phu hop.
5. [ ] Cap nhat docs fixbug/worklog sau khi fix.

## File du kien anh huong

- `test/features/features_hub/features_hub_page_test.dart` - sua assertion stale.
- `lib/features/features_hub/presentation/pages/features_hub_page.dart` - chi sua neu UI moi sai spec.

## Command can kiem chung

- `flutter test test/features/features_hub/features_hub_page_test.dart` - kiem tra widget test.
- `flutter test` - xac nhan test suite tong sau khi cac issue test khac duoc fix.

## Rui ro can de y

- Test router can dung harness on dinh, tranh assert qua mong manh vao implementation.
- Copy user-facing phai giu tieng Viet co dau va giong Nabi.
