Commit de xuat: fix(ai): chan retry StateError khi AI chat thieu runtime key

# Fix AI Chat retry StateError khi thieu runtime client

> Cap nhat 2026-07-13: cach xu ly fallback local khi thieu runtime client trong
> tai lieu nay da duoc thay the boi typed failure va banner tai
> `005-fixbug-vscode-ai-chat-runtime-config.md`. Tai lieu nay duoc giu lai nhu
> lich su cua buoc chan retry sai.

## Trieu chung

- AI Chat bat dau xu ly tin nhan nhung ca hai model `gemini-3.1-flash-lite` va `gemini-2.5-flash-lite` deu fail.
- Log hien `RETRY_ATTEMPT_FAILED` voi `errorType: StateError`, sau do `RETRY_EXHAUSTED` va fallback local.
- Nguoi dung chi thay chat fallback, con log runtime bi nhieu dong loi gay nhieu.

## Nguyen nhan xac nhan

- `AIChatService` constructor co the khoi tao khi runtime khong co `GEMINI_API_KEY`; luc do `_geminiClient` la null.
- Truoc fix, `sendMessage()` van di vao `_runWithRetry()`, goi tung model va `_sendText()` nem `StateError('Missing Gemini REST client ...')`.
- Day la loi cau hinh runtime thieu key, khong phai loi model can retry.

## Cach sua

- Them guard som cho `sendMessage()` va `sendMessageStream()`: neu khong co text generator va khong co Gemini REST client, tra fallback local ngay.
- Log mot warning an toan `MISSING_API_KEY` voi `reason: missing_api_key`.
- Khong ghi API key, prompt, response hoac noi dung chat vao log.
- Them regression test de dam bao missing key khong con log `RETRY_ATTEMPT_START`, `RETRY_ATTEMPT_FAILED`, `RETRY_EXHAUSTED` hoac `StateError`.

## Gioi han

- Fix nay khong bien runtime thieu key thanh live Gemini response; no chi chan retry sai va log sai loai loi.
- De AI Chat goi Gemini that, can chay app bang launch config/runtime script co Dart defines hop le.
