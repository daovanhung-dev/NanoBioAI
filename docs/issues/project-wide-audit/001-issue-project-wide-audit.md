# NanoBio Project-Wide Bug & Logic Audit

## 1. Audit metadata

| Thuộc tính | Giá trị |
|---|---|
| Repository | `daovanhung-dev/NanoBioAI` |
| Baseline commit | `7b2b90d5e0946721c2ac78363100e48a09f2032a` |
| Audit date | 2026-08-17 |
| Workflow | `find-issues` |
| Mode | Static project-wide audit, không sửa runtime code |
| Commit đề xuất | `docs(issue): ghi nhận project-wide NanoBio audit` |

### Mục tiêu

Rà soát bug ẩn, lỗi logic, lỗi thao tác và lỗi đồng bộ xuyên module của NanoBio tại đúng baseline commit nêu trên, tập trung vào:

- sai source-of-truth / sai subject-owner;
- dữ liệu thay đổi ở một view nhưng view khác còn stale;
- cùng chức năng nhưng semantics khác nhau giữa các màn;
- DD/BD contract không khớp runtime/test;
- notification/action state không khớp schedule/task state;
- state machine được hiển thị xong nhưng không persist đúng;
- lỗi có thể gây mất dữ liệu, sai dữ liệu người dùng hoặc trải nghiệm khó hiểu.

## 2. Source of truth và phạm vi

Thứ tự ưu tiên khi có mâu thuẫn:

1. Runtime source tại baseline commit.
2. Targeted tests hiện tại.
3. Supabase/RPC/SQLite contracts.
4. DD module Approved.
5. BD nguồn.
6. `.codex` project context/history.

### Kiến trúc runtime dùng để audit

```text
Presentation
  -> Provider / Controller
  -> Repository
  -> Datasource
  -> DAO / SQLite / Supabase RPC / External Service
```

Các mutation chính được trace theo fan-out:

```text
Onboarding/Profile
      |
      v
Generated Plan
  |       |        |
Meals   Tasks   Schedule
  \       |       /
   \      v      /
   Dashboard / Today Tasks
          |
          v
 Completion / Skip / Proof
          |
          v
 Health Score / Rewards / Notification / Cloud Sync
```

### Phạm vi module theo DD hiện tại

- M01-M19: Approved DD baseline.
- M30 Nabi Companion Notifications: Approved implementation contract.
- M20-M29: Draft / DD chưa được tạo; việc chưa có implementation đầy đủ **không được coi là bug**.

## 3. Executive summary

### Kết quả

- **7 confirmed issues**.
- **3 HIGH**.
- **4 MEDIUM**.
- Không có finding nào được nâng thành BLOCKER chỉ từ static evidence.
- Có thêm các validation risk chưa đủ bằng chứng để gọi là functional bug.

| ID | Severity | Nhóm | Tóm tắt |
|---|---|---|---|
| NB-AUD-001 | HIGH | SECURITY / IDENTITY | Daily Routine chọn user local theo `created_at DESC`, có thể đọc/ghi nhầm tài khoản |
| NB-AUD-002 | MEDIUM | DATA LOSS / UX | Daily Routine load lỗi nhưng UI dùng defaults và vẫn cho Save |
| NB-AUD-003 | HIGH | CROSS_VIEW / DATA_CONSISTENCY | Thay món cập nhật DB nhưng không invalidate Schedule/Dashboard providers |
| NB-AUD-004 | MEDIUM | UX / LOGIC | Today Tasks “Thay món” tự chọn candidate đầu tiên, khác semantics Meal Plan |
| NB-AUD-005 | HIGH | CONTRACT / STATE_SYNC | Notification action `skipped` không skip schedule item/task thực tế |
| NB-AUD-006 | MEDIUM | DOCUMENTATION_DRIFT | M01 DD chưa phản ánh Daily Routine onboarding step runtime hiện tại |
| NB-AUD-007 | MEDIUM | M30 STATE_MACHINE | Nabi secondary action non-defer không persist terminal status |

---

# 4. Detailed findings

## NB-AUD-001 — Daily Routine có thể resolve sai user local

**Severity:** HIGH  
**Type:** SECURITY / PRIVACY / IDENTITY / DATA_CONSISTENCY  
**Primary area:** Daily Routine, Onboarding  
**Affected flow:** Guest/local subject -> routine preferences -> onboarding -> schedule timing

### Summary

`DailyRoutinePreferencesLocalDatasource.resolveCurrentUserId()` dùng user Supabase nếu có session. Khi không có session, nó fallback sang record mới nhất trong bảng `users` bằng `ORDER BY created_at DESC LIMIT 1`.

Điều này mâu thuẫn trực tiếp với core subject resolver của dự án: storage recency không được dùng làm identity signal.

### Expected

Khi guest/offline:

- resolve đúng active/pending guest subject;
- nếu local DB có nhiều owner nhưng không xác định được subject thì fail closed;
- tuyệt đối không suy ra identity từ record tạo gần nhất.

### Actual

