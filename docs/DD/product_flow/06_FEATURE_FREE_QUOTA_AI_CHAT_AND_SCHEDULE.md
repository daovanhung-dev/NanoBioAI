# DD-PRODUCT-FLOW-FR-003 - Free Quota cho AI Chat và Tạo Lịch Trình

**BD nguồn:** BR-05, UC-06, UC-07, AC-04, AC-05, Section 9.2  
**Status:** Draft  
**Dependencies:** 03, 05, 13, 14, 15, `.codex/playbooks/ai_service.md`  

## 1. Mục tiêu và outcome

Free user có AI Chat tối đa 3 lượt/ngày và tạo lịch trình cá nhân mới tối đa 3 lần/tháng. Quota phải kiểm tra trước khi gọi AI hoặc ghi dữ liệu mới.

## 2. Trigger / Preconditions

- User đã đăng nhập và effective access là Free.
- User gửi AI Chat message hoặc yêu cầu tạo lịch trình mới.
- Supabase/trusted quota source sẵn sàng đọc/ghi.

## 3. Input contract

| Field | Required | Type | Validation | Sensitive? |
|---|---:|---|---|---|
| userId | Yes | UUID | Current auth user only | Yes |
| featureKey | Yes | enum | `ai_chat_message` hoặc `personal_schedule_generation` | No |
| periodKey | Yes | string | Derived by server/RPC from reset policy | No |
| idempotencyKey | Yes for consume | string | Unique per request | No |

## 4. Output / Postconditions

- Trong quota: action được phép tiếp tục và quota usage được ghi bởi trusted layer.
- Vượt quota: action bị chặn, không gọi Gemini/AI và không ghi schedule mới.
- Plus/FamilyPlus không bị chặn bởi quota Free theo DD-PRODUCT-FLOW-FR-004/005.

## 5. Happy path

```text
1. Controller nhận action AI Chat hoặc generate schedule.
2. Use-case yêu cầu quota service kiểm tra quyền tiêu thụ.
3. Trusted quota layer xác nhận còn quota.
4. Action gọi AI/service.
5. Khi action được tính là thành công theo Q-03, quota event/counter được ghi idempotent.
6. UI cập nhật remaining usage nếu có.
```

## 6. Alternative and error flows

| Case | Detection | UI behavior | Technical behavior | Retry |
|---|---|---|---|---|
| Free vượt 3 chat/ngày | quota check false | Mời quay lại ngày mai/nâng cấp | Không gọi AI | Sau reset/nâng cấp |
| Free vượt 3 schedule/tháng | quota check false | Mời đăng nhập/nâng cấp phù hợp | Không gọi AI/save schedule | Sau reset/nâng cấp |
| Quota service unavailable | network/server error | Báo chưa thể kiểm tra lượt | Fail closed với paid/resource action | Retry |
| AI call fail after quota reserved | action error | Báo lỗi thử lại | Idempotency/reversal policy phụ thuộc backend | Retry theo policy |

## 7. Persistence and ownership

| Action | Target | Actor allowed | RLS/constraint |
|---|---|---|---|
| Read quota rule/counter | Supabase quota tables | authenticated user own rows | RLS own read |
| Consume quota | RPC/Edge/trusted backend | server-side only | Client cannot write counter directly |
| Generate schedule | meal/tasks/schedule tables | authenticated allowed subject | quota must pass first |

## 8. Layer responsibilities / affected files

| Layer | Responsibility | Proposed file |
|---|---|---|
| Presentation | Show quota exhausted state with Nami copy | AI chat / dashboard/generate pages |
| Controller | Block before AI call | AI chat controller, dashboard/generated plan controller |
| Domain | Quota service contract | `v2/features/usage_quota`, `personal_schedule_quota` |
| Datasource | Supabase/RPC quota calls | v2 data layer / trusted backend wrapper |
| AI service | No quota decision, only generation | `lib/app_versions/v1/services/ai/*` |

## 9. Security / privacy

- Client không tự tăng `usage_quota_counters`.
- Không log prompt/raw health data khi quota fail.
- Không bypass quota bằng offline/local state.

## 10. Acceptance tests

- TC-PF-09: Free chat lượt 1..3 được phép.
- TC-PF-10: Free chat lượt 4 trong ngày bị chặn trước AI call.
- TC-PF-11: Free tạo lịch trình lần 4 trong tháng bị chặn trước AI call.
- TC-PF-12: Plus/FamilyPlus không bị chặn bởi hai quota Free.

## 11. Non-goals

- Không quyết định giá gói/nâng cấp.
- Không quyết định chính xác "một lượt hỏi" nếu Q-03 chưa chốt.

## 12. Open decisions

| ID | Question | Owner | Impact |
|---|---|---|---|
| Q-03 | Một lượt AI Chat là tin nhắn, phiên chat hay AI request thành công? | Product Owner / Tech Lead | Khi nào consume quota |
| Q-04 | Reset quota ngày/tháng theo timezone nào và xử lý đổi timezone ra sao? | Product Owner / Tech Lead | `periodKey`, reset time, anti-abuse |

