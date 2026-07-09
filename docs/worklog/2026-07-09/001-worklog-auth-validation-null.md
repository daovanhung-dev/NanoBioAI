Commit de xuat: docs(worklog): ghi nhan phien auth validation null

# Worklog - Auth validation null

## Thoi gian

- Ngay: 2026-07-09
- Bat dau: 11:54
- Ket thuc: 12:03
- Timezone: Asia/Saigon (+07:00)

## Pham vi

- Loai task: bugfix
- Module chinh: v2 authentication
- Yeu cau goc: Fix loi textbox dang nhap/dang ky hien do va khong cho submit khi nguoi dung nhap vao form.

## Da lam

- Xac nhan root cause: validator hop le bi doi tu `null` thanh chuoi rong khi boc qua `vietnameseUiText`.
- Them helper `_authValidationText` de giu contract `TextFormField.validator`: hop le phai tra `null`.
- Cap nhat validator email/password/full name tren login, register, forgot password, reset password.
- Them regression tests cho login/register form voi du lieu hop le.
- Cap nhat smoke tests auth de kiem tra so field render thay vi phu thuoc `InputDecoration.labelText` hien thanh `Text` widget.
- Chuyen cac `withOpacity` con lai trong file auth sang `withValues(alpha: ...)` de targeted analyze pass.

## File code/docs da sua

- `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart` - sua - giu validator hop le tra ve `null` va xu ly analyzer deprecation trong file auth.
- `test/app_versions/v2/features/auth/auth_pages_smoke_test.dart` - sua - them regression tests cho valid login/register form.
- `docs/fixbug/auth-validation-null/001-fixbug-auth-validation-null.md` - tao - ghi lai nguyen nhan va cach fix.
- `docs/worklog/2026-07-09/001-worklog-auth-validation-null.md` - tao - ghi lai phien bugfix.

## Tai lieu lien quan

- `.codex/workflows/bugfix.md`
- `.codex/task-skills/bugfix.md`
- `.codex/domains/access-membership-referral.md`
- `.codex/DOCS_WORKFLOW.md`

## Commands

- `dart format lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart test/app_versions/v2/features/auth/auth_pages_smoke_test.dart`: PASS.
- `flutter test test/app_versions/v2/features/auth/auth_pages_smoke_test.dart`: PASS - 4 tests pass; Flutter van in canh bao san co ve asset directories thieu trong `pubspec.yaml`.
- `flutter analyze lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart test/app_versions/v2/features/auth/auth_pages_smoke_test.dart`: PASS.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`: PASS - lan dau bi chan permission khi regenerate `.codex/task-skills`, rerun voi approval thi pass.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: PASS.
- `git diff --check`: PASS - co canh bao line-ending LF/CRLF san co, khong co whitespace error.

## Loi/Rui ro

- Da fix: valid auth validators khong con tra chuoi rong nen form co the submit khi email/password/register details hop le.
- Chua fix: canh bao asset directories thieu trong `pubspec.yaml` van xuat hien khi chay Flutter command; khong thuoc bug auth nay.
- Can kiem tra tiep: manual smoke tren thiet bi/emulator neu can xac nhan mau border va hanh vi submit voi Supabase staging.

## Ty le hoan thanh

- Hoan thanh: 100% trong pham vi bug UI validation login/register.
- Dang do: khong co trong pham vi bug nay.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - patch nho, dung root cause va co regression tests.
- Muc do hoan thanh task: da fix behavior chinh va chay targeted format/test/analyze.
- Bang chung kiem chung: regression tests login/register valid form pass; targeted analyze pass.
- Diem ton token/chua toi uu: co mot lan test patch sai do `TextFormField` khong expose `decoration`; lan sau nen uu tien test theo public widget count hoac FormState.
- Cach toi uu cho phien sau: voi bug UI validation, tim contract `String? validator` truoc khi thay doi copy/helper dung chung.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`
