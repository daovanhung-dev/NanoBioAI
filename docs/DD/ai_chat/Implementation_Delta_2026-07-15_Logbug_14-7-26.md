# Implementation Delta 2026-07-15 — Logbug 14-7-26

| Thuộc tính | Giá trị |
|---|---|
| Module | M07 / `AI_CHAT` |
| Nguồn | Kế hoạch logbug 14-7-26 do người dùng cung cấp ngày 2026-07-15 |
| Ảnh hưởng | Runtime config, AI failure, quota commit |

## Quyết định bổ sung

| ID | Quyết định |
|---|---|
| AI_CHAT-DELTA-BR01 | IDE, run và build đều dùng `.dart_tool/nanobio_defines.json` qua `--dart-define-from-file`; không bundle `assets/.env` và không log secret. |
| AI_CHAT-DELTA-BR02 | Technical/local fallback không được trả như câu trả lời AI thành công. Thiếu config, AI unavailable/overloaded và response invalid phải trả typed failure, không thêm assistant message. |
| AI_CHAT-DELTA-BR03 | Thứ tự bắt buộc: quota check → AI response hợp lệ → quota commit → publish assistant. Không commit quota khi config/AI/validation thất bại. |
| AI_CHAT-DELTA-BR04 | Commit quota retry tối đa ba lần với cùng request id. Nếu vẫn lỗi, fail closed và không trả câu trả lời AI. |

## Evidence

- Runtime: `ai_chat_service.dart`, `ai_exceptions.dart`, repository và `usage_quota_gateway.dart`.
- Tooling: `.vscode/launch.json`, `prepare_dart_defines.ps1`, `run_v2.ps1`, `build_authenticated.ps1`.
- Test: typed AI failures, no-assistant on failure, ba commit attempts/cùng request id và launcher contracts.
