Commit de xuat: test(config): verify runtime defines launcher contract

# Worklog - Runtime defines launcher contract

## Thoi gian

- Ngay: 2026-07-13
- Timezone: Asia/Saigon

## Pham vi

- Loai task: bugfix
- Module chinh: runtime configuration / AI chat
- Yeu cau goc: Dam bao GEMINI_API_KEY tu `.env` duoc truyen vao Flutter runtime.

## Da lam

- Bo sung contract test cho `tools/prepare_dart_defines.ps1`.
- Xac nhan VS Code launch va `tools/run_v2.ps1` su dung Dart defines.
- Chay script local de tao defines tam ma khong in secret.

## Commands

- `powershell -ExecutionPolicy Bypass -File tools/prepare_dart_defines.ps1`: PASS.
- `flutter test test/core/config/app_env_test.dart test/tools/run_v2_contract_test.dart test/tools/prepare_dart_defines_contract_test.dart`: PASS.
- `flutter analyze ...`: PASS.
- `powershell -ExecutionPolicy Bypass -File tools/run_v2.ps1 -ValidateOnly`: PASS.
- `git diff --check`: PASS; chi co canh bao line-ending cua working tree.

## Loi/Rui ro

- Da fix: launcher co contract test bao ve viec forward `GEMINI_API_KEY`.
- Chua kiem tra: live Gemini request tren device.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - thay doi nho, co kiem chung tap trung.
- Muc do hoan thanh task: hoan tat pham vi runtime launcher va regression contract.
- Bang chung kiem chung: targeted tests, analyzer, validation script deu PASS.
- Diem ton token/chua toi uu: khong chay full native build vi thay doi khong can native artifact.
- Cach toi uu cho phien sau: giu contract test gan voi script launcher.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`
