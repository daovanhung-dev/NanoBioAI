Commit de xuat: fix(ai): nap Gemini runtime key cho main_v2

# Fix Gemini API key runtime cho main_v2

## Trieu chung

- `.env` co `GEMINI_API_KEY` hop le va `tools/run_v2.ps1 -ValidateOnly` pass.
- Khi chay truc tiep `lib/main_v2.dart`, onboarding van fail tai buoc tao lich AI.
- Log Riverpod bao provider nem `Exception: Khong tim thay GEMINI_API_KEY` tu `AIService` constructor.

## Nguyen nhan xac nhan

- Flutter app tren device khong doc truc tiep host `.env` neu launch path khong truyen Dart defines.
- VS Code launch config truoc do co `lib/main.dart` va admin, nhung chua co config rieng cho `lib/main_v2.dart`.
- `AIService` throw ngay trong constructor khi thieu key, lam provider fail truoc khi meal/task generation co co hoi dung local fallback.

## Cach sua

- Them VS Code launch config cho `lib/main_v2.dart`, chay `NanoBio: prepare runtime defines` va truyen `.dart_tool/nanobio_defines.json`.
- Them bootstrap log an toan trong `main.dart` va `main_v2.dart`: chi log `Gemini config present: true/false`.
- Doi `AIService` de thieu `GEMINI_API_KEY` khong crash constructor; runtime generation se fallback local va `checkConnection()` tra failure message an toan.
- Them regression test cho missing-key fallback va contract test cho launch config `main_v2`.

## Gioi han

- Khong bundle `.env` vao assets va khong ghi key vao docs/log.
- Neu nguoi dung chay bang "Run current file" hoac lenh Flutter khong co Dart defines, app se khong co key nhung khong con crash provider.
- Live Gemini/on-device smoke van can chay tren device bang launch config hoac `tools/run_v2.ps1 -EntryPoint lib/main_v2.dart`.
