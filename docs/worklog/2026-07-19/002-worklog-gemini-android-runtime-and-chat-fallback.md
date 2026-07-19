Commit de xuat: docs(worklog): ghi nhan fix Gemini Android runtime va chat fallback

# Worklog - Fix Gemini Android runtime va chat fallback

## Thoi gian

- Ngay: 2026-07-19
- Timezone: Asia/Saigon

## Pham vi

- Loai task: bugfix/test/docs
- Module chinh: M02 `PERSONAL_SCHEDULE_AI`, M07 `AI_CHAT`
- Yeu cau goc: sua Chat AI va tao lich khong ket noi duoc Gemini tren Android.

## Da lam

- Xac nhan log `MISSING_API_KEY` la APK chay thieu Dart define, khong phai quota
  RPC (quota check da allowed).
- Them Android Studio shared profile, huong dan tao defines an toan va bootstrap
  diagnostic chi log nguon cau hinh.
- Dong bo Chat fallback voi model da duoc preflight xac nhan, giu luong tao lich
  hien co va khong lam gia response/commit quota khi Gemini that bai.

## File code/docs da sua

- `lib/core/config/app_env.dart`, `lib/main.dart` - safe config-source diagnostic.
- `lib/app_versions/v1/services/ai/ai_chat_service.dart` - them fallback
  `gemini-3.5-flash`.
- `.run/NanoBio__Authenticated_App.xml`, `.idea/runConfigurations/main_dart.xml`,
  `README.md` - profile/huong dan Android Studio.
- `test/core/config/app_env_test.dart`, `test/services/ai/ai_service_test.dart`,
  `test/tools/run_v2_contract_test.dart` - regression.

## Commands

- `flutter test` targeted AI/config/launcher: PASS (60 tests).
- `flutter analyze` target files: PASS.
- `tools/run_v2.ps1 -ValidateOnly`: PASS.
- `tools/run_v2.ps1 -DeviceId 12b304f9`: PASS; bootstrap dung `dartDefine`.
- `tools/test_gemini_connection.ps1 -TimeoutSec 20`: PASS voi model kha dung.

## Loi/Rui ro

- Da fix: APK tu profile duoc cung cap khong con thieu runtime Gemini key; Chat
  co fallback da duoc kiem chung.
- Can kiem tra tiep: smoke UI Chat va tao lich tren account con quota; Supabase
  sandbox quota/RLS/idempotency va notification real-device acceptance van la
  backlog rieng.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - tach duoc config injection, model availability va
  quota thay vi gom thanh mot loi ket noi.
- Muc do hoan thanh task: code/config va preflight da hoan tat; UI acceptance
  can thao tac nguoi dung tren thiet bi.
- Bang chung kiem chung: targeted tests, analyzer, Android bootstrap va Gemini
  preflight thanh cong; khong co secret trong log/tai lieu.
- Diem ton token/chua toi uu: Android Studio khong co before-run task chia se
  cross-platform cho PowerShell, nen README neu ro buoc tao defines.
- Cach toi uu cho phien sau: them smoke automation khi co test account/quota.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`
