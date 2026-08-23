Commit de xuat: docs(worklog): ghi nhan fix Voice client-only tren thiet bi

# Worklog — AI Voice client-only device runtime

## Thoi gian

- Ngay: 2026-08-23
- Bat dau: trong phien Codex hien tai
- Ket thuc: sau validation va Android device smoke hop nhat
- Timezone: Asia/Ho_Chi_Minh

## Pham vi

- Loai task: bugfix
- Module chinh: M07 `AI_CHAT` / Sequential Voice Plus
- Yeu cau goc: sua den khi Voice co the noi qua lai tren Android that, khong co
  backend Voice va goi Gemini client-only bang key tu `AppEnv`.

## Da lam

- Ghi nhan root cause `SpeechToText.listen()` tra `null` bi xu ly sai nhu boolean
  va kien truc Edge Function khong kha dung trong moi truong hien co.
- Chuyen contract DD/feature/checklist sang STT -> Flutter Gemini REST -> TTS.
- Ghi ro key co the bi lay khoi APK va paid gate chi o Flutter, co the bi bypass.
- Xoa `supabase/functions/voice-chat-turn` va chi bo block cua function nay trong
  `supabase/config.toml`; giu nguyen `delete-account`.
- Hoan tat runtime Flutter, regression tests, Android build/install va device
  smoke hop nhat.

## File code/docs da sua

- `supabase/functions/voice-chat-turn/` - xoa - khong con backend Voice.
- `supabase/config.toml` - sua - bo rieng block `voice-chat-turn`.
- `docs/DD/ai_chat/` - sua - cap nhat `AI_CHAT-F03/FN03/V03/API03` client-only.
- `docs/features/ai-voice/001-feature-plus-half-duplex-voice.md` - sua - contract,
  config, risk va acceptance hien hanh.
- `docs/checklist/checklist_complete_DD.md` va
  `docs/checklist/checklist_task_coding.md` - sua - bo deploy/Deno backlog Voice.
- `docs/fixbug/ai-voice-sequential/001-fixbug-ai-voice-sequential-device-runtime.md`
  - tao - root cause, fix va device acceptance.
- `lib/app_versions/v1/features/ai_voice/` - sua - STT/TTS lifecycle, direct
  Gemini datasource, RAM repository, controller va Plus access gate.
- `lib/app_versions/v1/services/ai/gemini_rest_client.dart` - sua - optional
  Gemini 3 thinking config va loc thought part khoi text dua vao TTS.
- `test/app_versions/v1/features/ai_voice/` - sua/tao - controller, repository,
  route/widget, direct datasource va concrete MethodChannel regressions.

## Tai lieu lien quan

- `docs/DD/ai_chat/Implementation_Delta_2026-08-23_Sequential_Voice_Plus.md`
- `docs/features/ai-voice/001-feature-plus-half-duplex-voice.md`
- `.codex/workflows/bugfix.md`

## Commands

- Targeted reference scan: PASS - DD/feature/checklist contract hien hanh da
  chuyen sang client-only; reference Edge cu chi duoc giu khi danh dau historical
  hoac xac nhan da xoa.
- `git diff --check`: PASS.
- Targeted trailing-whitespace scan: PASS.
- `.codex/tools/update_worklog_learning.ps1`: BLOCKED - moi truong khong co
  `powershell` hoac `pwsh`; khong sua generated history bang tay.
- Dart format check: PASS - 29 file, 0 file thay doi.
- Targeted Flutter analyze: PASS - 0 issue.
- Targeted Flutter tests: PASS - 75/75.
- Architecture boundary test: baseline FAIL ngoai scope Voice do ba import V1->V2
  hien huu o nutrition/settings/water; cac file nay khong thay doi trong task.
- Android debug build: PASS - `build/app/outputs/flutter-apk/app-debug.apk`.
- Runtime/APK scan: PASS - khong con `voice-chat-turn` trong source runtime hoac
  Flutter kernel cua APK.
- `adb install -r`: PASS tren Xiaomi `220333QPG`, giu nguyen session Plus.
- Android device smoke: PASS - ba turn tieng Viet lien tuc qua
  `listening -> thinking -> speaking -> listening`; khong cancel tuc thi,
  khong `concurrent startListening`, Stop/restart/background khong mo mic lai.

## Loi/Rui ro

- Da fix trong scope docs/backend cleanup: bo contract/deploy `voice-chat-turn`
  hien hanh va giu `delete-account` khong doi.
- Da fix/verify: runtime Flutter va Android multi-turn device smoke.
- Baseline ngoai scope: `test/architecture_version_boundary_test.dart` van bao
  ba vi pham hien huu trong nutrition/settings/water; khong mo rong bugfix Voice
  de sua cac module nay.
- Rui ro chap nhan: Gemini key co the bi trich xuat khoi APK; client Plus gate co
  the bi bypass. `.env` khong phai secret boundary cho mobile binary.
- Con can kiem tra rieng: iOS build va iPhone mic/STT/TTS/background tren
  macOS/iPhone.

## Ty le hoan thanh

- Hoan thanh: source/docs client-only, targeted validation, Android build/install
  va actual-device acceptance.
- Dang do: chi con iOS build/device acceptance ngoai moi truong Linux/Android.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - phan biet ro client-only product gate voi security
  boundary va khong che giau rui ro key trong APK.
- Muc do hoan thanh task: hoan tat client-only source va Android acceptance; iOS
  duoc giu pending dung theo gate macOS/iPhone.
- Bang chung kiem chung: format 29 file, analyze 0 issue, 75 test, Android debug
  build, APK scan, ADB install va ba turn tieng Viet tren thiet bi that deu PASS;
  file Function Voice da xoa, `delete-account` duoc giu.
- Diem ton token/chua toi uu: DD M07 co nhieu file traceability, can scan theo
  keyword va patch theo section thay vi doc rong toan bo module.
- Cach toi uu cho phien sau: bat dau tu fixbug doc + generated task-skill, chay
  plugin-contract test truoc build/ADB va cap nhat evidence mot lan o root.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`
