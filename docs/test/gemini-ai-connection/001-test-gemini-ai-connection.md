Commit de xuat: test(ai): bo sung regression va preflight Gemini

# Test kết nối Gemini và các tác vụ AI

## Phạm vi

- Transport REST và header xác thực.
- Parse response/error.
- AI onboarding connection check.
- AI Chat và conversation history.
- Cấu hình launcher/build.
- Kiểm tra không rò rỉ khóa ngoài `.env`.

## Kết quả trong môi trường hiện tại

| Kiểm tra | Kết quả | Ghi chú |
|---|---|---|
| Static delimiter/import scan cho 10 file Dart tác động | PASS | Không phát hiện delimiter/string/comment chưa đóng. |
| Parse `pubspec.yaml` và `.vscode/launch.json` | PASS | YAML/JSON hợp lệ. |
| Contract REST | PASS | Có `:generateContent`, `x-goog-api-key`, system instruction và JSON MIME config. |
| Audit đường gọi AI | PASS | Onboarding, meal, exercise và chat đều đi qua `AIService`/`AIChatService` và client REST mới. |
| Secret scan | PASS | Khóa thật chỉ còn trong `.env`, không xuất hiện trong source/docs/test mới. |
| DNS/live Gemini request | BLOCKED | Sandbox không phân giải được host Gemini (`gaierror`). Không kết luận key/model live từ môi trường này. |
| `dart format` / `flutter analyze` / `flutter test` | BLOCKED | Không có Dart/Flutter SDK. |
| PowerShell preflight | BLOCKED | Không có PowerShell trong sandbox. |
| Device smoke | BLOCKED | Không có Android device/toolchain trong sandbox. |

## Test cần chạy trên máy dự án

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_v2.ps1 -ValidateOnly
powershell -ExecutionPolicy Bypass -File tools/test_gemini_connection.ps1
flutter test test/services/ai/gemini_rest_client_test.dart
flutter test test/services/ai/ai_service_test.dart
flutter analyze lib/app_versions/v1/services/ai test/services/ai
powershell -ExecutionPolicy Bypass -File tools/run_v2.ps1 -DeviceId 12b304f9
```

