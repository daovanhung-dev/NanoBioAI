Commit de xuat: docs(worklog): ghi nhan phien authentication v2

# Worklog - Authentication V2

## Thoi gian

- Ngay: 2026-06-20
- Bat dau: Khoang 09:00
- Ket thuc: Khoang 09:34
- Timezone: Asia/Saigon

## Pham vi

- Loai task: coding
- Module chinh: authentication
- Yeu cau goc: Hoan thanh module authentication theo BD, DD, coding va bao cao.

## Da lam

- Doc BD `docs/BD/authentication/BD_Authentication_Registration_Login_NanoBio.md`.
- Doc DD authentication `00-16` va database scripts lien quan.
- Tao module authentication v2 voi repository, datasource, commands, route state, validators, AuthGate va auth pages.
- Tich hop onboarding cloud-first qua Supabase profile service, sau do mirror SQLite bang auth UUID.
- Doi dashboard/daily tracking local read uu tien current auth UUID de tranh doc nham latest user.
- Cap nhat guard `architecture_preservation_property_test` theo contract moi `DashboardEntity.userId` la Supabase UUID `String`.
- Them deep link config `nanobio://auth/callback` cho env example, Android va iOS.
- Them test unit/widget/targeted cho auth v2 va regression lien quan.

## File code/docs da sua

- `lib/app_versions/v2/features/auth/` - tao module auth v2.
- `lib/app_versions/v2/router/` - them auth routes va AuthGate initial route cho v2.
- `lib/services/supabase/auth/` - tao service dung chung cho profile lifecycle/current user.
- `lib/app_versions/v1/features/onboarding/` - cloud-first save va local mirror.
- `lib/app_versions/v1/features/dashboard/` - doc local data theo auth UUID neu co.
- `lib/app_versions/v1/features/daily_health_tracking/` - doc local profile theo auth UUID neu co.
- `.env.example`, `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist` - cau hinh auth redirect.
- `test/app_versions/v2/features/auth/` - them tests auth v2.
- `test/architecture_preservation_property_test.dart` - cap nhat expected field `String userId`.
- `docs/features/authentication/001-feature-authentication-v2.md` - bao cao feature.
- `docs/test/authentication/001-test-authentication-v2.md` - bao cao test.

## Tai lieu lien quan

- [Feature Authentication V2](../../features/authentication/001-feature-authentication-v2.md)
- [Test Authentication V2](../../test/authentication/001-test-authentication-v2.md)

## Commands

- `dart format --set-exit-if-changed .`: PASS - lan cuoi 365 files, 0 changed.
- `flutter analyze`: FAIL - repo co 289 warning/info lint nen hien co; loc theo file vua sua khong co issue.
- `flutter test test\architecture_preservation_property_test.dart test\app_versions\v2\features\auth test\architecture_version_boundary_test.dart test\widget_test.dart test\features\dashboard test\features\daily_health_tracking`: PASS - 63 tests pass.
- `flutter test test\features\features_hub\features_hub_page_test.dart`: FAIL - khong tim thay text `AI Coach`, doc lap voi auth.
- `powershell -NoProfile -ExecutionPolicy Bypass -File .codex\tool\codex_quick_check.ps1`: PARTIAL - script in `QUICK CHECK PASSED` nhung log co `Some tests failed` vi `features_hub_page_test`.

## Loi/Rui ro

- Da fix: Supabase chua initialize trong test gay assert khi dashboard/onboarding fallback local.
- Chua fix: analyzer nen hien co cua repo van fail do warning/info lint ngoai scope.
- Chua fix: full suite con fail ngoai scope auth o `features_hub_page_test`.
- Can kiem tra tiep: manual Supabase SQL integrity, RLS hai user, redirect allow-list, recovery link va Edge Function `delete-account`.
