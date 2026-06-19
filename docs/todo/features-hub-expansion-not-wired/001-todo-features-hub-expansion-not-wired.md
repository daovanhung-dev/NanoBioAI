Commit de xuat: docs(todo): lap todo fix features hub expansion routing

# Todo - Noi route cho Features Hub expansion

## Issue goc
- Issue: [Features Hub expansion chua hien thi va chua co route](../../issues/features-hub-expansion-not-wired/001-issue-features-hub-expansion-not-wired.md)
- Severity: high
- Trang thai: todo

## Muc tieu fix
- Dong bo `FeaturesHubPage`, `RoutePaths`, va `app_router.dart` voi cac page da tao.
- User co the mo cac module moi tu Features Hub.

## Khong lam trong todo nay
- Khong them persistence cho cac page moi; issue do co todo rieng.
- Khong sua copy/UI ngoai cac card/route can noi.
- Khong tao route cho page chua ton tai.

## Cac viec can lam
1. [ ] Doc docs feature expansion va cac page moi trong `lib/features/*/presentation/pages`.
2. [ ] Doi chieu danh sach card hien co trong `FeaturesHubPage` voi route/page that.
3. [ ] Them route constants can thiet vao `RoutePaths`.
4. [ ] Import va khai bao route trong `app_router.dart`.
5. [ ] Them card trong `FeaturesHubPage` cho cac module moi va dung copy tieng Viet co dau.
6. [ ] Cap nhat widget tests cho so card va dieu huong route moi.
7. [ ] Cap nhat docs fixbug/worklog sau khi fix.

## File du kien anh huong
- `lib/features/features_hub/presentation/pages/features_hub_page.dart` - them card/action.
- `lib/core/constants/routes/route_names.dart` - them route paths.
- `lib/core/router/app_router.dart` - them GoRoute va imports.
- `test/features/features_hub/features_hub_page_test.dart` - cap nhat coverage.

## Command can kiem chung
- `flutter test test/features/features_hub/features_hub_page_test.dart` - kiem tra Features Hub.
- `flutter analyze` - kiem tra route/import.

## Rui ro can de y
- Neu route moi can auth guard, can dong bo voi policy auth.
- Cac page session-only co the gay ky vong sai neu copy nhu da luu that.
