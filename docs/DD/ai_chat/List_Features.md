# List Features — AI_CHAT / AI Chat

## 0. Document Information

| Field | Value |
|---|---|
| Module | AI_CHAT |
| Overall | [Overall.md](Overall.md) |
| Version | v1.7 |
| Last Updated | 2026-09-13 |
| Source | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M07, 16.1 AC-03/AC-04/AC-06, Appendix A UC-07 |

## 1. Feature Inventory

| ID | Feature | Goal | Actor | Trigger | Priority | Source | Functions | Views | Status |
|---|---|---|---|---|---|---|---|---|---|
| AI_CHAT-F01 | Mở AI Chat theo quyền | Chỉ actor có entitlement hợp lệ được vào chat. | Free, Plus, FamilyPlus | Mở AI Chat | P0 | BD M07 luồng, AC-03/AC-06 | AI_CHAT-FN01 | AI_CHAT-V01 | Approved - DD docs complete |
| AI_CHAT-F02 | Gửi câu hỏi AI theo quota | Gửi câu hỏi khi quota/rate policy cho phép. | Free, Plus, FamilyPlus | Submit chat question | P0 | BD M07 rules, AC-04 | AI_CHAT-FN02 | AI_CHAT-V02 | Approved - DD docs complete |
| AI_CHAT-F03 | Hội thoại giọng nói tuần tự | Plus/FamilyPlus nói từng lượt với Nabi qua Gemini client-only, chọn endpointing 0,2/0,5/1/2 giây và hard cap nghe 3 phút, không dùng quota Voice NanoBio; chấp nhận key/APK và client-gate risk. | Plus, FamilyPlus | Chọn tốc độ và nhấn Bắt đầu tại `/ai-voice` | P0 | User-approved client-only Voice, reaction-speed and 3-minute hard-cap plans 2026-08-23 | AI_CHAT-FN03 | AI_CHAT-V03 | Reaction-speed Android PASS; 3-minute source/test/build/install PASS, >60-second continuity pending; iOS pending |

## 2. Dependencies Between Features

| Source Feature | Relationship | Target Feature | Data / State Passed | Condition |
|---|---|---|---|---|
| AI_CHAT-F01 | prerequisite / trigger | Next feature in this module | Module state and actor context | Previous feature succeeds and business rules pass |
| Cross-module | dependency | Related module DD | Entitlement, ownership, audit, or event state | Dependency module is available and accepted decision/evidence gates are satisfied |
| AI_CHAT-F01 | authorization prerequisite | AI_CHAT-F03 | Authenticated user id + effective access | Exact current user has Plus/FamilyPlus; all unresolved access states fail-closed |

---

<a id="ai_chat-f01"></a>
# AI_CHAT-F01 — Mở AI Chat theo quyền

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Chỉ actor có entitlement hợp lệ được vào chat. |
| Actor chính | Free, Plus, FamilyPlus |
| Actor phụ / hệ thống | Membership quota |
| Trigger | Mở AI Chat |
| Phạm vi | Access check and load chat shell. |
| Không thuộc feature | Prompt design. |
| Requirement nguồn | BD M07 luồng, AC-03/AC-06 |
| Rule áp dụng | AI_CHAT-BR01 |
| View liên quan | AI_CHAT-V01 |
| Function liên quan | AI_CHAT-FN01 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 6/M07, 16.1 AC-03/AC-04/AC-06, Appendix A UC-07. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của AI Chat được cập nhật và có thể truy vết tới BD M07 luồng, AC-03/AC-06. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Free, Plus, FamilyPlus mở AI_CHAT-V01 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=ai_request; Name=AI Request; Purpose=Theo dõi request chat; Attributes=request_id, user, status, quota impact; Relationships=Uses quota ledger}, @{Id=chat_message; Name=Chat Message; Purpose=Tin nhắn chat nếu lưu; Attributes=owner, role, content summary, created_at; Relationships=Subject to privacy policy}.
4. Actor thực hiện hành động: Mở AI Chat.
5. AI_CHAT-FN01 kiểm tra AI_CHAT-BR01 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| AI_CHAT-F01-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | AI_CHAT-TC01 |
| AI_CHAT-F01-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | AI_CHAT-TC01 |
| AI_CHAT-F01-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | AI_CHAT-TC01 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| AI_CHAT-BR01 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | AI_CHAT-E-main | Dữ liệu nghiệp vụ chính của AI Chat | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | AI_CHAT-API01 | Contract dự kiến cho AI_CHAT-FN01 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Documented Acceptance Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| AI_CHAT-AC01-01 | Với source BD M07 luồng, AC-03/AC-06, feature tạo đúng outcome: Chỉ actor có entitlement hợp lệ được vào chat.. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-AC01-02 | Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-AC01-03 | Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-AC01-04 | AI_CHAT-V01 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied. | Documented | Required in implementation/test phase; not executed in this DD docs pass |