Daily Routine tự chọn row mới nhất trong `users`.

### Evidence

- `lib/core/access/local_subject_resolver.dart`
  - Core contract nêu rõ storage recency không được dùng làm identity signal.
  - Resolver chuẩn dựa trên authenticated actor hoặc durable pending guest; ambiguity phải fail.
- `lib/app_versions/v1/features/daily_routine/data/datasources/daily_routine_preferences_local_datasource.dart`
  - `resolveCurrentUserId()` fallback query `users ORDER BY created_at DESC LIMIT 1`.
- `lib/app_versions/v1/features/daily_routine/domain/repositories/daily_routine_preferences_repository_impl.dart`
  - current-user load/save dùng datasource resolver trên.
- `lib/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart`
  - onboarding lưu routine thông qua `saveForCurrentUser(...)` thay vì luôn truyền explicit subject ID của hồ sơ vừa lưu.

### Reproduction

1. Local DB có user A và B.
2. B được tạo sau A.
3. Không có Supabase session.
4. Active/pending guest thực tế là A.
5. Mở hoặc Save `Daily Routine Preferences`.
6. Resolver có thể chọn B vì B có `created_at` mới hơn.

### Impact

- Đọc nhịp sinh hoạt của người khác trên cùng local DB.
- Ghi đè preferences của owner khác.
- Rủi ro privacy/cross-account contamination.
- Các flow dùng routine hiện tại có thể hiển thị/ghi cấu hình không thuộc active subject.

### Suggested fix direction

- Dùng canonical `LocalSubjectResolver` / `SubjectAccessContext`.
- Bỏ hoàn toàn identity-by-recency.
- Trong onboarding, truyền explicit user/subject ID đã được resolved/saved.
- Fail closed nếu local subject ambiguous.

### Regression tests required

- 2 local users + no Supabase session + pending guest A => resolve A.
- 2 users + không có durable active subject => throw/fail closed.
- Onboarding save routine phải ghi đúng owner explicit.
- Logout/login account khác không được reuse routine owner trước.

---

## NB-AUD-002 — Daily Routine load lỗi nhưng UI biến lỗi thành defaults có thể Save

**Severity:** MEDIUM  
**Type:** DATA LOSS / ERROR_HANDLING / UX  
**Primary area:** Daily Routine

### Summary

Khi provider load routine preferences bị lỗi, page có thể dựng draft bằng `DailyRoutinePreferences.defaults()` và vẫn expose Save. Lỗi đọc tạm thời vì SQLite/decoding có thể bị người dùng hiểu thành “chưa thiết lập”, sau đó Save defaults đè dữ liệu thật.

### Expected

- Error state khác rõ Empty state.
- Khi load failed, editor không được cho Save dữ liệu giả định.
- Có Retry; reset-to-defaults chỉ xảy ra qua explicit user action.

### Actual

Error rendering có thể sử dụng `_draft ?? DailyRoutinePreferences.defaults()` và giữ editor/save path hoạt động.

### Evidence

- `lib/app_versions/v1/features/daily_routine/presentation/pages/daily_routine_preferences_page.dart`
  - Error path sử dụng default model khi draft chưa có.
  - Save path không có invariant “initial load must succeed”.

### Reproduction

1. User đã có routine preferences custom.
2. Làm datasource/load throw tạm thời.
3. Mở page.
4. UI dựng defaults.
5. User chỉnh nhẹ hoặc nhấn Save.
6. Defaults/custom mix có thể được persist đè lên dữ liệu thật.

### Impact

- Mất cấu hình giờ thức/ngủ/bữa ăn hiện hữu.
- Schedule timing sau đó thay đổi không chủ ý.
- Error bị che dưới dạng dữ liệu hợp lệ.

### Suggested fix direction

- Tách `loading / empty / error / ready` rõ ràng.
- Disable Save cho tới khi load thành công.
- Nếu muốn reset defaults, thêm explicit CTA và confirmation.

### Regression tests required

- Repository throws => page shows retry and Save disabled/absent.
- Empty record => defaults only trong explicit empty state.
- Retry success => original preferences restored.

---

## NB-AUD-003 — Meal replacement gây stale Schedule/Dashboard giữa các view

**Severity:** HIGH  
**Type:** CROSS_VIEW / DATA_CONSISTENCY / STATE_SYNC  
**Primary modules:** M02 Personal Schedule AI, M03 Dashboard & Schedule Execution  
**Affected views:** Meal Plan, Lifestyle Schedule, Today Tasks, Dashboard

### Summary

Meal replacement transaction cập nhật đúng `meal_plans` và linked `lifestyle_schedule_items`, đồng thời refresh reminders và sync. Tuy nhiên Riverpod mutation path chỉ refresh `MealPlanController` của chính màn Meal Plan; không invalidate các provider đã cache dữ liệu schedule/dashboard.

Kết quả: database đã chứa món mới, notification có thể đã được schedule lại bằng món mới, nhưng view Schedule/Today/Dashboard đang cache vẫn có thể hiển thị món cũ cho tới manual refresh/lifecycle/timer.

