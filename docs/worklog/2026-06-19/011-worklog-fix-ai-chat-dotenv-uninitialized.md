Commit de xuat: docs(worklog): ghi nhan fix ai chat dotenv uninitialized

# Worklog - Fix AI Chat dotenv uninitialized

## Thoi gian
- Ngay: 2026-06-19
- Bat dau: 23:35
- Ket thuc: 23:43
- Timezone: Asia/Saigon (+07:00)

## Pham vi
- Loai task: fix-issues
- Module chinh: AI Chat service
- Yeu cau goc: implement plan fix `AIChatService(apiKeyOverride: '')` crash khi dotenv chua khoi tao.

## Da lam
- Doc todo, issue, AI service playbook, implementation va test lien quan.
- Reproduce test fail voi `NotInitializedError`.
- Sua `AIChatService` de override rong khong fallback sang dotenv.
- Them helper doc dotenv an toan cho env chat key/model/fallback.
- Them regression test cho case khong truyen `modelNames`.
- Cap nhat todo va tao fixbug doc.

## File code/docs da sua
- `lib/services/ai/ai_chat_service.dart` - sua resolve API key/env an toan khi dotenv chua init.
- `test/services/ai/ai_service_test.dart` - them regression test.
- `docs/todo/ai-chat-dotenv-uninitialized/001-todo-ai-chat-dotenv-uninitialized.md` - cap nhat trang thai/checklist.
- `docs/fixbug/ai-chat-dotenv-uninitialized/001-fixbug-ai-chat-dotenv-uninitialized.md` - tao tai lieu fixbug.
- `docs/worklog/2026-06-19/011-worklog-fix-ai-chat-dotenv-uninitialized.md` - tao worklog.

## Tai lieu lien quan
- [Fixbug AI Chat dotenv uninitialized](../../fixbug/ai-chat-dotenv-uninitialized/001-fixbug-ai-chat-dotenv-uninitialized.md)
- [Todo AI Chat dotenv uninitialized](../../todo/ai-chat-dotenv-uninitialized/001-todo-ai-chat-dotenv-uninitialized.md)

## Commands
- `flutter test test/services/ai/ai_service_test.dart --plain-name "missing API key does not crash and returns local fallback"`: PASS
- `flutter test test/services/ai/ai_service_test.dart`: PASS
- `dart format lib/services/ai/ai_chat_service.dart test/services/ai/ai_service_test.dart`: PASS
- `flutter test`: SKIPPED - optional trong plan; repo da co cac release-level issue rieng ve full suite.

## Loi/Rui ro
- Da fix: `AIChatService(apiKeyOverride: '')` khong con crash khi dotenv chua khoi tao.
- Chua fix: Cac issue AI/log/release khac trong `docs/issues` van ngoai scope.
- Can kiem tra tiep: Khi fix release suite tong, chay lai `flutter test` toan repo.