---

<a id="ai_chat-f02"></a>
# AI_CHAT-F02 — Gửi câu hỏi AI theo quota

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Gửi câu hỏi khi quota/rate policy cho phép. |
| Actor chính | Free, Plus, FamilyPlus |
| Actor phụ / hệ thống | AI service |
| Trigger | Submit chat question |
| Phạm vi | Check quota, call AI, record success. |
| Không thuộc feature | Raw AI logs. |
| Requirement nguồn | BD M07 rules, AC-04 |
| Rule áp dụng | AI_CHAT-BR02 |
| View liên quan | AI_CHAT-V02 |
| Function liên quan | AI_CHAT-FN02 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 6/M07, 16.1 AC-03/AC-04/AC-06, Appendix A UC-07. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của AI Chat được cập nhật và có thể truy vết tới BD M07 rules, AC-04. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Free, Plus, FamilyPlus mở AI_CHAT-V02 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=ai_request; Name=AI Request; Purpose=Theo dõi request chat; Attributes=request_id, user, status, quota impact; Relationships=Uses quota ledger}, @{Id=chat_message; Name=Chat Message; Purpose=Tin nhắn chat nếu lưu; Attributes=owner, role, content summary, created_at; Relationships=Subject to privacy policy}.
4. Actor thực hiện hành động: Submit chat question.
5. AI_CHAT-FN02 kiểm tra AI_CHAT-BR02 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| AI_CHAT-F02-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | AI_CHAT-TC02 |
| AI_CHAT-F02-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | AI_CHAT-TC02 |
| AI_CHAT-F02-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | AI_CHAT-TC02 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| AI_CHAT-BR02 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | AI_CHAT-E-main | Dữ liệu nghiệp vụ chính của AI Chat | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | AI_CHAT-API02 | Contract dự kiến cho AI_CHAT-FN02 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Documented Acceptance Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| AI_CHAT-AC02-01 | Với source BD M07 rules, AC-04, feature tạo đúng outcome: Gửi câu hỏi khi quota/rate policy cho phép.. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-AC02-02 | Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-AC02-03 | Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-AC02-04 | AI_CHAT-V02 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied. | Documented | Required in implementation/test phase; not executed in this DD docs pass |

---

<a id="ai_chat-f03"></a>
# AI_CHAT-F03 — Hội thoại giọng nói tuần tự cho Plus/FamilyPlus

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Cho phép Plus/FamilyPlus giao tiếp bằng giọng nói theo từng lượt rõ ràng: người nói xong thì Nabi xử lý/nói, Nabi nói xong mới nghe lượt tiếp theo. |
| Actor chính | Plus, FamilyPlus |
| Actor bị chặn | Guest và Free |
| Trigger | Người dùng nhấn **Bắt đầu** trên `AI_CHAT-V03`. |
| Phạm vi | STT từng câu, Gemini REST trực tiếp từ Flutter, TTS, history RAM tối đa 6 lượt. |
| Không thuộc feature | Full-duplex, nói chen, reconnect Live, custom PCM, Bluetooth, offline, lưu lịch sử. |
| Requirement nguồn | User-approved Sequential Voice plan 2026-08-23. |
| Rule áp dụng | AI_CHAT-BR03..AI_CHAT-BR11 |
| View liên quan | AI_CHAT-V03 |
| Function/API liên quan | AI_CHAT-FN03, AI_CHAT-API03 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Có Supabase session hợp lệ; effective access thuộc đúng user hiện tại; `hasPaidAccess == true`; người dùng chủ động nhấn Bắt đầu; quyền mic/speech được cấp. |
| Hậu điều kiện thành công | Hiển thị transcript cuối và câu trả lời cuối; sau TTS hoàn tất + 300 ms, controller nghe turn tiếp theo. |
| Hậu điều kiện thất bại | Dừng vòng lặp, tắt STT/TTS, giữ copy lỗi an toàn và yêu cầu người dùng chủ động thử lại. |
| Dữ liệu | History chỉ tồn tại trong RAM; tối đa 12 message (`user`/`model`); xóa khi Start phiên mới, Stop, background, rời trang hoặc dispose. |
| Quota | Không check/commit quota NanoBio; rate limit/quota của Gemini vẫn có thể trả lỗi tạm thời. |