### Expected

Sau một successful meal replacement, cùng một source meal phải đồng bộ ngay trên:

```text
Meal Plan
  -> Lifestyle Schedule
  -> Today Tasks
  -> Dashboard timeline
  -> Notification
  -> Cloud sync projection
```

### Actual

- DB projection được update đúng.
- Meal Plan controller reload chính nó.
- `lifestyleScheduleControllerProvider` không được invalidate trong replacement flow.
- `dashboardDynamicProvider` không được invalidate trong replacement flow.

### Evidence

- `lib/app_versions/v1/features/meal_plan/presentation/controllers/meal_plan_controller.dart`
  - `replaceMealByCatalogCode()` gọi repository rồi `state = AsyncData(await _fetchMealPlans())`.
  - Không invalidate schedule/dashboard providers.
- `lib/app_versions/v1/features/meal_plan/domain/repositories/meal_plan_repository_impl.dart`
  - Sau datasource write: refresh reminders + sync outbox.
  - Repository không có Riverpod invalidation responsibility.
- `lib/app_versions/v1/features/meal_plan/data/datasources/meal_plan_local_datasource.dart`
  - Transaction update `meal_plans` + linked `lifestyle_schedule_items` title/description.
- `lib/app_versions/v1/features/lifestyle_schedule/providers/lifestyle_schedule_provider.dart`
  - Schedule là retained AsyncNotifier state.
- `lib/app_versions/v1/features/dashboard/providers/dashboard_dynamic_provider.dart`
  - Dashboard dynamic data được cache qua provider.
- `lib/app_versions/v1/features/dashboard/presentation/controllers/dashboard_controller.dart`
  - Project đã có pattern `_invalidateDashboardDependents()` cho các mutation khác, chứng minh cross-provider invalidation là contract hiện hữu.

### Reproduction

1. Mở Schedule/Today để provider load meal X.
2. Điều hướng sang Meal Plan.
3. Replace meal X -> Y.
4. Quay lại route trước mà không trigger full lifecycle/manual refresh.
5. Schedule/Today có thể vẫn render X trong cached state.
6. Notification đã có thể dùng Y.

### Impact

- Người dùng thấy hai món khác nhau cho cùng một nhiệm vụ.
- Có thể làm nhầm món vì notification và UI không trùng.
- Dashboard progress/timeline mang projection stale.
- Đây đúng loại bug cross-view mà audit được yêu cầu ưu tiên.

### Suggested fix direction

Tạo một mutation invalidation path duy nhất sau meal change, tối thiểu invalidate/refresh:

- meal plan;
- lifestyle schedule;
- dashboard dynamic/timeline;
- today-task projection nếu có cache riêng trong tương lai;
- nutrition/summary provider nếu dữ liệu meal được aggregate ở đó.

Không để từng page tự nhớ refresh các dependent khác.

### Regression tests required

- Cache Schedule -> replace meal -> Schedule state updated không cần lifecycle.
- Cache Dashboard -> replace meal -> timeline cập nhật ngay.
- Today Tasks dùng same new meal.
- Reminder content khớp UI sau replacement.

---

## NB-AUD-004 — “Thay món” có semantics khác nhau giữa Today Tasks và Meal Plan

**Severity:** MEDIUM  
**Type:** UX / LOGIC / DUPLICATE_ACTION  
**Primary modules:** M02/M03

### Summary

Hai nơi cùng hiển thị thao tác “Thay món”, nhưng hành vi khác nhau:

- Meal Plan: load replacement candidates và cho user chọn món cụ thể.
- Today Tasks: gọi deprecated `replaceMealById(...)`, API này tự chọn candidate đầu tiên.

### Expected

Một product action cùng tên nên dùng cùng business use case và cùng semantics, đặc biệt với meal personalization.

### Actual

Today Tasks thay món ngay theo candidate đầu tiên mà user không chọn.

### Evidence

- `lib/app_versions/v1/features/today_tasks/presentation/widgets/today_task_card.dart`
  - `_replaceMeal()` gọi deprecated `replaceMealById(sourceId)`.
- `lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart`
  - modern flow gọi `loadReplacementCandidates(...)`, mở selector rồi `replaceMealByCatalogCode(...)`.
- Deprecated repository/controller method tự chọn first candidate.

### Reproduction

1. Một meal có từ 2 replacement candidates.
2. Mở Meal Plan -> “Thay món” => user được chọn.
3. Mở Today Tasks -> “Thay món” => candidate đầu tiên được chọn tự động.

### Impact

- Hành vi không nhất quán.
- User mất quyền kiểm soát lựa chọn món ở Today Tasks.
- Candidate sorting/name changes có thể làm kết quả thay thế thay đổi mà không rõ lý do.

### Suggested fix direction

- Today Tasks reuse cùng replacement picker/use-case với Meal Plan.
- Remove deprecated auto-first path khỏi presentation.
- Một canonical meal replacement interaction cho toàn app.

