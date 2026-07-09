Commit de xuat: fix(auth): giu validator hop le tra ve null

# Fixbug - Auth validation null

## Van de

- Khi nguoi dung dang nhap hoac dang ky, cac textbox auth co the hien trang thai loi mau do ngay ca khi du lieu da hop le.
- Form khong cho submit vi Flutter xem validator tra ve chuoi rong la mot loi validation.

## Nguyen nhan

- Cac validator tren man login/register boc ket qua `AuthValidators.*` bang `vietnameseUiText(...)`.
- Khi `AuthValidators.*` tra ve `null` de bao hop le, `vietnameseUiText(null)` tra ve `''`.
- `TextFormField.validator` chi xem `null` la hop le; moi chuoi khac `null`, ke ca chuoi rong, deu la loi.

## Cach fix

- Them helper private `_authValidationText` trong `auth_pages.dart`.
- Helper giu nguyen `null` cho trang thai hop le va chi chuan hoa text khi co thong bao loi.
- Thay cac validator email/password/full name cua auth form sang helper moi.
- Giu nguyen validator confirm password va referral code vi cac validator nay da tra `null` truc tiep.
- Chuyen cac `withOpacity(...)` con lai trong file auth sang `withValues(alpha: ...)` de targeted analyze khong bi chan boi deprecated info.

## Regression test

- Them test login form voi email va password hop le, ky vong `FormState.validate()` tra ve `true`.
- Them test register form voi account details hop le, ky vong `FormState.validate()` tra ve `true`.
- Smoke test tiep tuc dam bao login/register page render dung so luong field chinh.

## Validation

- `dart format lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart test/app_versions/v2/features/auth/auth_pages_smoke_test.dart`: PASS.
- `flutter test test/app_versions/v2/features/auth/auth_pages_smoke_test.dart`: PASS, co canh bao san co ve asset directories khai bao trong `pubspec.yaml` nhung khong chan test.
- `flutter analyze lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart test/app_versions/v2/features/auth/auth_pages_smoke_test.dart`: PASS.