## C. Luồng chính

1. Guest được route guard chuyển tới đăng nhập. Free nhìn thấy CTA nâng cấp nhưng
   trang/controller/micro không được mount. Loading, error, null và user mismatch
   cũng không mount feature.
2. Plus/FamilyPlus mở `AI_CHAT-V03`; chọn **Tốc độ phản ứng** hoặc giữ
   **Bình thường 1 giây** mặc định. Micro vẫn tắt cho đến khi nhấn
   **Bắt đầu**.
3. Controller reset history và đi `idle -> listening`.
4. Final transcript dừng recognizer ngay. Nếu chưa final, gateway chỉ arm
   threshold sau partial non-empty đầu tiên và dừng sau 0,2/0,5/1/2 giây
   im lặng theo mức chọn. Mỗi lượt có hard cap app/plugin 3 phút nhưng final,
   endpointing hoặc recognizer OS có thể dừng sớm hơn. Transcript rỗng không gọi
   Gemini và quay lại nghe.
5. Transcript hợp lệ đưa state sang `thinking`, gọi `AI_CHAT-FN03`/
   `AI_CHAT-API03`; micro giữ tắt.
6. Datasource gọi Gemini REST trực tiếp bằng key/model từ `AppEnv`. Gate
   Plus/FamilyPlus không được kiểm tra lại ở server.
7. Text hợp lệ đưa state sang `speaking`; TTS đọc xong, chờ khoảng 300 ms rồi
   controller mới quay lại `listening`.
8. Người dùng nhấn **Dừng** ở bất kỳ state nào thì STT/TTS bị hủy, operation cũ
   bị vô hiệu, history bị xóa và micro không tự mở lại.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Gemini call | UI |
|---|---|---|---|---|
| AI_CHAT-F03-ALT01 | Transcript sau trim rỗng | Không thêm history; nghe lại nếu phiên còn active | Không | Giữ trạng thái nghe |
| AI_CHAT-F03-ERR01 | Mic/speech permission denied | Dừng session và audio | Không | Hướng dẫn cấp quyền/thử lại |
| AI_CHAT-F03-ERR02 | Access/session không hợp lệ trước khi mount | Không mount hoặc dừng session, fail-closed trong app | Không gọi từ UI hợp lệ | Hướng dẫn đăng nhập/nâng cấp |
| AI_CHAT-F03-ERR03 | Thiếu/sai Gemini key hoặc model/config không dùng được | Dừng session, không auto retry | Một request có thể thất bại | Báo Voice chưa sẵn sàng |
| AI_CHAT-F03-ERR04 | 408/429/5xx/network | Dừng session, không auto retry | Không gọi lại tự động | Báo tạm thời chưa sẵn sàng |
| AI_CHAT-F03-ERR05 | Response rỗng/không hợp lệ | Không thêm history | Một turn thất bại | Báo chưa thể trả lời |
| AI_CHAT-F03-ERR06 | TTS lỗi | Dừng session và audio | Không gọi thêm | Yêu cầu chủ động thử lại |
| AI_CHAT-F03-ERR07 | Stop/background khi listening/thinking/speaking | Hủy audio, tăng generation token và bỏ response đến muộn | Không thêm turn muộn | Về idle, không restart |

## E. Hợp đồng API và dữ liệu

| Contract | Quy định |
|---|---|
| Request | Repository nhận `message` non-empty tối đa 6.000 ký tự; datasource gửi tối đa 12 history item role `user`/`model`, mỗi item tối đa 6.000 ký tự, cùng current message qua `GeminiRestClient`. |
| Success | Gemini text non-empty đã trim/kiểm tra và tối đa 2.000 ký tự; chỉ khi đó repository mới append cặp history. |
| Errors | 408/429/network/5xx → temporarily unavailable; key/auth/model/config → unavailable; response rỗng → invalid response. |
| Gemini | Nabi tiếng Việt, trả lời ngắn, không chẩn đoán thay bác sĩ, hướng dẫn cấp cứu phù hợp; không truyền app-owned output token cap. |
| Privacy / risk | Không log transcript/history/key/raw response; không lưu SQLite/Supabase. Key không commit nhưng có thể bị trích xuất khỏi APK; paid gate chỉ ở client. |
| Reaction speed | 200/500/1.000/2.000 ms sau speech result gần nhất; default 1.000 ms; selection RAM qua Stop/Start cùng page. Không phải Gemini/network latency. |
| Listen duration | `listenFor = 180.000 ms` là hard cap app/plugin mỗi lượt. Final, endpointing, Stop/lifecycle/error hoặc recognizer OS có thể kết thúc sớm hơn; không bảo đảm raw audio đủ 3 phút trên mọi máy. |

