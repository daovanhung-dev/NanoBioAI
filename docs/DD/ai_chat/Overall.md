# Overall — AI_CHAT / AI Chat

## 1. Document Information

| Attribute | Value |
|---|---|
| Module Code | AI_CHAT |
| BD Module | M07 |
| Version | v1.7 |
| DD decision | Approved |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M07, 16.1 AC-03/AC-04/AC-06, Appendix A UC-07 |
| Created Date | 2026-06-28 |
| Last Updated | 2026-09-13 |
| Release Scope | Project DD baseline for M01-M19 |

## 2. Business Goal
Module này đảm bảo AI Chat chỉ mở cho tài khoản có quyền, không gọi AI khi quota
bị chặn và không lưu/log raw sensitive response. Với Voice, module cung cấp luồng
tuần tự tối giản cho Plus/FamilyPlus và gọi Gemini trực tiếp từ Flutter. Micro
không mở khi quyền chưa được xác nhận fail-closed trong app; key trong APK và
client-only paid gate là rủi ro được chấp nhận rõ ràng.

## 3. Module Scope

### In Scope
- Gate AI Chat theo đăng nhập/gói.
- Quota Free 3 lượt/ngày.
- Plus/FamilyPlus không bị quota Free.
- Xử lý lỗi AI an toàn.
- Voice Plus/FamilyPlus theo chuỗi
  `speech_to_text -> Flutter datasource -> Gemini generateContent -> flutter_tts`.
- Tùy chọn endpointing sau lời nói: Siêu nhanh 0,2 giây, Nhanh 0,5
  giây, Bình thường 1 giây mặc định và Chậm 2 giây.
- Hard cap mỗi lượt nghe là 3 phút/180.000 ms; final, endpointing và giới hạn
  recognizer hệ điều hành vẫn có thể kết thúc sớm hơn.
- Lịch sử Voice tối đa 6 lượt hỏi-đáp trong RAM, không ghi SQLite/Supabase.

### Out of Scope
- Ghi raw prompt/response thật vào DD hoặc log.
- Medical diagnosis.
- Model/provider tuning chi tiết.
- Gemini Live/full-duplex, nói chen, custom PCM, Bluetooth acceptance, offline và
  lưu lịch sử Voice.

## 4. Roles and Permissions

| Role | Permissions in This Module | Limitations |
|---|---|---|
| Guest | Không dùng AI Chat/Voice. | Chuyển tới đăng nhập; không mount controller/micro. |
| Free | Dùng AI Chat chữ theo quota. | Không dùng Voice; nhận CTA nâng cấp Plus. |
| Plus, FamilyPlus | Dùng AI Chat chữ và Voice tuần tự. | Voice vẫn chịu giới hạn/rate limit của Gemini; không có quota Voice NanoBio. |
| System | Validate state, apply business rules, write events/audit where required. | Must be idempotent and must follow accepted product decisions. |
| Admin/Super Admin | Operate only where BD grants admin responsibility. | Backend/API must reject missing permission; UI hiding is not sufficient. |

## 5. Primary Entities/Data

| Entity ID | Entity | Purpose | Important Attributes | Relationships |
|---|---|---|---|---|
| AI_CHAT-E-ai_request | AI Request | Theo dõi request chat | request_id, user, status, quota impact | Uses quota ledger |
| AI_CHAT-E-chat_message | Chat Message | Tin nhắn chat nếu lưu | owner, role, content summary, created_at | Subject to privacy policy |
| AI_CHAT-E-voice_session | Voice Session (RAM only) | Giữ tối đa 12 message và reaction-speed selection cho page/controller đang mở | role, text, sequence, reaction speed | History xóa theo lifecycle; selection giữ qua Stop/Start cùng page, reset 1 giây khi tạo controller/page mới; không persistence |

## 6. States and State Transitions

| Entity / Group | States | Notes |
|---|---|---|
| AI Request | created, validating, sent, succeeded, failed, quota_blocked | Source: BD Appendix B and module sections. |
| Voice Session | idle, listening, thinking, speaking, error | `listening -> thinking -> speaking -> listening`; micro luôn tắt ở `thinking` và `speaking`. Stop/background đưa về `idle` và vô hiệu hóa kết quả đến muộn. |

## 7. Business Rules

