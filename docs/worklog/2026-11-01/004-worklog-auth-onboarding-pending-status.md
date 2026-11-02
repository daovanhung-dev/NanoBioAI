Commit de xuat: fix(auth): route pending onboarding accounts

# Worklog - Fix auth onboarding status pending

## Thoi gian

- Ngay: 2026-11-01
- Bat dau: Khong ghi nhan chinh xac
- Ket thuc: 20:33
- Timezone: Asia/Ho_Chi_Minh

## Pham vi

- Loai task: bugfix
- Module chinh: V2 auth route state
- Yeu cau goc: Sua loi dang nhap thanh cong nhung khong vao duoc man chinh tren dien thoai dang ket noi.

## Da lam

- Xac nhan backend dat `onboarding_status=pending` mac dinh cho tai khoan moi va API profile tra lai gia tri nay.
- Them `pending` vao nhom trang thai onboarding chua hoan tat trong `AuthRouteStateResolver`.
- Hot reload va hot restart app tren Xiaomi `220333QPG`; app chuyen den man `Kich thuoc chu` cua onboarding.
- Khong sua hoac xoa du lieu tai khoan, token, hay local database.

## File code/docs da sua

- `lib/app_versions/v2/features/auth/domain/services/auth_route_state_resolver.dart` - route `pending` den onboarding.
- `docs/fixbug/auth-onboarding-pending-status/001-fixbug-auth-onboarding-pending-status.md` - ghi nhan root cause, fix va bang chung.
- `docs/worklog/2026-11-01/004-worklog-auth-onboarding-pending-status.md` - worklog phien.
- `.codex/history/` va `.codex/task-skills/` - refresh tu worklog.

## Tai lieu lien quan

- `backend/src/nanobio_backend/db/models.py` - gia tri mac dinh `pending`.
- `backend/src/nanobio_backend/modules/profile/view.py` - API profile tra onboarding status.
- `lib/app_versions/v2/features/auth/domain/services/auth_route_state_resolver.dart` - quyet dinh auth route.

## Commands

- `flutter analyze lib/app_versions/v2/features/auth/domain/services/auth_route_state_resolver.dart`: PASS, khong co issue.
- `dart format --output=none --set-exit-if-changed lib/app_versions/v2/features/auth/domain/services/auth_route_state_resolver.dart`: PASS, khong doi format.
- Dart MCP hot reload va hot restart tren thiet bi: PASS.
- DTD runtime error check: PASS, khong co runtime errors.
- `git diff --check`: PASS.
- `.codex/tools/validate_codex_integrity.ps1`: FAIL do thieu `docs/audit/source_truth_manifest.json` va cac stale path co san trong history/task-skill; khong sua ngoai pham vi.
- Regression tests: SKIPPED.

## Loi/Rui ro

- Da fix: `pending` khong con roi vao trang thai auth khong xac dinh.
- Chua fix: khong co.
- Can kiem tra tiep: nguoi dung hoan tat onboarding; app se vao man chinh theo route da cau hinh.

## Ty le hoan thanh

- Hoan thanh: source fix va runtime transition tren thiet bi ket noi.
- Dang do: khong co.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - root cause duoc doi chieu giua backend contract va man hinh tren thiet bi.
- Muc do hoan thanh task: hoan tat fix; onboarding van can hoan tat truoc khi vao man chinh.
- Bang chung kiem chung: targeted analyzer, format check, hot restart, screenshot onboarding va runtime error check.
- Diem ton token/chua toi uu: lan analyze dau qua Dart MCP bi tu choi do root config; Flutter CLI da chay targeted thanh cong.
- Cach toi uu cho phien sau: dung Flutter CLI targeted khi root cua Dart MCP khong duoc nhan.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`