### Regression tests required

- 2 candidates => Today Tasks phải yêu cầu explicit selection.
- Cancel selector => không mutation DB.
- Selected candidate phải giống ở Meal Plan và Today Tasks.

---

## NB-AUD-005 — Notification `skipped` không skip schedule item/task

**Severity:** HIGH  
**Type:** CONTRACT / STATE_SYNC / NOTIFICATION / UX  
**Primary modules:** M09 Schedule Notifications, M03 Dashboard & Schedule Execution

### Summary

M09 DD mô tả notification action có thể complete/skip đúng item và đúng subject. Runtime `NotificationActionIds.skipped` hiện chỉ cập nhật trạng thái response của row `notifications`; source schedule/task vẫn pending.

Test hiện tại còn cố ý khóa hành vi này, nghĩa là đây là drift có hệ thống giữa DD và runtime/test semantics.

### Expected theo DD

Notification skip phải tác động đến canonical item state theo subject, hoặc nếu product muốn “Để sau” thì phải có defer/snooze semantics riêng và persist thời điểm tiếp theo.

### Actual

`skipped`:

- cập nhật `notifications.action_status = skipped`;
- request sync;
- không update `lifestyle_schedule_items`;
- không update linked `meal_plans` / `daily_health_tasks`;
- không có `skipped` canonical state cho schedule item;
- không persist snooze/defer timestamp.

### Evidence

- `docs/DD/schedule_notifications/README.md`
  - module scope có action handling.
- `docs/DD/schedule_notifications/Function_List.md`
  - FN02 mô tả complete/skip item từ notification theo đúng subject.
- `docs/DD/dashboard_schedule/Function_List.md`
  - Plan Item có complete/skip semantics.
- `lib/app_versions/v1/services/notifications/notification_action_handler.dart`
  - `NotificationActionIds.skipped` chỉ thay notification row.
- `lib/app_versions/v1/services/notifications/reminder_notification_scheduler.dart`
  - button label là “Để sau”, action id lại là `skipped`.
- `lib/core/storage/localdb/tables/lifestyle_schedule_items_table.dart`
  - model hiện chủ yếu có `is_completed`, không có canonical skip/defer state tương ứng.
- `test/services/notifications/notification_action_handler_test.dart`
  - test hiện kỳ vọng skipped response không complete source schedule item.

### Reproduction

1. Có pending generated schedule item.
2. Notification hiện “Để sau”.
3. User nhấn action này.
4. Notification row ghi skipped/cancelled.
5. Mở app: schedule item vẫn pending.
6. Không có snooze state rõ ràng để biết khi nào reminder quay lại.

### Impact

- Notification history và task state không đồng bộ.
- DD/QA expectation khác runtime.
- Người dùng tưởng đã bỏ qua nhưng item vẫn chờ.
- Progress/reminder có thể hành xử bất ngờ.

### Suggested fix direction

PO/Tech cần chốt một trong hai semantics, không dùng hybrid:

**Option A — Skip thực sự**
- canonical item status `pending/completed/skipped`;
- transaction propagate linked source/progress theo business rule;
- tests/DD cùng semantics.

**Option B — Defer/Snooze**
- đổi action ID/copy khỏi `skipped`;
- persist `deferred_until`/next eligible reminder;
- source vẫn pending có chủ đích;
- DD/test cập nhật thành defer contract.

### Regression tests required

- Notification skip/defer state phải match exact business decision.
- Correct subject guard.
- App reopen vẫn thấy same persisted semantics.
- No phantom Health/Wellness point on skip.

---

## NB-AUD-006 — M01 Approved DD chưa phản ánh Daily Routine onboarding step

**Severity:** MEDIUM  
**Type:** DOCUMENTATION_DRIFT / QA_TRACEABILITY  
**Primary module:** M01 Onboarding & Health Profile

### Summary

Runtime onboarding hiện có thêm `Nhịp sống mỗi ngày` / Daily Routine Preferences với validation và persistence. M01 Approved DD vẫn là baseline cũ và chưa mô tả delta này.

### Expected

Approved DD phải trace được tất cả mandatory onboarding step có ảnh hưởng profile/persistence/schedule generation.

### Actual

Runtime đã mở rộng onboarding nhưng M01 DD chưa có corresponding implementation delta/feature mapping.

### Evidence

- `docs/DD/onboarding_profile/README.md`
  - baseline v1.0, last updated 2026-06-30.
- `lib/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart`
  - step titles hiện có `Nhịp sống mỗi ngày`;
  - có validation/persistence `DailyRoutinePreferences`.

### Impact

- QA đọc DD có thể không test step mới.
- Business validation/routine ownership bug như NB-AUD-001 dễ lọt vì không có traceability rõ.
- DD status “Approved” tạo cảm giác contract đã đầy đủ trong khi runtime đã drift.

### Suggested fix direction

Tạo M01 implementation delta mô tả:

- step order hiện tại;
- required/optional fields;
- ownership/subject rule;
- persistence target;
- impact lên generated plan schedule timing;
- error/retry behavior;
- tests và acceptance cases.

