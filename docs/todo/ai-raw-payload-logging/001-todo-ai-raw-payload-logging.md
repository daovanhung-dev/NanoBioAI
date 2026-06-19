Commit de xuat: docs(todo): lap todo fix ai raw payload logging

# Todo - Go raw payload trong log AI

## Issue goc
- Issue: [AI service log raw prompt va raw response](../../issues/ai-raw-payload-logging/001-issue-ai-raw-payload-logging.md)
- Severity: high
- Trang thai: todo

## Muc tieu fix
- Log AI chi con summary an toan: traceId, method, model, count, source, error type, prompt length, response length.
- Khong log raw prompt, raw response, `healthData`, userId that, hoac ho so suc khoe.

## Khong lam trong todo nay
- Khong xoa toan bo logging can cho debug.
- Khong thay doi schema prompt/response AI neu khong can.
- Khong them sample data de che test.

## Cac viec can lam
1. [ ] Doc `lib/services/ai/ai_service.dart`, `lib/services/ai/ai_trace_logger.dart`, va test AI lien quan.
2. [ ] Liet ke cac call log raw payload trong meal/exercise/check connection.
3. [ ] Thay raw payload bang summary length/count/source an toan.
4. [ ] Cap nhat test dang ky vong raw response de ky vong log an toan.
5. [ ] Kiem tra khong con log `healthData`, raw prompt, raw response.
6. [ ] Cap nhat docs fixbug/worklog sau khi fix.

## File du kien anh huong
- `lib/services/ai/ai_service.dart` - thay doi noi dung log.
- `lib/services/ai/ai_trace_logger.dart` - dieu chinh helper chunk/raw payload neu can.
- `test/services/ai/ai_service_test.dart` - cap nhat ky vong logging.

## Command can kiem chung
- `flutter test test/services/ai/ai_service_test.dart` - kiem tra AI tests.
- `rg "RAW_RESPONSE|PROMPT_SENT|DECODED_JSON|healthData" lib/services/ai test/services/ai` - xac nhan raw markers da duoc xu ly.

## Rui ro can de y
- Van can du thong tin debug loi AI ma khong lo du lieu nhay cam.
- Test cu co the dang assert behavior khong con an toan.
