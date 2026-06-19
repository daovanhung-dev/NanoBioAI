Commit de xuat: docs(todo): lap todo fix new care pages session only state

# Todo - Xu ly state chi ton tai trong phien cua cac page cham soc moi

## Issue goc
- Issue: [Cac page cham soc moi khong luu du lieu that](../../issues/new-care-pages-session-only-state/001-issue-new-care-pages-session-only-state.md)
- Severity: medium
- Trang thai: todo

## Muc tieu fix
- Tranh viec UI lam user hieu da ghi nhan du lieu that trong khi state chi nam trong widget.
- Neu can, noi page vao data layer hien co theo kien truc Presentation -> Provider/Controller -> Repository -> Datasource -> DAO/API.

## Khong lam trong todo nay
- Khong them schema SQLite moi neu chua co quyet dinh san pham ro.
- Khong cho UI goi DB/DAO truc tiep.
- Khong tao mock/sample production data.

## Cac viec can lam
1. [ ] Doc `water_tracking_page.dart`, `personal_goals_page.dart`, va `gentle_care_mode_page.dart`.
2. [ ] Xac dinh page nao can persistence that trong v1 va page nao chi nen la UI/navigation.
3. [ ] Voi Water Tracking, kiem tra co the tai su dung daily health tracking datasource/log hien co khong.
4. [ ] Voi Personal Goals/Gentle Care, chon provider/local preference hoac doi copy de khong ham y da luu.
5. [ ] Neu them persistence, doc playbook SQLite/health tracking va tao migration/test phu hop.
6. [ ] Cap nhat docs fixbug/worklog sau khi fix.

## File du kien anh huong
- `lib/features/water_tracking/presentation/pages/water_tracking_page.dart` - xu ly ghi nhan that hoac copy.
- `lib/features/personal_goals/presentation/pages/personal_goals_page.dart` - xu ly selected state.
- `lib/features/gentle_care_mode/presentation/pages/gentle_care_mode_page.dart` - xu ly selected state.
- `lib/features/daily_health_tracking/` - doc/sua neu noi water vao tracking that.

## Command can kiem chung
- `flutter test` - kiem tra regression.
- `flutter analyze` - kiem tra architecture/lint.
- `rg "core/storage/localdb|data/datasources" lib/features/*/presentation` - kiem tra presentation khong import data/DAO truc tiep.

## Rui ro can de y
- Doi persistence co the cham schema, can migration/version/onCreate/test neu them bang/cot.
- Neu chi doi copy, can ro rang nhung van diu dang theo Nami.