### Regression/validation required

- DD -> Function -> View -> source/test traceability cho Daily Routine step.

---

## NB-AUD-007 — Nabi M30 secondary action non-defer không persist terminal state

**Severity:** MEDIUM  
**Type:** STATE_MACHINE / INTERACTION_PERSISTENCE / M30  
**Primary module:** M30 Nabi Companion Notifications

### Summary

M30 controller xử lý primary action đúng kiểu state machine: navigation thành công -> `actioned`, thất bại -> `failed`. Defer và dismiss cũng persist state. Nhưng secondary action nếu không phải defer chỉ navigate + analytics + clear bubble, không update durable occurrence status.

### Expected

Mọi interaction terminal của occurrence phải persist consistent status/event để dedupe, analytics, replay và diagnostics dùng cùng source of truth.

### Actual

Secondary non-defer action có thể làm bubble biến mất trong UI nhưng DB occurrence vẫn ở trạng thái trước như `presented`/`opened`.

### Evidence

- `docs/DD/nabi_companion_notifications/Function_List.md`
  - FN06 yêu cầu record interaction và state-machine progression.
- `lib/features/nabi/application/notifications/nabi_notification_controller.dart`
  - primary action: update `actioned` hoặc `failed`.
  - defer: update `deferred` + next eligible.
  - dismiss: update `dismissed`.
  - secondary non-defer: navigate, track analytics, clear local active occurrence; **không update durable status**.
- `lib/features/nabi/data/notifications/nabi_notification_local_repositories.dart`
  - repository có persistence API cho status; omission nằm ở controller interaction path.

### Reproduction

1. Có Nabi occurrence có secondary action không phải defer.
2. Bubble được present/open.
3. User kích secondary action.
4. Navigation thành công.
5. UI clear occurrence.
6. Đọc local occurrence record: status có thể vẫn là state pre-action thay vì `actioned`.

### Impact

- UI state và durable state lệch nhau.
- Analytics/state machine không phản ánh action đã xảy ra.
- Dedupe/cap/replay/admin diagnostics có thể xử lý occurrence như chưa terminal.

### Suggested fix direction

Secondary non-defer cần mirror primary transition:

```text
navigate success -> actioned
navigate failure -> failed
```

Persist state trước/đồng bộ với analytics event ordering theo M30 contract.

### Regression tests required

- secondary action success => persisted `actioned`.
- secondary action failure => persisted `failed`.
- defer secondary vẫn -> `deferred` + nextEligibleAt.
- interaction event không duplicate khi double tap.

---

# 5. Cross-module consistency matrix

| Mutation / Action | Canonical write | Dependent projections | Audit result |
|---|---|---|---|
| Replace meal | `meal_plans` + linked `lifestyle_schedule_items` | Meal Plan, Schedule, Today Tasks, Dashboard, Notifications | **FAIL UI invalidation — NB-AUD-003** |
| Replace meal from Today Tasks | meal replacement repository | same as above | **Semantics mismatch — NB-AUD-004** |
| Complete schedule item | schedule transaction + linked source + health score ledger | Schedule, meals/tasks, score | Verified transaction/owner guard present |
| Manual task completion | schedule/manual task path | official health score | Verified manual tasks excluded from official score |
| Notification complete | exact source action path | schedule/task/proof rules | Core subject checks observed; no confirmed issue in inspected path |
| Notification skipped | notification row only | schedule/task/progress | **FAIL contract/state sync — NB-AUD-005** |
| Daily Routine current-user save | routine prefs row | onboarding/profile/schedule inputs | **FAIL owner resolution — NB-AUD-001** |
| Daily Routine load error | UI draft | persisted prefs if Save | **Potential overwrite — NB-AUD-002** |
| Nabi primary action | occurrence state machine | nav/analytics | Verified terminal update present |
| Nabi secondary non-defer | navigation + UI clear | occurrence DB/analytics | **FAIL terminal persistence — NB-AUD-007** |

# 6. Module audit status

`Reviewed` dưới đây nghĩa là dependency-chain/static pass trên source/DD/tests trọng yếu tại baseline commit. Nó **không** có nghĩa mọi binary/generated file đã được đọc, và không thay thế runtime/sandbox acceptance.

