Commit de xuat: docs(worklog): ghi nhan fix Chat AI native debug runtime

# Worklog - Fix Chat AI native debug runtime

## Thoi gian

- Ngay: 2026-07-19
- Timezone: Asia/Saigon

## Pham vi

- Loai task: bugfix/test/docs
- Module chinh: M07 `AI_CHAT`, M05 runtime configuration
- Yeu cau goc: xac dinh va sua Chat AI van hien loi tren Android.

## Da lam

- Lay log process dang loi va xac nhan nguon cau hinh Gemini la `missing`, trong
  khi quota backend cho phep request.
- Them fallback local-only cho Android debug qua BuildConfig + MethodChannel, giu
  Dart define uu tien va khong dua `.env` vao asset/source control.
- Chay `flutter run` thuan de tai lap entrypoint loi cu, sau do smoke Chat bang
  goi y co san tren thiet bi. Gemini response duoc validate va quota commit.

## File code/docs da sua

- `android/app/build.gradle.kts`, `android/app/src/main/kotlin/.../MainActivity.kt`
  - native debug runtime config.
- `lib/core/config/app_env.dart` - resolve native config sau Dart define/dotenv.
- `test/core/config/app_env_test.dart`, `test/tools/run_v2_contract_test.dart` -
  regression native fallback.
- `README.md`, `docs/fixbug/gemini-ai-connection/007-...` - huong dan va evidence.

## Commands

- `flutter test` AI/config target: PASS.
- `flutter analyze` target files: PASS.
- `flutter run -d 12b304f9 -t lib/main.dart`: PASS; boot `nativeBuildConfig`.
- Android Chat smoke: PASS; Gemini valid response va quota commit, khong log key
  hay noi dung response.

## Loi/Rui ro

- Da fix: chay debug tu IDE/gutter khong con lam Chat mat Gemini config.
- Can kiem tra tiep: tao lich UI smoke theo account/quota; Supabase sandbox quota
  acceptance va notification real-device backlog van rieng biet.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - dung log runtime process de tach loi injection khoi
  quota va Gemini, sau do kiem chung full flow tren thiet bi.
- Muc do hoan thanh task: Chat Android debug da co evidence end-to-end.
- Bang chung kiem chung: unit tests, analyzer, Gradle build, boot source va Chat
  response/quota commit tren device.
- Diem ton token/chua toi uu: tuong tac UI qua ADB can nhieu buoc do hub scroll.
- Cach toi uu cho phien sau: them smoke integration co navigation test id neu app
  co UI automation harness.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`