| ID | Rule | Applied At | Criticality |
|---|---|---|---|
| AI_CHAT-BR01 | Guest không được mở AI Chat. | AI chat gate and quota consumption | Mandatory |
| AI_CHAT-BR02 | Free bị chặn ở lượt hỏi thứ 4 trong ngày; Plus/FamilyPlus không bị quota Free. | AI chat gate and quota consumption | Mandatory |
| AI_CHAT-BR03 | Voice chỉ mount cho user hiện tại có `hasPaidAccess` thuộc Plus hoặc FamilyPlus. Loading, error, null, user mismatch, anonymous và Free đều fail-closed trong app. | Route/page gate | Mandatory |
| AI_CHAT-BR04 | Voice datasource gọi Gemini REST trực tiếp bằng `GeminiRestClient`; model resolve `GEMINI_CHAT_MODEL -> GEMINI_MODEL -> gemini-3.5-flash`. | Flutter datasource / `AppEnv` | Mandatory |
| AI_CHAT-BR05 | Voice không trừ quota NanoBio và không tạo bảng/RPC/quota mới; giới hạn dịch vụ Gemini vẫn áp dụng. | Repository/client | Mandatory |
| AI_CHAT-BR06 | STT, Gemini và TTS chạy tuần tự; không có STT/TTS overlap. Transcript rỗng không gọi Gemini. | Voice controller | Mandatory |
| AI_CHAT-BR07 | History chỉ ở RAM, tối đa 12 message tương ứng 6 lượt hỏi-đáp và được xóa theo vòng đời phiên. | Voice repository | Mandatory |
| AI_CHAT-BR08 | Stop/background/dispose phải hủy STT/TTS, vô hiệu hóa response đến muộn và không tự mở micro lại. | Voice controller | Mandatory |
| AI_CHAT-BR09 | Không log transcript, history, Gemini key hoặc response thô; lỗi phải ánh xạ thành thông báo an toàn. Key không được commit nhưng có thể bị trích xuất khỏi APK. | App | Mandatory |
| AI_CHAT-BR10 | Reaction speed là endpointing silence sau speech result: 200/500/1.000/2.000 ms, default 1.000 ms. Chỉ arm sau partial non-empty đầu tiên; final result dừng ngay. Đây không phải Gemini/network latency. | Voice state/controller/device gateway | Mandatory |
| AI_CHAT-BR11 | Mỗi lượt STT đặt `listenFor = 180.000 ms` làm hard cap phía app/plugin. Final result, endpointing, Stop/lifecycle/error hoặc recognizer OS có thể kết thúc sớm hơn; không cam kết raw audio liên tục đủ 3 phút trên mọi máy. User message/history item Voice tối đa 6.000 ký tự; Gemini response tối đa 2.000 ký tự và không có app-owned output token cap. | Voice device gateway / repository / datasource | Mandatory |

## 8. Overall Operational Flow

1. Actor enters the module through the planned view or event listed in Views.md.
2. System validates authentication, entitlement, role, ownership, family scope, Sale status, or Admin permission as applicable.
3. System loads only the data needed for AI Chat.
4. Feature function applies module business rules and cross-cutting rules from BD sections 14 and 15.
5. Successful writes use transaction/idempotency and audit where required.
6. UI/API returns a safe business result and never exposes raw stack trace, DB/API wording, secret, payment evidence, or unnecessary health data.

### 8.1. Voice sequential flow (`AI_CHAT-F03`)

1. Route yêu cầu đăng nhập; access gate xác nhận đúng user hiện tại và
   Plus/FamilyPlus trước khi mount trang/controller.
2. Người dùng chọn **Tốc độ phản ứng** hoặc giữ mặc định
   **Bình thường 1 giây**, rồi nhấn **Bắt đầu**; repository xóa history RAM
   và controller mở STT.
3. Gateway bắt đầu nghe với hard cap 3 phút nhưng chưa có pause timer. Sau partial non-empty đầu
   tiên, threshold 0,2/0,5/1/2 giây được áp dụng. Final result hoặc
   threshold im lặng dừng micro sớm hơn hard cap; transcript rỗng được bỏ qua
   và tiếp tục nghe. Recognizer OS vẫn có thể final/stop trước 3 phút.
4. Controller gửi message đến repository; datasource lắp tối đa 12 history item
   và gọi `AI_CHAT-API03` trực tiếp qua `GeminiRestClient`.
5. Gemini REST trả text đã kiểm tra; không có quota NanoBio hoặc server Voice
   kiểm tra quyền lại trước request.
6. Controller chờ TTS đọc xong, đợi thêm khoảng 300 ms rồi mới mở STT cho turn kế.
7. Permission/Gemini/TTS error dừng vòng lặp. Người dùng phải chủ động thử lại.
8. Stop, background hoặc rời trang hủy audio, xóa history và chặn mọi callback cũ.

