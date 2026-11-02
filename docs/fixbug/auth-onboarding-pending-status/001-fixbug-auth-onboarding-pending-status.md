Commit de xuat: fix(auth): route pending onboarding accounts

# Fixbug - Chuyen tai khoan pending vao onboarding

## Hien tuong

- Tren Xiaomi `220333QPG`, dang nhap thanh cong nhung app hien `Nabi can kiem tra them` thay vi chuyen tiep.
- Backend tao tai khoan moi voi `onboarding_status=pending` va API profile tra lai gia tri nay.
- Auth resolver cua Flutter chi nhan `completed`, `not_started` va `in_progress`, nen `pending` roi vao nhanh failure.

## Root cause

Contract trang thai onboarding khong dong nhat: backend dung `pending` lam gia tri mac dinh, con Flutter coi moi gia tri ngoai ba gia tri da biet la trang thai khong xac dinh.

## Cach sua

- Xem `pending` la onboarding chua hoan tat va chuyen den luong onboarding, cung nhom voi `not_started` va `in_progress`.
- Giu nguyen API, backend data va cac trang thai la.

## Bang chung va xac minh

- Trien khai source fix bang hot reload va hot restart qua DTD tren Xiaomi `220333QPG`.
- Sau hot restart, app hien man `Kich thuoc chu` trong onboarding thay vi man loi.
- `flutter analyze lib/app_versions/v2/features/auth/domain/services/auth_route_state_resolver.dart`: PASS, khong co loi.
- `dart format --output=none --set-exit-if-changed` tren resolver: PASS.
- DTD runtime errors: khong co.
- Regression test: chua them/chay trong phien nay.

## Gioi han

- Tai khoan can hoan tat onboarding truoc khi den man chinh; fix nay khong bo qua onboarding.
- Khong doc token/credential va khong sua/xoa du lieu tai khoan.
