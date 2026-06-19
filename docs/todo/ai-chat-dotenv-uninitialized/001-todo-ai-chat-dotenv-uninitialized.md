Commit de xuat: docs(todo): lap todo fix ai chat dotenv uninitialized

# Todo - AI Chat crash khi dotenv chua khoi tao

## Issue goc
- Issue: [AI Chat crash khi dotenv chua khoi tao](../../issues/ai-chat-dotenv-uninitialized/001-issue-ai-chat-dotenv-uninitialized.md)
- Severity: high
- Trang thai: done

## Muc tieu fix
- Dam bao `AIChatService(apiKeyOverride: '')` khong doc `dotenv.env` khi dotenv chua duoc khoi tao.
- Khi API key bi thieu, service tra local fallback thay vi crash.

## Khong lam trong todo nay
- Khong doi flow AI chat UI neu khong can.
- Khong goi API Gemini that trong test.
- Khong sua cac issue AI khac ngoai dotenv fallback.

## Cac viec can lam
1. [x] Doc `lib/services/ai/ai_chat_service.dart` va test lien quan trong `test/services/ai/ai_service_test.dart`.
2. [x] Xac minh logic constructor phan biet override duoc truyen voi override khong duoc truyen.
3. [x] Sua nho nhat de chuoi override rong duoc coi la missing key hop le va khong fallback sang `dotenv.env`.
4. [x] Cap nhat hoac them test cho truong hop dotenv chua init.
5. [x] Cap nhat docs fixbug/worklog sau khi fix.

## File du kien anh huong
- `lib/services/ai/ai_chat_service.dart` - sua logic doc API key.
- `test/services/ai/ai_service_test.dart` - xac nhan missing key khong crash.

## Command can kiem chung
- `flutter test test/services/ai/ai_service_test.dart` - kiem tra AI service regression.
- `flutter test` - xac nhan test suite sau khi sua.

## Rui ro can de y
- Can giu hanh vi doc `.env` binh thuong khi khong co override.
- Khong log API key hoac thong tin nhay cam.