| Module | Status | Confirmed findings / notes |
|---|---|---|
| M01 Onboarding & Health Profile | Reviewed | NB-AUD-001, NB-AUD-002, NB-AUD-006 |
| M02 Personal Schedule AI | Reviewed | NB-AUD-003, NB-AUD-004; generated-plan persistence/request ledger looked atomic in inspected paths |
| M03 Dashboard & Schedule Execution | Reviewed | NB-AUD-003, NB-AUD-004, NB-AUD-005; completion transaction propagation present |
| M04 Basic Health Calculators | Targeted reviewed | No confirmed issue promoted in this pass |
| M05 Auth/Profile Sync/Guest Merge | Reviewed | Auth signout/preflight sync and subject guards looked consistent in inspected paths |
| M06 Membership & Quota | Reviewed | Trusted effective-access pattern observed; backend sandbox risk remains |
| M07 AI Chat | Targeted reviewed | No new evidence-backed issue promoted in this pass |
| M08 Health Score & Habits | Reviewed via schedule coupling | Manual tasks excluded from official Health Score in inspected service |
| M09 Schedule Notifications | Reviewed | NB-AUD-005 |
| M10 Advanced Tracking & Goals | Targeted reviewed | No confirmed issue promoted |
| M11 FamilyPlus | Reviewed | Effective access/RPC context checks observed; sandbox/RLS risk remains |
| M12 Sale & Direct Referral | Contract/risk reviewed | No new source-level confirmed issue; sandbox verification pending |
| M13 Payment/Membership | Reviewed | Pending request does not appear to grant trusted entitlement in inspected path |
| M14 Sale Points & Conversion | Contract/risk reviewed | No new confirmed source issue; trusted backend verification still required |
| M15 Admin Dashboard | Targeted reviewed | No new confirmed issue promoted |
| M16 Admin Operations | Targeted reviewed | No new confirmed issue promoted |
| M17 Reconciliation | Contract/risk reviewed | No new confirmed issue promoted |
| M18 Reporting | Targeted reviewed | No new confirmed issue promoted |
| M19 Audit/Security/Support | Targeted reviewed | No new confirmed issue promoted |
| M20-M29 Advanced Health | Out of bug scope except approved shell | DD not started/Draft; missing business implementation not classified as bug |
| M30 Nabi Companion Notifications | Reviewed | NB-AUD-007; integration wiring needs runtime verification |

# 7. Verified controls / paths that should be preserved

Các đoạn sau được xem là guard tốt trong static inspection và không nên bị phá khi fix:

1. **Schedule completion transaction**
   - Owner-scoped write.
   - Propagates completion sang linked meal/task.
   - Health-score ledger write nằm cùng logical completion flow.

2. **Manual task vs official Health Score**
   - Daily schedule score service loại manual tasks khỏi official Health Score theo DD delta.

3. **Meal replacement database transaction**
   - Update `meal_plans` và linked `lifestyle_schedule_items` trong transaction.
   - Refresh reminders sau replacement.
   - Outbox sync được trigger/best-effort drain.
   - Bug nằm ở provider invalidation, không phải DB projection transaction.

4. **Generated plan persistence**
   - Request ledger + generated data + guest initial-use contract được xử lý theo hướng atomic/idempotent trong inspected paths.
   - Reminder failure sau commit được coi là warning thay vì biến durable generation thành failed retry.

5. **Cloud sync orchestration**
   - User-scoped snapshot/push-before-pull/cloud-apply loop suppression hiện hữu trong inspected code.

6. **SQLite v20 migration routing**
   - `MigrationManager` chỉ chứa phần tới v17 nhưng `DatabaseService` dispatch thêm v18/v19/v20; do đó không ghi false-positive “v18-v20 không chạy”.

7. **Membership/FamilyPlus trusted gate**
   - Effective access lấy từ trusted backend/RPC in inspected providers/datasources; không thấy local flag đơn giản tự cấp quyền ở các path đã đọc.

# 8. Test gaps and validation risks

Các mục dưới đây **không được tính vào 7 confirmed bugs**, trừ khi đã nêu ở finding cụ thể.

## 8.1 Daily Routine production resolver chưa được test đúng failure mode

`test/features/daily_routine/daily_routine_preferences_test.dart` chủ yếu:

- model/default/time validation;
- repository round-trip bằng resolver inject explicit `test-user`.

Thiếu test:

- production resolver với nhiều local users;
- ambiguous guest identity;
- page load error + Save guard.

## 8.2 M30 direct notification controller coverage còn mỏng

Trong test inventory đã inspect, chưa thấy targeted tests đầy đủ cho:

- secondary non-defer success/failure state;
- terminal state persistence;
- navigation gateway integration;
- duplicate interaction/double tap.

## 8.3 M30 integration wiring cần runtime/source-index verification

Trong các entrypoint/presentation files đã inspect:

- general Nabi shell/overlay chủ yếu watch global Nabi controller;
- notification controller có default no-op navigation gateway;
- chưa đủ bằng chứng tĩnh để khẳng định mọi runtime override/wiring của M30 được kích hoạt trong unified app.

Do code-search index của connector không đáng tin cậy ở commit này và không có local checkout, mục này **chỉ được giữ là risk**, không nâng thành confirmed bug.

## 8.4 Supabase sandbox/staging vẫn là P1 open risk

Các module phụ thuộc trusted backend chưa thể coi production-ready chỉ từ Dart/SQL docs:

- membership/quota;
- FamilyPlus/RLS;
- payment;
- Sale/referral;
- Admin operations;
- reconciliation.

Cần sandbox/local Supabase acceptance với >=2 users và family scopes.

## 8.5 Không có CI evidence cho exact baseline commit