## 9. Integrations and Dependencies

| Dependency | Type | Purpose | Failure Behavior |
|---|---|---|---|
| Auth/Profile | Internal/Supabase planned | Identify actor and ownership. | Block action or request login. |
| Membership/Entitlement | Internal/trusted backend planned | Apply Free/Plus/FamilyPlus access and quotas. | Keep previous state; do not grant paid access. |
| Audit/Security | Cross-cutting | Trace sensitive changes. | Sensitive writes must fail or be queued safely if audit cannot be recorded. |
| Module-specific dependencies | Internal | MEMBERSHIP_QUOTA: access/quota., AUTH_PROFILE_SYNC: session., AUDIT_SECURITY: safe logging. | Follow dependency owner DD and record conflict as an implementation issue or accepted exception. |
| `speech_to_text` / `flutter_tts` | Device libraries | Nhận dạng từng câu và phát câu trả lời. | Dừng phiên, hiển thị lỗi an toàn, không tự retry vô hạn. |
| `AppEnv` / native runtime config | Client config | Cấp Gemini key/model cho Flutter. | Thiếu/sai config dừng Voice; key có thể bị trích xuất khỏi APK. |
| Gemini `generateContent` | External AI qua trusted Edge Function | Sinh câu trả lời Nabi tiếng Việt; NanoBio không đặt output token cap, vẫn giữ response-size safety bound. | Gộp text parts; `MAX_TOKENS` là lỗi typed, không trả partial response. |

## 10. Non-Functional Requirements

| Category | Requirement |
|---|---|
| Security | Route/page fail-closed theo access từ Supabase, nhưng không có server Voice enforcement. Key nằm trong client runtime/APK; không hard-code/commit/log và chấp nhận khả năng bị trích xuất/bypass. |
| Data Integrity | Use unique business keys/idempotency for writes, especially payment, quota, point, family, notification, and admin actions. |
| Privacy | Minimize health/family data; Voice transcript/history chỉ ở RAM và không xuất hiện trong log. |
| Observability | Chỉ log stage/status/error type an toàn; không log transcript, history, key hoặc raw Gemini response. |
| Resilience | Voice error dừng vòng lặp; Stop/background làm callback cũ vô hiệu và không restart micro. Endpointing target không được mô tả như cam kết Gemini response latency; hard cap 3 phút không được mô tả như bảo đảm recognizer/raw audio luôn chạy đủ thời lượng. |

## 11. Risks, Assumptions, and Decisions

| ID | Type | Content | Impact | Status |
|---|---|---|---|---|
| AI_CHAT-RISK01 | Implementation evidence backlog | Runtime/sandbox evidence, final wireframes, and production acceptance remain outside DD completeness. | Implementation must produce evidence before production release. | Tracked |
| AI_CHAT-ASSUMPTION01 | Assumption | BD v2.0 plus user decisions from 2026-06-30 are the source of truth; legacy conflicting Sale/Admin logic is not implementation source. | Implementation must migrate or reject old behavior such as Sale tree, tier-2 commission, or 5 percent rules. | Active |
| AI_CHAT-Q-16 | Answered decision | Which timezone is authoritative? | Use Vietnam timezone, Asia/Ho_Chi_Minh. | Accepted - User decision 2026-06-30 |
| AI_CHAT-RISK02 | Acceptance evidence backlog | Client-only/Android baseline và reaction-speed delta đã PASS; hard cap nghe 3 phút đã PASS source/90 tests/analyze/build/install nhưng chưa có continuity smoke qua mốc 60 giây; iOS chưa có build/device evidence. | Không claim >60-second Android continuity hoặc suy rộng Android evidence sang iOS trước verification tương ứng. | Tracked |
| AI_CHAT-RISK03 | Accepted security exception | Gemini key nằm trong app và Plus-only chỉ được enforce bởi Flutter. APK bị sửa hoặc key bị lấy có thể bỏ qua giới hạn. | Không phù hợp khi cần chống lạm dụng key/paid access tin cậy; khi đó phải dùng backend proxy. | Accepted by user 2026-08-23 |

## 12. ADR Summary

