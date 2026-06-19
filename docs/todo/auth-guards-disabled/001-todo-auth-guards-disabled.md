Commit de xuat: docs(todo): lap todo fix auth guards disabled

# Todo - Bat lai auth guard cho route protected

## Issue goc
- Issue: [Dashboard va AI Chat dang tat auth guard](../../issues/auth-guards-disabled/001-issue-auth-guards-disabled.md)
- Severity: high
- Trang thai: todo

## Muc tieu fix
- Lam ro va dong bo route nao can auth.
- Neu Dashboard/AI Chat la route protected, bat lai `RouteGuards.authGuard` va them test route guard.

## Khong lam trong todo nay
- Khong doi toan bo auth/onboarding architecture.
- Khong thay doi Supabase config hoac secret.
- Khong khoa cac man offline neu product yeu cau dung khong can dang nhap.

## Cac viec can lam
1. [ ] Doc `lib/core/router/app_router.dart`, `lib/core/router/route_guards.dart`, va splash flow.
2. [ ] Xac minh product rule: Dashboard/AI Chat co bat buoc dang nhap hay khong.
3. [ ] Neu protected, bat lai guard cho `/dashboard` va `/ai-chat`.
4. [ ] Them/cap nhat test cho user null va user da dang nhap neu test ha tang cho phep.
5. [ ] Kiem tra route Nutrition/Profile van khong bi regression.
6. [ ] Cap nhat docs fixbug/worklog sau khi fix.

## File du kien anh huong
- `lib/core/router/app_router.dart` - bat lai redirect guard.
- `lib/core/router/route_guards.dart` - chi sua neu guard hien tai chua du.
- `lib/features/splash/presentation/pages/splash_page.dart` - xem xet neu splash bypass auth.

## Command can kiem chung
- `flutter test` - kiem tra route/widget regression.
- `flutter analyze` - xac nhan router changes sach lint.

## Rui ro can de y
- App co the dang ho tro offline-first, can tranh khoa nham flow onboarding/local data.
- Redirect loop giua splash/login/dashboard can duoc kiem tra.