## F. Acceptance Requirements

| ID | Requirement | Evidence required | Current status |
|---|---|---|---|
| AI_CHAT-TC03 | Plus và FamilyPlus vào được; Guest login redirect; Free CTA; loading/error/null/user mismatch fail-closed. | Widget/route tests | PASS |
| AI_CHAT-TC04 | Ít nhất hai turn đúng thứ tự và không có STT/TTS overlap. | Controller unit test với fake | PASS |
| AI_CHAT-TC05 | Transcript rỗng không gọi repository/Gemini. | Controller unit test | PASS |
| AI_CHAT-TC06 | Stop/background ở listening/thinking/speaking không restart và bỏ late response. | Controller lifecycle tests | PASS |
| AI_CHAT-TC07 | Permission, config/key/model, 408/429/network/5xx, invalid response và TTS error đều fail-safe. | Unit/widget tests | PASS |
| AI_CHAT-TC08 | History giữ đúng 6 lượt và xóa giữa các phiên/lifecycle. | Repository unit tests | PASS |
| AI_CHAT-TC09 | Concrete STT wrapper không coi `listen()` trả `null` là lỗi; chờ native `done/notListening` trước lượt mới. | MethodChannel/plugin contract tests | PASS |
| AI_CHAT-TC10 | Datasource lắp history/system instruction/model/config đúng và timeout sau 30 giây. | Flutter datasource tests với fake Gemini client | PASS |
| AI_CHAT-TC11 | Error mapping client-only đúng; response lỗi/rỗng không append history. | Flutter datasource/repository tests | PASS |
| AI_CHAT-TC12 | Source/log không lộ key/transcript/history/raw response và không còn runtime `voice-chat-turn`. | Flutter/static scans | PASS |
| AI_CHAT-TC13 | Android debug build và hội thoại tiếng Việt nhiều lượt trên thiết bị thật. | Build + device smoke | PASS — Xiaomi `220333QPG`, ba lượt liên tục |
| AI_CHAT-TC14 | iOS build và iPhone mic/STT/TTS/background smoke. | macOS/Xcode + device smoke | Pending |
| AI_CHAT-TC15 | Bốn mức map đúng 200/500/1.000/2.000 ms; default là 1.000 ms và selection RAM giữ qua Stop/Start cùng page. | Controller/state/widget tests | PASS — expanded targeted suite 86/86 |
| AI_CHAT-TC16 | Gateway bắt đầu với `pauseFor: null`, chỉ arm threshold sau partial non-empty đầu tiên, reset theo result mới và dừng ngay khi final. | Concrete MethodChannel/plugin contract tests | PASS — expanded targeted suite 86/86 |
| AI_CHAT-TC17 | Android cài lại và re-smoke Siêu nhanh 0,2 giây, Stop → đổi threshold → Start trong cùng page và hội thoại nhiều lượt. | Build + Xiaomi `220333QPG` device smoke | PASS — dropdown/default/delayed-arm/two-turn, safe network retry, selector lock/persistence, Stop trong TTS; AI_CHAT-TC13 baseline vẫn PASS |
| AI_CHAT-TC18 | Mỗi lượt truyền `listenFor = 180.000 ms`; final/endpointing vẫn kết thúc sớm; input 3.000 ký tự accepted, 6.001 rejected, response >2.000 rejected; build mới và Android compatibility smoke không còn app hard cap 60 giây. | Concrete gateway/repository/datasource tests + targeted analyze/test + Android build/install/device smoke | PARTIAL PASS — source, MethodChannel/controller assertions, expanded 90/90 tests, analyze 10 item/0 issue, format 21 file/0 changed, Android build/install PASS; >60-second continuity smoke pending; OS có thể final/stop trước 3 phút |