GitHub Actions lookup tại commit `7b2b90d5...` không trả về workflow run. Không thể dùng CI để xác nhận analyzer/test/build state cho exact audit baseline.

## 8.6 Không chạy được local Flutter validation trong phiên audit

Direct source clone trong sandbox bị lỗi DNS/network. Audit chuyển sang GitHub connector tại exact commit và thực hiện static source/DD/test inspection. Vì không có checkout runnable nên không claim:

- `flutter analyze` pass;
- `flutter test` pass;
- debug APK build pass;
- device/integration smoke pass.

# 9. Recommended fix order

## Priority 1 — identity/data correctness

1. **NB-AUD-001** — bỏ identity-by-recency ở Daily Routine.
2. Thêm regression tests multi-user/guest ambiguity trước các refactor khác.

## Priority 2 — canonical action semantics

3. **NB-AUD-005** — chốt “Skip” hay “Defer” và đồng bộ DD/schema/handler/tests.

## Priority 3 — cross-view consistency

4. **NB-AUD-003** — centralized provider invalidation sau meal mutation.
5. **NB-AUD-004** — hợp nhất meal replacement UI/use-case.

## Priority 4 — M30 state machine

6. **NB-AUD-007** — persist secondary terminal status + tests.

## Priority 5 — error/data-loss UX + documentation

7. **NB-AUD-002** — error state không được Save defaults.
8. **NB-AUD-006** — cập nhật M01 DD delta/traceability.

# 10. Regression matrix đề xuất

| Scenario | Unit | Repository/DAO | Controller | Widget | Integration |
|---|---:|---:|---:|---:|---:|
| Daily Routine multi-owner resolve | ✓ | ✓ |  |  | ✓ |
| Daily Routine load error cannot overwrite |  | ✓ | ✓ | ✓ |  |
| Replace meal updates all cached projections |  | ✓ | ✓ | ✓ | ✓ |
| Today Tasks replacement requires explicit candidate |  |  | ✓ | ✓ | ✓ |
| Notification skip/defer canonical semantics | ✓ | ✓ |  |  | ✓ |
| M30 secondary action terminal persistence | ✓ | ✓ | ✓ |  | ✓ |
| M01 Daily Routine DD traceability | contract |  |  |  |  |

# 11. Evidence inventory — principal files inspected

## Project/workflow/contracts

- `AGENTS.md`
- `.codex/AGENTS.md`
- `.codex/PROJECT_MAP.md`
- `.codex/history/LEARNED_SKILLS.md`
- `.codex/history/OPEN_RISKS.md`
- `.codex/workflows/find-issues.md`
- `.codex/task-skills/find-issues.md`
- `.codex/ISSUE_TODO_WORKFLOW.md`
- `docs/DD/README.md`

## DD

- `docs/DD/onboarding_profile/README.md`
- `docs/DD/personal_schedule_ai/README.md`
- `docs/DD/dashboard_schedule/README.md`
- `docs/DD/dashboard_schedule/Function_List.md`
- `docs/DD/schedule_notifications/README.md`
- `docs/DD/schedule_notifications/Function_List.md`
- `docs/DD/nabi_companion_notifications/Function_List.md`
- `docs/DD/nabi_companion_notifications/Import_File.md`

## Core / identity / DB / sync

- `lib/core/access/local_subject_resolver.dart`
- `lib/core/storage/localdb/database_service.dart`
- `lib/core/storage/localdb/migrations/migration_manager.dart`
- `lib/core/storage/localdb/migrations/migration_v20.dart`
- `lib/core/storage/localdb/sync/sync_outbox_schema.dart`
- `lib/core/storage/localdb/tables/lifestyle_schedule_items_table.dart`

## Daily Routine / Onboarding

- `lib/app_versions/v1/features/daily_routine/data/datasources/daily_routine_preferences_local_datasource.dart`
- `lib/app_versions/v1/features/daily_routine/domain/repositories/daily_routine_preferences_repository_impl.dart`
- `lib/app_versions/v1/features/daily_routine/presentation/pages/daily_routine_preferences_page.dart`
- `lib/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart`

## Meal / Schedule / Today / Dashboard

- `lib/app_versions/v1/features/meal_plan/presentation/controllers/meal_plan_controller.dart`
- `lib/app_versions/v1/features/meal_plan/domain/repositories/meal_plan_repository_impl.dart`
- `lib/app_versions/v1/features/meal_plan/data/datasources/meal_plan_local_datasource.dart`
- `lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart`
- `lib/app_versions/v1/features/lifestyle_schedule/data/datasources/lifestyle_schedule_local_datasource.dart`
- `lib/app_versions/v1/features/lifestyle_schedule/data/models/lifestyle_schedule_timeline_builder.dart`
- `lib/app_versions/v1/features/lifestyle_schedule/domain/repositories/lifestyle_schedule_repository_impl.dart`
- `lib/app_versions/v1/features/lifestyle_schedule/domain/services/daily_schedule_score_service.dart`
- `lib/app_versions/v1/features/lifestyle_schedule/presentation/controllers/lifestyle_schedule_controller.dart`
- `lib/app_versions/v1/features/lifestyle_schedule/presentation/controllers/daily_health_hub_controller.dart`
- `lib/app_versions/v1/features/lifestyle_schedule/providers/lifestyle_schedule_provider.dart`
- `lib/app_versions/v1/features/today_tasks/presentation/pages/today_tasks_page.dart`
- `lib/app_versions/v1/features/today_tasks/presentation/widgets/today_task_card.dart`
- `lib/app_versions/v1/features/today_tasks/domain/services/today_task_selector.dart`
- `lib/app_versions/v1/features/dashboard/providers/dashboard_dynamic_provider.dart`
- `lib/app_versions/v1/features/dashboard/presentation/controllers/dashboard_controller.dart`
- `lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart`