| ID | Decision | Context | Status |
|---|---|---|---|
| AI_CHAT-ADR01 | Approve this module DD as docs-complete and track runtime/sandbox evidence separately. | The user requested DD docs 100 percent without changing runtime code or claiming sandbox evidence. | Accepted |
| AI_CHAT-ADR02 | Keep accepted product decisions as the module business contract. | Q-01..Q-18 are closed by user decision and recorded in the DD registry. | Accepted |
| AI_CHAT-ADR03 | Dùng half-duplex STT→Flutter Gemini REST→TTS và không có backend Voice. | User xác nhận chỉ có Supabase database và chấp nhận key/APK cùng client-gate risk để giữ triển khai tối giản. | Accepted; supersedes Voice Live và Edge Function Voice |
| AI_CHAT-ADR04 | Cho chọn endpointing 0,2/0,5/1/2 giây; default 1 giây và chỉ lưu selection trong RAM page/controller. | User muốn kiểm soát khoảng ngắt lời trước khi gửi turn cho Gemini. | Accepted 2026-08-23 |
| AI_CHAT-ADR05 | Tăng `listenFor` mỗi lượt từ 60 giây lên 3 phút/180.000 ms; endpointing/final vẫn kết thúc sớm hơn. Đồng thời nới user/history item Voice lên 6.000 ký tự, giữ Gemini response ở 2.000 ký tự và bỏ app-owned output token cap. | User muốn có thể nói dài hơn trong một lượt mà không thay đổi half-duplex, tốc độ phản ứng hoặc output safety bound. | Accepted 2026-08-23; token-cap delta superseded by 2026-09-13 fixbug |

## 13. Traceability Matrix

| BD/Requirement | Feature | Function | View | API | Test |
|---|---|---|---|---|---|
| BD M07 luồng, AC-03/AC-06 | AI_CHAT-F01 | AI_CHAT-FN01 | AI_CHAT-V01 | AI_CHAT-API01 | AI_CHAT-TC01 |
| BD M07 rules, AC-04 | AI_CHAT-F02 | AI_CHAT-FN02 | AI_CHAT-V02 | AI_CHAT-API02 | AI_CHAT-TC02 |
| User-approved Sequential Voice + reaction-speed + 3-minute hard-cap plans 2026-08-23 | AI_CHAT-F03 | AI_CHAT-FN03 | AI_CHAT-V03 | AI_CHAT-API03 | AI_CHAT-TC03..AI_CHAT-TC18 |

## 14. Approval Checklist

- [x] Scope and out-of-scope reviewed for DD docs completeness.
- [x] Business rules reviewed for DD docs completeness.
- [x] UI states reviewed for DD docs completeness.
- [x] API/schema/RLS contracts documented for implementation planning.
- [x] Product decisions answered or accepted as explicit implementation policy.

## 15. Accepted Product Decision Contract

| ID | Accepted Policy | Implementation Contract | Source |
|---|---|---|---|
| Q-16 | Use Vietnam timezone, Asia/Ho_Chi_Minh. | Quota reset, reporting windows, payment hold, refund/cancel window, schedule/day boundaries, and audit display use Asia/Ho_Chi_Minh. | User decision 2026-06-30 |

### Implementation Evidence Backlog

| Evidence Area | Required evidence before production acceptance | DD blocker? |
|---|---|---|
| Runtime/test/sandbox | M06 quota gate before production AI calls. | No - tracked outside DD completeness |
| Coding progress | Update only when code, tests, SQL/RPC, or sandbox evidence changes. | No |
| Production acceptance | Requires implementation workflow evidence and worklog command output. | No |
| Voice baseline source/device | Client-only targeted validation và ba lượt tiếng Việt trên Xiaomi `220333QPG`; không cancel/concurrent listen/STT-TTS overlap. | No - PASS; giữ là regression baseline |
| Voice reaction-speed source | Unit/widget/plugin tests cho 200/500/1.000/2.000 ms, default/selection RAM, delayed arm và final result. | No - PASS trong expanded 86/86 tests; analyze 10 item/0 issue |
| Voice Android reaction re-smoke | Build/install lại; Siêu nhanh 0,2 giây, Stop → đổi threshold → Start cùng page và multi-turn. | No - PASS trên Xiaomi `220333QPG`; delayed arm, safe network retry, selector lock/persistence và Stop trong TTS |
| Voice 3-minute hard cap/text bounds | Source test xác nhận `listenFor = 180.000 ms`, final/endpointing vẫn thắng; input 3.000 ký tự accepted, 6.001 rejected, response >2.000 rejected; Android compatibility smoke qua mốc 60 giây khi OS cho phép. | No - source/90 tests/analyze/build/install PASS; >60-second device continuity pending; không claim OS luôn giữ recognizer/raw audio đủ 3 phút |
| Voice iOS | Xcode build và iPhone mic/speech/TTS/background smoke trên macOS. | No - pending |
