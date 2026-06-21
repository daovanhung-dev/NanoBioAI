# DD-PRODUCT-FLOW-FR-001 - Guest Onboarding và Lịch Trình AI Lần Đầu

**BD nguồn:** BR-01, BR-02, BR-03, UC-01, UC-02, UC-03, AC-01, AC-02, AC-03  
**Status:** Draft  
**Dependencies:** 03, 12, 13, 14, 15, `.codex/playbooks/onboarding.md`, `.codex/playbooks/ai_service.md`  

## 1. Mục tiêu và outcome

Guest hoàn tất onboarding không cần đăng nhập, app lưu đủ dữ liệu đầu vào, sinh đúng một lịch trình cá nhân đầu tiên gồm meal plan, bài tập/daily task và timeline, sau đó chỉ cho dùng V1 allowlist.

## 2. Trigger / Preconditions

- User mở app lần đầu hoặc chưa hoàn tất onboarding.
- User có thể chọn onboarding ngay mà chưa đăng nhập.
- Dữ liệu onboarding hợp lệ theo validation hiện có.

## 3. Input contract

| Field | Required | Type | Validation | Sensitive? |
|---|---:|---|---|---|
| Personal profile | Yes | structured form | Tuổi/giới/chiều cao/cân nặng trong range hợp lệ | Yes |
| Health goals | Yes | list/code | Ít nhất một mục tiêu nếu UI yêu cầu | Yes |
| Habits/conditions/allergies/treatments | No/conditional | list/code/text | Không ghi record rỗng | Yes |
| Survey answers | Conditional | key/value | Mã câu hỏi không trùng | Yes |

## 4. Output / Postconditions

- Local SQLite có profile/goals/habits/conditions/allergies/treatments/survey answers.
- Lịch trình cá nhân đầu tiên được tạo và lưu: meal plan, exercise/daily tasks, lifestyle schedule items.
- Notification theo lịch được tạo theo DD-PRODUCT-FLOW-FR-009.
- Guest không được tạo thêm lịch trình mới nếu chưa đăng nhập.

## 5. Happy path

```text
1. Guest nhập onboarding.
2. Controller validate form.
3. Repository lưu dữ liệu personal vào SQLite.
4. AI service tạo lịch trình cá nhân đầu tiên từ dữ liệu onboarding.
5. Normalizer/validator chuẩn hóa text tiếng Việt và schema.
6. App lưu meal/tasks/schedule.
7. App lập notification theo từng mốc.
8. Router đưa Guest vào V1 allowlist/dashboard/menu phù hợp.
```

## 6. Alternative and error flows

| Case | Detection | UI behavior | Technical behavior | Retry |
|---|---|---|---|---|
| Form invalid | Controller validation | Hiện lỗi nhẹ nhàng, giữ dữ liệu đã nhập | Không ghi DB/AI call | User sửa input |
| AI timeout/quota/invalid JSON | AI service exception/validator | Thông báo Nami chưa thể tạo lịch lúc này | Không crash, không ghi partial invalid data | Cho retry nếu chưa đánh dấu đã dùng lượt |
| Guest đã có lịch trình đầu tiên | Local/trusted state theo quyết định Q-01 | Mời đăng nhập để tạo thêm | Chặn trước khi gọi AI | Sau login đi qua quota |
| Deep-link/module ngoài V1 | Route/use-case guard | Điều hướng đăng nhập/đăng ký | Guard chặn route và use-case | Login/signup |

## 7. Persistence and ownership

| Action | Target | Actor allowed | RLS/constraint |
|---|---|---|---|
| Save onboarding local | SQLite profile tables | Guest local user | Local only until sync decision |
| Generate initial schedule | AI service + local DB | Guest once | Q-01 controls exact identity boundary |
| Generate additional schedule | AI service | Guest not allowed | Requires auth + membership/quota |

## 8. Layer responsibilities / affected files

| Layer | Responsibility | Proposed file |
|---|---|---|
| Presentation | Form, loading/error/success, no direct DB | `lib/app_versions/v1/features/onboarding/presentation/*` |
| Controller | Validation orchestration and state | `onboarding_controller.dart` |
| Repository/datasource | Save local onboarding data | `onboarding_repository_impl.dart`, `onboarding_local_datasource.dart` |
| AI service | Generate and normalize plan | `generated_plan_service.dart`, AI normalizers |
| Notification service | Schedule reminders | `lib/app_versions/v1/services/notifications/*` |

## 9. Security / privacy

- Không log hồ sơ sức khỏe chi tiết, raw prompt hoặc raw AI response.
- Không dùng local flag để mở paid/Free/Plus features.
- User-facing copy phải là tiếng Việt có dấu, không nói database/table/parser/exception.

## 10. Acceptance tests

- TC-PF-01: Guest hoàn tất onboarding và có lịch trình đủ 3 thành phần.
- TC-PF-02: Guest tạo thêm lịch trình bị chặn trước AI call.
- TC-PF-03: Guest deep-link vào module ngoài V1 bị chặn.
- TC-PF-04: AI invalid output không crash và không ghi dữ liệu sai.

## 11. Non-goals

- Không định nghĩa công thức score.
- Không định nghĩa sync Guest local data sang Supabase; phụ thuộc Q-02.
- Không mở Anonymous Auth migration nếu chưa chốt Q-01/Q-02.

## 12. Open decisions

| ID | Question | Owner | Impact |
|---|---|---|---|
| Q-01 | Guest "1 lần tạo lịch trình" tính theo thiết bị, local profile, anonymous user hay account? | Product Owner / Tech Lead | Chống tạo lại và migration strategy |
| Q-02 | Guest login/signup có sync local schedule/onboarding vào Supabase không? | Product Owner / Tech Lead | Cloud sync và ownership |

