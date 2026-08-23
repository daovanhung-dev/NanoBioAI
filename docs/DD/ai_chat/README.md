# DD — AI Chat

| Attribute | Value |
|---|---|
| Module Code | AI_CHAT |
| BD Module | M07 |
| Version | v1.7 |
| Lifecycle | Current |
| DD decision | Approved; Sequential Voice delta accepted |
| Implementation | Implemented |
| Verification | Static-verified at `25018e8`; Runtime-unverified for cross-device/iOS continuity; Sandbox-unverified |
| Source evidence | Auth-protected `/ai-chat` and `/ai-voice`, REST/STT/TTS controllers and access gate are reachable |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-08-23 |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M07, 16.1 AC-03/AC-04/AC-06, Appendix A UC-07 |

## Purpose
Cho phép Member hỏi đáp AI bằng chữ theo quota và cung cấp hội thoại giọng nói
tuần tự riêng cho Plus/FamilyPlus. Voice gọi Gemini REST trực tiếp từ Flutter,
cho phép chọn endpointing 0,2/0,5/1/2 giây sau lời nói; đây không phải
Gemini response latency. Mỗi lượt đặt hard cap nghe 3 phút nhưng final,
endpointing hoặc recognizer hệ điều hành có thể dừng sớm hơn. Guest, Free và mọi
trạng thái quyền không xác định đều bị chặn trước khi khởi tạo micro/controller.
User/history item Voice tối đa 6.000 ký tự; Gemini response vẫn tối đa 2.000 ký
tự và 256 output tokens.

## Documents in This Module
- [Overall](./Overall.md)
- [Feature List](./List_Features.md)
- [Function List](./Function_List.md)
- [Views](./Views.md)
- [Import and File Mapping](./Import_File.md)
- [Diagrams](./diagrams/README.md)
- [Assets](./assets/README.md)
- [Change History](./history/CHANGELOG.md)
- [Implementation Delta 2026-07-15 — Logbug 14-7-26](./Implementation_Delta_2026-07-15_Logbug_14-7-26.md)
- [Implementation Delta 2026-08-23 — Sequential Voice Plus](./Implementation_Delta_2026-08-23_Sequential_Voice_Plus.md)

## Traceability Summary
- AI_CHAT-F01: Mở AI Chat theo quyền
- AI_CHAT-F02: Gửi câu hỏi AI theo quota
- AI_CHAT-F03: Hội thoại giọng nói tuần tự cho Plus/FamilyPlus

## Dependent Modules
- MEMBERSHIP_QUOTA: access/quota.
- AUTH_PROFILE_SYNC: session.
- AUDIT_SECURITY: safe logging.
- Gemini API: Voice gọi trực tiếp qua `GeminiRestClient`; key lấy từ `AppEnv` và
  có thể bị trích xuất khỏi APK.

## Answered Questions
| ID | Question | Decision | Status |
|---|---|---|---|
| Q-16 | Which timezone is authoritative? | Use Vietnam timezone, Asia/Ho_Chi_Minh. | Answered - User decision 2026-06-30 |

## Approval Status
| Role | Approver | Status | Date |
|---|---|---|---|
| BA/PO | Product Owner | Approved by DD acceptance pass | 2026-06-30 |
| Tech Lead | Tech Lead | Approved by DD acceptance pass | 2026-06-30 |
| QA Lead | QA Lead | Approved by DD acceptance pass | 2026-06-30 |

## Validation Notes
- DD docs complete: all product questions are answered and documented as implementation policy.
- Runtime, sandbox/RLS/API smoke, and production acceptance evidence are tracked in the Implementation Evidence Backlog, not as DD blockers.
- Runtime code, SQL, Supabase config, and tests were not changed in this DD docs 100 percent pass.
- Baseline client-only đã có targeted validation và ba lượt Android device
  smoke PASS trên Xiaomi `220333QPG`. Kết quả này được giữ nguyên nhưng
  không tự động chứng minh delta tốc độ phản ứng mới.
- Bốn threshold 0,2/0,5/1/2 giây, default/selection RAM, expanded 86/86
  tests và Android re-smoke đã PASS; iOS vẫn chờ macOS/iPhone.
- Thiết kế Gemini Live và Edge Function Voice trước đây đã bị thay thế; contract
  hiện tại chấp nhận rủi ro key nằm trong APK và quyền Plus chỉ được gate trong
  app. APK bị sửa hoặc key bị lấy có thể bỏ qua giới hạn này.