## Notification / AI

- `lib/app_versions/v1/services/notifications/notification_action_handler.dart`
- `lib/app_versions/v1/services/notifications/reminder_schedule_service.dart`
- `lib/app_versions/v1/services/notifications/reminder_notification_scheduler.dart`
- `lib/app_versions/v1/services/ai/generated_plan_service.dart`
- `lib/app_versions/v1/services/ai/generated_plan_request_store.dart`

## Auth / Cloud / Access / Family

- `lib/app_versions/v2/features/auth/presentation/controllers/auth_controller.dart`
- `lib/app_versions/v2/features/cloud_sync/data/datasources/user_data_sync_tables.dart`
- `lib/app_versions/v2/features/cloud_sync/data/datasources/sqlite_user_data_sync_local_datasource.dart`
- `lib/app_versions/v2/features/cloud_sync/data/datasources/supabase_user_data_sync_remote_datasource.dart`
- `lib/app_versions/v2/features/cloud_sync/data/repositories/authenticated_user_data_sync_repository_impl.dart`
- `lib/app_versions/v2/features/membership_entitlement/data/datasources/effective_access_remote_datasource.dart`
- `lib/app_versions/v2/features/payments/providers/membership_payment_providers.dart`
- `lib/app_versions/v3/features/familyplus/data/datasources/familyplus_remote_datasource.dart`
- `lib/app_versions/v3/features/familyplus/providers/familyplus_providers.dart`

## Nabi M30 / runtime entry

- `lib/features/nabi/application/notifications/nabi_notification_controller.dart`
- `lib/features/nabi/application/notifications/nabi_notification_engine.dart`
- `lib/features/nabi/data/notifications/nabi_notification_local_repositories.dart`
- `lib/features/nabi/presentation/widgets/nabi_app_shell.dart`
- `lib/features/nabi/presentation/widgets/nabi_assistant_overlay.dart`
- `lib/features/nabi/nabi.dart`
- `lib/main.dart`
- `lib/app/bio_ai_app.dart`
- `lib/app_versions/v2/app/bio_ai_v2_app.dart`
- `lib/app_versions/v1/router/v1_router.dart`
- `lib/app_versions/v1/router/v1_route_guards.dart`
- `lib/app_versions/v2/router/v2_router.dart`
- `lib/app_versions/v3/router/v3_router.dart`

## Tests

- `test/features/daily_routine/daily_routine_preferences_test.dart`
- `test/services/notifications/notification_action_handler_test.dart`
- Nabi application/data test directories were inventoried for direct M30 coverage.

# 12. Audit limitations

1. Đây là **static project-wide audit tại exact GitHub commit**, không phải full runtime/device acceptance.
2. Không tuyên bố đã đọc từng byte binary/generated/cache/assets. Audit tập trung meaningful source code, contracts, DD, tests và dependency chains có ảnh hưởng product behavior.
3. GitHub connector code search không có index tin cậy cho baseline; do đó nhiều file được mở trực tiếp theo tree/path thay vì dựa vào search result rỗng.
4. Clone source vào sandbox bị chặn DNS, nên không thể chạy local Flutter toolchain trong phiên này.
5. Supabase/RLS/business backend vẫn cần sandbox verification trước khi đóng production readiness.

# 13. Conclusion

Các lỗi quan trọng nhất không phải lỗi syntax mà là **identity ownership**, **cross-view invalidation**, và **action semantics/state-machine drift**:

```text
Wrong subject resolver
        |
        v
Cross-account routine data risk

Meal replacement
        |
        +--> DB updated
        +--> notification updated
        `--> cached UI not invalidated   <-- stale cross-view

Notification "skipped"
        |
        +--> notification row = skipped
        `--> schedule item = pending     <-- split truth

Nabi secondary action
        |
        +--> navigation happened
        +--> UI bubble cleared
        `--> occurrence DB not terminal <-- split state machine
```

Nên sửa theo thứ tự: **NB-AUD-001 -> NB-AUD-005 -> NB-AUD-003 -> NB-AUD-007 -> NB-AUD-002/NB-AUD-004 -> NB-AUD-006**, rồi chạy targeted regression trước khi broad analyze/build và Supabase acceptance.
