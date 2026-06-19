Commit de xuat: docs(todo): lap todo fix ai chat unbounded context tokens

# Todo - Gioi han context token AI Chat

## Issue goc
- Issue: [AI Chat giu lich su khong gioi han](../../issues/ai-chat-unbounded-context-tokens/001-issue-ai-chat-unbounded-context-tokens.md)
- Severity: medium
- Trang thai: todo

## Muc tieu fix
- Giam rui ro token/latency tang vo han khi user chat lau trong cung mot `ChatSession`.

## Khong lam trong todo nay
- Khong thiet ke lai toan bo AI chat UX.
- Khong them telemetry phuc tap neu chua co ha tang.
- Khong luu raw noi dung chat nhay cam vao log.

## Cac viec can lam
1. [ ] Doc `lib/services/ai/ai_chat_service.dart`, tap trung cac ham `sendMessage`, stream, va `resetChat`.
2. [ ] Xac dinh chien luoc nho nhat: gioi han so luot, reset mem session, hoac summarize neu da co helper phu hop.
3. [ ] Them hang so cau hinh ro rang cho nguong history.
4. [ ] Log summary an toan khi reset/gioi han, khong log noi dung tin nhan.
5. [ ] Them test cho hanh vi vuot nguong neu co the mock session.
6. [ ] Cap nhat docs fixbug/worklog sau khi fix.

## File du kien anh huong
- `lib/services/ai/ai_chat_service.dart` - gioi han session/history.
- `test/services/ai/ai_service_test.dart` - test hanh vi gioi han neu phu hop.

## Command can kiem chung
- `flutter test test/services/ai/ai_service_test.dart` - kiem tra AI chat/service.
- `flutter analyze` - xac nhan khong tao lint moi.

## Rui ro can de y
- Reset session co the lam mat ngu canh hoi thoai, can copy Nami giai thich nhe neu user-facing.
- Uoc luong token khong chinh xac neu chi dua vao so luot.
