# TASK SPECIFICATION — Liên kết toàn bộ chức năng NanoBioAI thành hệ sinh thái sức khỏe thống nhất

**Project:** NanoBioAI / NamiAI  
**Repository:** `daovanhung-dev/NanoBioAI`  
**Baseline kiểm tra:** `main` @ `60145c4b94b5c8920381201924979a2256431ab4`  
**Loại task:** Architecture + Product Flow + Cross-feature Integration + State Synchronization  
**Mức ưu tiên đề xuất:** P0/P1  
**Trạng thái:** Task specification — chưa triển khai code  
**Nguyên tắc:** Local-first, Clean Architecture, Event-driven orchestration, không phá version boundary V1/V2/V3/Admin/Sale

---

# 1. Bối cảnh

NanoBioAI hiện đã có nhiều chức năng sức khỏe riêng biệt:

- Onboarding / hồ sơ ban đầu.
- Dashboard.
- Daily Health Tracking.
- Health Check-in.
- Body Metrics.
- Water Tracking.
- Sleep Tracking / Sleep Safety.
- Stress Tracking.
- Nutrition.
- Meal Plan.
- Food Scan.
- Lifestyle Schedule.
- Today Tasks.
- Personal Goals.
- Goal Review.
- Weekly Summary.
- AI Chat.
- AI Voice.
- NaBi Care.
- Health Reminder / Notification.
- Health Score / reward-related flow.
- Membership Free / Plus / FamilyPlus.
- Các capability thuộc V1, V2, V3.

Vấn đề hiện tại không phải là thiếu feature, mà là **các feature chưa tạo thành một hệ thống có quan hệ nhân – quả rõ ràng**.

Một hành động ở module A có thể cập nhật dữ liệu thành công nhưng:

- Module B không refresh.
- Module C không biết dữ liệu mới tồn tại.
- AI vẫn dùng context cũ.
- Dashboard chưa phản ánh thay đổi.
- NaBi chưa đưa insight liên quan.
- Schedule/Meal Plan không được đánh giá lại khi sức khỏe thay đổi.
- Notification tiếp tục chạy theo kế hoạch cũ.
- Weekly Summary không ghi nhận đầy đủ hành vi.
- Feature liên quan không được gợi ý cho người dùng.
- Người dùng phải tự biết tính năng nào cần mở tiếp theo.

Kết quả là ứng dụng có nhiều chức năng nhưng trải nghiệm vẫn giống tập hợp các màn hình độc lập thay vì một **AI Health Companion** thống nhất.

---

# 2. Mục tiêu chính

Thiết kế và triển khai cơ chế để:

> **Mỗi dữ liệu sức khỏe hoặc hành động quan trọng của người dùng có thể trở thành một sự kiện có cấu trúc, được các module liên quan phản ứng đúng cách mà không tạo dependency trực tiếp giữa các màn hình.**

Luồng mục tiêu:

```text
User Action
    ↓
Feature Controller
    ↓
Repository
    ↓
Datasource / DAO / API
    ↓
Persist thành công
    ↓
Health Domain Event
    ↓
Cross-feature Orchestrator
    ↓
Health Context invalidation / rebuild
    ↓
Các projection/provider liên quan refresh
    ↓
NaBi / Dashboard / Recommendation / Reminder / Summary cập nhật
    ↓
Next Best Action được đề xuất cho người dùng
```

---

# 3. Mục tiêu sản phẩm

Sau task này, người dùng không cần tự hiểu toàn bộ danh sách feature.

Ứng dụng phải có khả năng:

1. Nhận biết người dùng vừa làm gì.
2. Nhận biết dữ liệu sức khỏe nào vừa thay đổi.
3. Xác định module nào bị ảnh hưởng.
4. Đồng bộ state liên quan.
5. Cập nhật Health Context.
6. Đánh giá xem NaBi có cần phản hồi hay không.
7. Cập nhật insight/dashboard.
8. Điều chỉnh recommendation.
9. Lập hoặc hủy reminder phù hợp.
10. Đề xuất hành động tiếp theo đúng ngữ cảnh.
11. Không spam notification.
12. Không tự ý thay đổi quyết định nhạy cảm mà không có xác nhận của người dùng.

---

# 4. Kiến trúc hiện tại phải được giữ

NanoBioAI đang sử dụng hướng kiến trúc:

```text
Presentation
    ↓
Provider / Controller
    ↓
Repository
    ↓
Datasource
    ↓
DAO / API
```

Task này **không được phá kiến trúc trên**.

## 4.1. Cấm

Không tạo các luồng kiểu:

```text
HealthCheckInPage
    ↓
MealPlanPage
    ↓
ScheduleDAO
```

hoặc:

```text
FoodScanController
    ↓
DashboardController
    ↓
SleepRepository
```

hoặc:

```text
Widget A
    ↓
SQLite trực tiếp
```

## 4.2. Yêu cầu

Cross-feature communication phải đi qua contract trung gian:

```text
Feature
    ↓
Domain Event
    ↓
Orchestrator
    ↓
Port / Repository / Provider invalidation
```

---

# 5. Source-of-truth cần tuân thủ

Khi triển khai:

1. Reachable source từ `lib/main.dart`.
2. SQLite/Supabase executable source.
3. Package/platform config.
4. Executable tests.
5. Current docs.
6. Historical docs/worklogs chỉ dùng làm bằng chứng theo snapshot.

Không được tin tài liệu cũ khi source hiện tại đã thay đổi.

Ví dụ cụ thể:

- Một số `.codex` docs vẫn mô tả SQLite version 20.
- Source hiện tại:
  `lib/core/storage/localdb/database_version.dart`
  đang là version **23**.

Do đó task này phải audit schema từ source hiện tại trước khi thêm table/event/outbox mới.

---

# 6. Phạm vi module phải rà soát

## 6.1. V1 / Basic health

Rà soát tối thiểu:

- `onboarding`
- `dashboard`
- `daily_health_tracking`
- `health_check_in`
- `body_metrics`
- `water_tracking`
- `sleep_tracking`
- `stress_tracking`
- `nutrition`
- `meal_plan`
- `lifestyle_schedule`
- `today_tasks`
- `daily_routine`
- `personal_goals`
- `goal_review`
- `weekly_summary`
- `quick_care`
- `gentle_care_mode`
- `features_hub / Nami Care`
- `profile`
- `ai_chat`
- `ai_voice`
- notification services
- generated plan services

## 6.2. Shared NaBi

Rà soát:

```text
lib/features/nabi/
```

Đặc biệt:

- care orchestration.
- care analysis.
- care repository.
- health reminder preferences.
- health reminder schedule.
- notification planner.
- feedback.
- care panel.
- global Nabi integration.

## 6.3. V2

Rà soát những phần liên quan:

- auth.
- cloud sync.
- membership.
- entitlement.
- quota.
- health/reward projection nếu đang reachable.
- user identity.

## 6.4. V3

Rà soát tối thiểu:

- Food Scan.
- Food Scan History.
- Advanced Tracking.
- FamilyPlus.

Food Scan hiện là runtime feature, không được xem như placeholder.

---

# 7. Vấn đề kiến trúc cần giải quyết

## 7.1. State fragmentation

Nhiều feature có provider/repository riêng.

Khi feature A ghi dữ liệu:

```text
A repository -> SQLite
```

feature B có thể vẫn giữ provider cache cũ.

### Giải pháp

Tạo cơ chế invalidation theo **domain impact**, không theo page.

Ví dụ:

```text
BodyMetricRecorded
  -> invalidate HealthContext
  -> invalidate DashboardProjection
  -> invalidate HealthScoreProjection
  -> invalidate NabiCareEvaluation
```

---

# 8. Giải pháp tổng thể đề xuất

Task nên triển khai theo 5 lớp mới.

```text
┌─────────────────────────────────────────────┐
│  Feature Controllers                         │
│  health / sleep / nutrition / tasks / ...   │
└───────────────────┬─────────────────────────┘
                    │ persisted successfully
                    ▼
┌─────────────────────────────────────────────┐
│  Health Domain Event Contract                │
└───────────────────┬─────────────────────────┘
                    ▼
┌─────────────────────────────────────────────┐
│  Health Event Dispatcher                     │
└───────────────────┬─────────────────────────┘
                    ▼
┌─────────────────────────────────────────────┐
│  Health Orchestrator                         │
│  impact map + handlers + debounce/coalesce   │
└──────┬────────────┬─────────────┬───────────┘
       │            │             │
       ▼            ▼             ▼
Health Context   Projection    NaBi Care
Builder          Refresh       Evaluation
       │            │             │
       └──────┬─────┴─────┬───────┘
              ▼           ▼
        Next Best Action  Reminder
              │
              ▼
         User Experience
```

---

# 9. Thành phần 1 — Health Domain Event

Tạo một contract sự kiện thuần Dart.

Đề xuất vị trí:

```text
lib/core/health_events/
├── health_domain_event.dart
├── health_event_type.dart
├── health_event_priority.dart
├── health_event_scope.dart
└── health_event_metadata.dart
```

`core` chỉ chứa contract thuần, tuyệt đối không import feature V1/V2/V3.

## 9.1. Event tối thiểu

```text
profile.created
profile.updated

health_checkin.recorded
health_checkin.updated

daily_health.recorded

body_metric.recorded
body_metric.updated

water.logged
water.goal_reached

sleep.session_completed
sleep.summary_updated
sleep.risk_detected

stress.recorded
stress.level_changed

nutrition.logged
nutrition.updated
nutrition.profile_updated

food_scan.analyzed
food_scan.confirmed_consumed

meal_plan.generated
meal_plan.updated

schedule.generated
schedule.updated

task.completed
task.skipped
task.rescheduled

goal.created
goal.updated
goal.completed

weekly_summary.generated

health_score.updated

nabi_care.analysis_updated
nabi_care.feedback_recorded

auth.signed_in
auth.signed_out

cloud_sync.completed
```

---

# 10. Event payload

Không phát event mơ hồ kiểu:

```dart
"healthChanged"
```

Mỗi event phải có metadata đủ dùng nhưng không chứa dữ liệu nhạy cảm dư thừa.

Concept:

```text
eventId
eventType
occurredAt
subjectId
sourceFeature
entityId
changedFields
severity
requiresHealthContextRefresh
requiresNabiEvaluation
requiresProjectionRefresh
```

Không đưa raw audio Sleep Safety vào event.

Không đưa ảnh Food Scan vào event.

Không đưa prompt AI hoặc transcript nhạy cảm vào event.

---

# 11. Thành phần 2 — Health Event Dispatcher

Đề xuất shared service:

```text
lib/services/health_orchestration/
├── health_event_dispatcher.dart
├── health_event_listener.dart
├── health_event_impact_registry.dart
└── health_event_deduplicator.dart
```

Dispatcher chịu trách nhiệm:

- nhận event.
- deduplicate.
- serialize những event xung đột.
- coalesce event liên tiếp.
- gọi orchestrator.
- không chứa business logic của feature.

## 11.1. Không dùng event bus global thiếu kiểm soát

Không triển khai một `StreamController<dynamic>.broadcast()` rồi để mọi nơi subscribe tùy ý.

Lý do:

- khó trace.
- khó test.
- dễ tạo loop.
- khó biết feature nào phản ứng event nào.
- dễ leak subscription.
- dễ refresh quá nhiều.

Phải có **impact registry rõ ràng**.

---

# 12. Thành phần 3 — Health Event Impact Registry

Registry định nghĩa event nào ảnh hưởng gì.

Ví dụ:

| Event | Health Context | Dashboard | NaBi | Schedule | Meal Plan | Summary | Reward |
|---|---:|---:|---:|---:|---:|---:|---:|
| `body_metric.recorded` | Yes | Yes | Yes | Maybe | Yes | Yes | No |
| `sleep.summary_updated` | Yes | Yes | Yes | Yes | Maybe | Yes | No |
| `task.completed` | Yes | Yes | Maybe | Yes | No | Yes | Yes |
| `water.logged` | Yes | Yes | Conditional | No | No | Yes | Maybe |
| `food_scan.confirmed_consumed` | Yes | Yes | Yes | No | Yes | Yes | Maybe |
| `health_checkin.recorded` | Yes | Yes | Yes | Yes | Yes | Yes | No |
| `stress.recorded` | Yes | Yes | Yes | Yes | Maybe | Yes | No |

Registry giúp:

- tránh mọi event refresh toàn app.
- biết chính xác dependency.
- viết test deterministic.
- kiểm soát hiệu năng.

---

# 13. Thành phần 4 — Unified Health Context

Đây là phần quan trọng nhất.

Hiện AI Chat, AI Voice, NaBi Care, Nutrition, Schedule và Dashboard không nên tự xây context sức khỏe theo cách riêng.

Tạo một **Health Context Snapshot** thống nhất.

Đề xuất:

```text
lib/services/health_context/
├── health_context_snapshot.dart
├── health_context_builder.dart
├── health_context_repository.dart
├── health_context_freshness.dart
└── health_context_provider.dart
```

Shared layer chỉ sử dụng abstractions/ports phù hợp; wiring feature-specific đặt ở composition/provider layer để không phá version boundaries.

---

# 14. Nội dung Health Context Snapshot

Snapshot đề xuất:

```text
identity
profile

age
sex
height
weight
BMI
body metrics trend

known conditions
allergies
medications

latest health check-in
recent symptoms
daily health state

sleep summary
sleep trend
sleep safety flags

stress level
stress trend

water intake
water goal
hydration trend

nutrition summary
macro/micro summary
recent confirmed meals
diet constraints

current meal plan

today schedule
task completion
schedule adherence

health score
health score trend

personal goals
goal progress

recent NaBi observations

recent relevant events

data freshness metadata
missing-data fields
```

---

# 15. Freshness bắt buộc

Mỗi field quan trọng cần biết:

```text
value
recordedAt
source
freshness
```

Ví dụ:

```text
weight = 72kg
recordedAt = 2026-08-25
```

khác hoàn toàn với:

```text
weight = 72kg
recordedAt = 2025-10-01
```

AI không được coi hai dữ liệu này có độ tin cậy như nhau.

---

# 16. Health Context không phải một bảng duplicate

Không tạo một table chứa bản copy toàn bộ user health state rồi ép mọi feature ghi vào đó.

Health Context nên là **read model / snapshot được compose từ source-of-truth hiện có**.

Có thể cache snapshot có TTL nếu cần tối ưu.

Source data vẫn nằm trong repositories/tables của từng domain.

---

# 17. Thành phần 5 — Health Orchestrator

Đề xuất:

```text
lib/services/health_orchestration/
├── health_orchestrator.dart
├── health_orchestration_result.dart
├── health_action_type.dart
├── health_action_candidate.dart
└── handlers/
```

Orchestrator nhận event và quyết định:

```text
cần refresh context?
cần refresh dashboard?
cần đánh giá NaBi?
cần recalculate health score?
cần update summary?
cần schedule reminder?
cần đề xuất next action?
```

Orchestrator **không được tự điều hướng UI**.

---

# 18. Chặn orchestration loop

Ví dụ nguy hiểm:

```text
HealthContextUpdated
 -> NabiEvaluated
 -> HealthContextUpdated
 -> NabiEvaluated
 -> ...
```

Phải có:

- event ID.
- causation ID.
- correlation ID.
- source.
- dedupe window.
- maximum orchestration depth nếu cần.
- rule không emit event nếu output thực tế không đổi.

---

# 19. Riverpod invalidation strategy

Không gọi:

```text
ref.invalidate(...)
```

rải rác ở hàng chục feature.

Tạo abstraction kiểu:

```text
HealthProjectionInvalidator
```

và map impact:

```text
Dashboard
HealthContext
HealthScore
WeeklySummary
NabiCare
NextBestAction
```

Wiring Riverpod nằm ở presentation/application composition phù hợp.

---

# 20. NaBi trở thành intelligence orchestration surface

NaBi không chỉ là mascot hoặc chat surface.

NaBi phải là lớp diễn giải các thay đổi sức khỏe thành lời nhắc/gợi ý hữu ích.

Luồng:

```text
Health Event
    ↓
Health Context
    ↓
Deterministic rules
    ↓
Có cần AI không?
    ↓
NaBi Care evaluation
    ↓
Safety filter
    ↓
Care recommendation
    ↓
Next Best Action
```

AI **không phải bước bắt buộc cho mọi event**.

---

# 21. Deterministic-first, AI-second

Ví dụ:

```text
water.logged
```

không cần gọi Gemini mỗi lần.

Rule engine có thể xử lý:

```text
water < 30% goal vào 15:00
=> candidate hydration reminder
```

Chỉ gọi AI khi:

- cần diễn giải nhiều nguồn dữ liệu.
- cần personalized care summary.
- cần conversational response.
- cần generate recommendation phức tạp.

---

# 22. Next Best Action Engine

Đây là cơ chế giúp người dùng khám phá feature đúng lúc.

Đề xuất:

```text
lib/features/nabi/application/next_best_action/
├── next_best_action.dart
├── next_best_action_engine.dart
├── next_best_action_policy.dart
└── next_best_action_ranker.dart
```

Hoặc vị trí tương đương phù hợp source hiện tại sau audit.

Một candidate gồm:

```text
id
type
title
message
destination
priority
reason
expiresAt
cooldown
requiredAccess
```

---

# 23. Ranking Next Best Action

Score gợi ý:

```text
score =
    health_relevance
  + urgency
  + freshness
  + personalization
  + feature_discovery_value
  - repetition_penalty
  - notification_fatigue
```

Chỉ hiển thị top 1–3 candidate.

Không biến Dashboard thành danh sách 20 lời nhắc.

---

# 24. Notification Fatigue Policy

Bắt buộc có policy.

Ví dụ:

- Không nhắc cùng một việc quá N lần/ngày.
- Không tạo notification mới nếu người dùng vừa dismiss tương tự.
- Không dùng push/local notification cho mọi insight.
- Insight nhẹ chỉ hiển thị trong Dashboard/Nabi Care.
- Notification dành cho:
  - hành động có thời gian.
  - nguy cơ cần chú ý phù hợp policy.
  - reminder user đã opt-in.
  - kế hoạch đã được người dùng chấp nhận.

---

# 25. Luồng tích hợp cụ thể 01 — Health Check-in

```text
User completes Health Check-in
        ↓
HealthCheckInRepository persist
        ↓
health_checkin.recorded
        ↓
HealthContext invalidated
        ↓
Dashboard refresh
        ↓
NaBi Care evaluate
        ↓
Health impact rules
        ↓
Next Best Action
```

Nếu người dùng báo:

```text
mệt hơn + ngủ kém
```

hệ thống có thể đề xuất:

- xem Sleep Summary.
- giảm cường độ schedule.
- theo dõi thêm triệu chứng.
- hỏi NaBi.
- cập nhật mục tiêu ngắn hạn.

Không được tự sửa toàn bộ schedule nếu chưa có consent.

---

# 26. Luồng 02 — Sleep

```text
Sleep session completed
        ↓
sleep.session_completed
        ↓
sleep summary calculated
        ↓
sleep.summary_updated
        ↓
Health Context
        ↓
Dashboard + Weekly Summary
        ↓
NaBi evaluates trend
        ↓
Schedule adjustment candidate
```

Nếu ngủ kém:

```text
NaBi:
"Đêm qua giấc ngủ của bạn chưa tốt lắm.
Hôm nay mình giảm nhẹ cường độ vận động nhé?"
```

CTA:

```text
[Xem đề xuất]
[Giữ lịch hiện tại]
```

Không tự thay lịch âm thầm.

---

# 27. Luồng 03 — Stress

```text
Stress recorded
     ↓
stress.recorded
     ↓
Health Context
     ↓
Health Score projection
     ↓
NaBi
     ↓
Next Best Action
```

Candidate:

- breathing / gentle-care flow.
- sleep preparation.
- giảm task intensity.
- AI Chat nếu người dùng muốn trao đổi.

---

# 28. Luồng 04 — Body Metrics

```text
Weight/body metric updated
       ↓
body_metric.recorded
       ↓
recalculate metrics
       ↓
Health Context
       ↓
Dashboard
       ↓
Nutrition context
       ↓
Goal progress
       ↓
Weekly Summary
```

Nếu cân nặng thay đổi đáng kể:

- không đưa chẩn đoán.
- hiển thị trend.
- đề xuất kiểm tra mục tiêu.
- cho phép update Nutrition Profile.

---

# 29. Luồng 05 — Water

```text
water.logged
    ↓
daily hydration projection
    ↓
Dashboard refresh
    ↓
Weekly Summary
    ↓
conditional reminder policy
```

Không gọi AI mỗi lần uống nước.

---

# 30. Luồng 06 — Food Scan

Food Scan đã là V3 runtime feature.

Luồng:

```text
Image selected
    ↓
Food Scan analysis
    ↓
User confirms food consumed
    ↓
food_scan.confirmed_consumed
    ↓
Nutrition log
    ↓
Health Context
    ↓
Dashboard / Nutrition
    ↓
NaBi Care if relevant
    ↓
Meal plan recommendation candidate
```

Chỉ event **confirmed consumed** mới nên ảnh hưởng nutrition chính thức.

`food_scan.analyzed` không được coi là người dùng đã ăn.

---

# 31. Food Scan privacy

Giữ nguyên nguyên tắc:

- ảnh scan local.
- rich AI result local nếu thiết kế hiện tại như vậy.
- không sync raw image mặc định.
- event chỉ chứa IDs/summary metadata tối thiểu.

---

# 32. Luồng 07 — Task completion

```text
User opens task
    ↓
required check-in/photo flow
    ↓
task completion transaction succeeds
    ↓
task.completed
    ↓
schedule adherence
    ↓
health score
    ↓
reward projection
    ↓
weekly summary
    ↓
dashboard
```

Notification **không được tự hoàn thành task**.

Notification chỉ đưa người dùng vào đúng flow.

---

# 33. Luồng 08 — Meal Plan

```text
Meal plan generated/changed
        ↓
meal_plan.updated
        ↓
Nutrition projection
        ↓
Schedule/today context
        ↓
Notification schedule
        ↓
Dashboard
```

Nếu người dùng đổi meal:

- Today view phải phản ánh.
- reminder cũ phải cancel/update.
- AI context phải dùng meal mới.

---

# 34. Luồng 09 — Personal Goal

```text
goal.updated
    ↓
Health Context
    ↓
Dashboard
    ↓
Schedule recommendation
    ↓
Meal/nutrition recommendation
    ↓
Next Best Action
```

Khi hoàn thành:

```text
goal.completed
    ↓
goal review
    ↓
weekly summary
    ↓
new-goal candidate
```

---

# 35. Luồng 10 — AI Chat / AI Voice

AI Chat và AI Voice phải sử dụng cùng một Health Context contract.

Không để:

```text
AI Chat build context A
AI Voice build context B
NaBi Care build context C
```

Mục tiêu:

```text
UnifiedHealthContext
       ├── AI Chat
       ├── AI Voice
       ├── NaBi Care
       └── recommendation generation
```

Có thể khác nhau ở **view** của snapshot:

```text
ChatContextView
VoiceContextView
CareContextView
```

nhưng source snapshot thống nhất.

---

# 36. Context minimization cho AI

Không gửi toàn bộ database lên Gemini.

Tạo AI context mapper:

```text
HealthContextSnapshot
        ↓
AIContextPolicy
        ↓
RelevantHealthContext
        ↓
Prompt
```

Chỉ gửi field cần thiết cho request.

Ví dụ hỏi uống nước:

- hydration.
- age nếu cần.
- relevant conditions.
- recent activity.

Không cần gửi toàn bộ lịch sử Food Scan.

---

# 37. Dashboard trở thành projection, không phải source

Dashboard phải chỉ hiển thị state đã được aggregate.

Không để Dashboard:

- tự ghi health data.
- tự sửa schedule.
- tự tính business rule độc lập với domain service.

Dashboard nên đọc:

```text
DashboardProjection
```

gồm:

- today status.
- health score.
- sleep.
- hydration.
- nutrition.
- schedule progress.
- current NaBi insight.
- next best action.

---

# 38. Weekly Summary

Weekly Summary phải trở thành consumer của các event/projection quan trọng.

Đảm bảo phản ánh:

- task completion.
- hydration.
- nutrition.
- sleep.
- stress.
- body metrics.
- goal progress.
- health check-ins.

Không nhất thiết lưu toàn bộ event history nếu source tables hiện có đủ để aggregate.

---

# 39. Persistence strategy cho event

Giai đoạn đầu nên ưu tiên **in-process event + durable source data**.

Không nhất thiết tạo Event Sourcing đầy đủ.

## Phase 1

```text
Repository persist
  -> event dispatcher in memory
```

Nếu app restart:

- source-of-truth vẫn còn.
- projections có thể rebuild.

## Phase 2 nếu cần reliability

Có thể thêm local integration outbox:

```text
health_event_outbox
```

chỉ khi audit chứng minh cần durable retry.

Không thêm table chỉ vì “event-driven nghe hay”.

---

# 40. Cloud sync

Không sync tất cả event lên Supabase.

Cloud sync vẫn theo domain data hiện có.

Event local dùng để orchestration trong app.

Chỉ thêm cloud contract khi:

- có multi-device requirement.
- backend cần xử lý event.
- FamilyPlus cần cross-account event.
- analytics/product requirement đã được phê duyệt.

Nếu Supabase schema thay đổi:

- cập nhật `docs/supabase/01_build_system.sql`.
- seed thay đổi thì cập nhật `02_seed_data.sql`.
- chạy sandbox verification trước khi claim production-ready.

---

# 41. Guest / Free / Plus / FamilyPlus

## Guest

Phải hoạt động local-first:

- onboarding.
- basic health.
- initial schedule.
- reminder cơ bản.
- dashboard basic.
- health context local.

## Free authenticated

Bổ sung:

- cloud sync.
- quota-aware AI.
- authenticated capabilities.

## Plus

Next Best Action có thể đưa CTA tới paid feature nhưng:

- không được giả trạng thái membership.
- access phải đọc từ trusted entitlement.

## FamilyPlus

Cross-member health data phải tuân privacy/access contract.

Không dùng local event của user A để tác động profile user B nếu chưa có backend authorization hợp lệ.

---

# 42. Auth transition

Khi Guest → Member:

```text
auth.signed_in
    ↓
identity resolved
    ↓
cloud sync
    ↓
Health Context rebuild
    ↓
projection refresh
```

Không để cached guest snapshot trở thành member snapshot.

Khi sign out:

- flush/reconcile local sync theo policy hiện tại.
- clear identity-bound caches.
- rebuild guest state phù hợp.

---

# 43. Subject isolation

Mọi event có dữ liệu cá nhân phải gắn:

```text
subjectId
```

Nếu current active subject khác event subject:

```text
ignore / quarantine
```

Điều này đặc biệt quan trọng:

- account switch.
- FamilyPlus.
- delayed notification.
- async AI response.
- sync completion.

---

# 44. Async stale response protection

Ví dụ:

```text
User records health check-in A
AI request starts
User updates health check-in B
AI A returns later
```

Không được để response A overwrite insight của B.

Phải có:

```text
contextVersion
requestId
sourceEventId
```

Trước commit AI result:

```text
if currentContextVersion != requestContextVersion:
    discard or reevaluate
```

---

# 45. Event priority

Đề xuất:

```text
LOW
NORMAL
HIGH
SAFETY
```

Ví dụ:

- water logged → LOW.
- task completed → NORMAL.
- significant health change → HIGH.
- Sleep Safety trigger → SAFETY.

SAFETY không đồng nghĩa “AI chẩn đoán”.

Safety flow phải đi qua policy riêng.

---

# 46. Debounce / coalesce

Ví dụ người dùng cập nhật:

```text
weight
waist
body fat
```

trong 30 giây.

Không cần 3 lần NaBi AI evaluation.

Có thể coalesce thành:

```text
body_metrics.batch_updated
```

hoặc debounce evaluation.

---

# 47. Performance budget

Task phải tránh:

- rebuild toàn app.
- query toàn DB sau mọi event.
- gọi AI sau mọi event.
- reschedule toàn notification set mỗi lần.
- reload weekly summary không cần thiết.

Impact registry phải giúp update đúng projection.

---

# 48. Feature Discovery

Ngoài NaBi Care, cần có CTA đúng ngữ cảnh.

Ví dụ:

## Sau Body Metrics

```text
Bạn vừa cập nhật cân nặng.
[Xem xu hướng]
[Cập nhật mục tiêu]
```

## Sau Sleep

```text
Đêm qua bạn ngủ ít hơn thường lệ.
[Xem giấc ngủ]
[Điều chỉnh lịch hôm nay]
```

## Sau Food Scan

```text
Mình đã cập nhật bữa ăn vào nhật ký.
[Xem dinh dưỡng hôm nay]
```

## Cuối tuần

```text
Tuần này đã đủ dữ liệu để tổng kết.
[Xem tuần của bạn]
```

---

# 49. UX rule

Không tự động navigate khi event xảy ra.

Chỉ:

- update data.
- update insight.
- hiện contextual CTA.
- local notification nếu policy cho phép.

Navigation chỉ xảy ra sau user intent.

---

# 50. Proposed file ownership

Đây là **target architecture**, agent phải đối chiếu source trước khi tạo file.

## Pure contracts

```text
lib/core/health_events/
```

## Shared orchestration

```text
lib/services/health_orchestration/
```

## Unified health context

```text
lib/services/health_context/
```

## NaBi next actions

Ưu tiên nằm trong:

```text
lib/features/nabi/
```

## Feature adapters

Nằm bên trong từng feature/application/provider layer, không để shared service import presentation.

---

# 51. Không phá version boundary

Shared layer:

```text
core/
services/
```

không được import:

```text
app_versions/v1/presentation
app_versions/v2/presentation
app_versions/v3/presentation
```

Feature wiring có thể phụ thuộc shared contracts.

V3 Food Scan không được gọi controller/page của V1 Nutrition.

Thay vào đó:

```text
V3 Food Scan
    ↓
HealthDomainEvent
    ↓
Shared Orchestrator
    ↓
Nutrition projection adapter
```

---

# 52. Các file cần audit trước khi coding

Bắt buộc đọc tối thiểu:

```text
AGENTS.md
.codex/AGENTS.md
.codex/PROJECT_MAP.md
.codex/workflows/coding.md
.codex/task-skills/README.md
.codex/domains/README.md
```

Sau đó đọc đúng domain.

## Router

```text
lib/app_versions/v1/router/v1_router.dart
lib/app_versions/v1/router/v1_route_guards.dart
lib/app_versions/v2/router/v2_router.dart
lib/app_versions/v3/router/v3_router.dart
```

## SQLite

```text
lib/core/storage/localdb/database_service.dart
lib/core/storage/localdb/database_version.dart
lib/core/storage/localdb/migrations/
```

## AI

```text
lib/app_versions/v1/services/ai/ai_chat_service.dart
lib/app_versions/v1/services/ai/generated_plan_service.dart
lib/app_versions/v1/services/ai/gemini_rest_client.dart
```

## Notification

```text
lib/app_versions/v1/services/notifications/notification_bootstrap.dart
lib/app_versions/v1/services/notifications/notification_action_handler.dart
```

## NaBi

```text
lib/features/nabi/
```

## Food Scan

```text
lib/app_versions/v3/features/food_scan/
```

## Core health feature repositories/providers

Audit theo từng flow, không chỉ đọc presentation page.

---

# 53. Audit deliverable trước implementation

Agent phải tạo **Integration Matrix**.

Format:

| Source Feature | User Action | Persisted Data | Event | Consumers hiện tại | Consumers còn thiếu | Priority |
|---|---|---|---|---|---|---|

Phải có ít nhất toàn bộ reachable health features.

---

# 54. Data Ownership Matrix

Tạo bảng:

| Data | Owner Repository | Local/Cloud | Readers | Writers | Freshness |
|---|---|---|---|---|---|

Ví dụ:

```text
body metrics
sleep summary
water logs
nutrition logs
meal plan
schedule
task completion
health check-in
goals
NaBi analysis
```

Mục tiêu là loại bỏ trường hợp cùng một concept được ghi bởi nhiều feature không có source-of-truth rõ ràng.

---

# 55. Event Impact Matrix

Tạo bảng:

| Event | Context | Dashboard | NaBi | AI | Schedule | Nutrition | Summary | Reward | Notification |
|---|---|---|---|---|---|---|---|---|---|

Đây phải là artifact dùng để coding và viết test.

---

# 56. Ưu tiên triển khai

## P0 — Data consistency

Phải làm trước:

1. Task completion ↔ Schedule ↔ Dashboard.
2. Meal Plan ↔ Today context ↔ Notification.
3. Health Check-in ↔ Health Context.
4. Body Metrics ↔ Health Context ↔ Dashboard.
5. Food Scan confirmed ↔ Nutrition.
6. Auth/account switching cache isolation.
7. Provider invalidation đúng sau writes.

## P1 — Health intelligence

1. Unified Health Context.
2. NaBi Care automatic evaluation theo meaningful event.
3. Health Score refresh.
4. Weekly Summary aggregation.
5. Schedule adjustment candidates.
6. Nutrition recommendation candidates.

## P2 — Feature discovery

1. Next Best Action.
2. Contextual CTA.
3. Smart reminder.
4. Notification fatigue policy.

## P3 — Advanced

1. Durable local integration outbox nếu thực sự cần.
2. Cross-device orchestration.
3. FamilyPlus cross-member authorized insights.
4. Long-term trend/risk engine.

---

# 57. Phase thực hiện chi tiết

## Phase 0 — Baseline

- Chốt commit HEAD.
- Đọc AGENTS.
- Đọc project map.
- Đọc coding workflow.
- Chọn domain.
- Chạy targeted baseline tests.
- Ghi lại pre-existing failures.
- Không sửa code ở bước này.

---

# 58. Phase 1 — Inventory

Đối với mỗi feature:

1. Xác định route reachable.
2. Xác định Controller/Notifier.
3. Xác định Repository.
4. Xác định Datasource.
5. Xác định DAO/table.
6. Xác định cloud sync.
7. Xác định provider cache.
8. Xác định notification.
9. Xác định AI dependency.
10. Xác định downstream consumer.

Output:

```text
Feature Integration Inventory
```

---

# 59. Phase 2 — Xác định broken links

Tìm các pattern:

```text
write succeeds
but provider not invalidated
```

```text
data saved locally
but summary uses stale cache
```

```text
AI prompt builds independent context
```

```text
notification still references old schedule
```

```text
same concept stored in two places
```

```text
feature has route but no contextual entry point
```

---

# 60. Phase 3 — Event contracts

Tạo:

- event enum/type.
- base event.
- metadata.
- correlation.
- priority.
- event impact registry.

Viết unit test trước cho:

- equality.
- dedupe.
- impact resolution.
- unsupported event behavior.

---

# 61. Phase 4 — Unified Health Context

Implement builder theo repository abstractions.

Yêu cầu:

- deterministic.
- testable.
- user/subject scoped.
- freshness aware.
- partial data tolerant.
- không crash vì một module thiếu dữ liệu.

Nếu Sleep unavailable:

```text
sleep = missing
```

không làm toàn snapshot fail.

---

# 62. Phase 5 — Feature event emission

Migrate lần lượt, không big-bang.

Thứ tự:

1. Health Check-in.
2. Body Metrics.
3. Water.
4. Sleep.
5. Stress.
6. Task Completion.
7. Meal Plan.
8. Nutrition.
9. Food Scan.
10. Goals.

Event chỉ emit **sau transaction/persist thành công**.

---

# 63. Phase 6 — Projection invalidation

Implement targeted invalidation.

Test:

```text
water.logged
```

không được invalidate Food Scan History nếu không có dependency.

---

# 64. Phase 7 — NaBi integration

Kết nối event có relevance cao tới NaBi Care.

Không gọi AI với:

- mọi water log.
- mọi screen open.
- mọi provider refresh.

Dùng:

- impact registry.
- debounce.
- cooldown.
- deterministic pre-filter.

---

# 65. Phase 8 — Next Best Action

Tạo candidate engine.

Nguồn candidate:

- missing data.
- abnormal trend theo deterministic policy.
- stale profile.
- incomplete goal.
- sleep/stress.
- nutrition.
- hydration.
- task progress.
- weekly summary availability.

Rank và chỉ trả top candidate.

---

# 66. Phase 9 — Notification integration

Notification planner nhận accepted/candidate reminder.

Phân biệt:

```text
Insight
CTA
In-app reminder
Local notification
Safety notification
```

Không đồng nhất tất cả thành notification.

---

# 67. Phase 10 — AI integration

AI Chat / Voice / NaBi sử dụng Health Context mapper.

Test prompt context không chứa:

- raw sleep audio.
- raw Food Scan image.
- unrelated sensitive history.
- internal DB terms.

---

# 68. Phase 11 — End-to-end flow tests

Bắt buộc có integration tests cho ít nhất:

### Flow A

```text
Health Check-in
→ context
→ NaBi candidate
→ dashboard refresh
```

### Flow B

```text
Task completion
→ schedule progress
→ health score
→ reward
→ weekly summary
```

### Flow C

```text
Food Scan confirm
→ nutrition
→ health context
→ dashboard
```

### Flow D

```text
Sleep summary
→ NaBi
→ schedule adjustment candidate
```

### Flow E

```text
Account switch
→ stale event from old account rejected
```

---

# 69. Test strategy

## Unit

- event contracts.
- event impact registry.
- context builder.
- freshness.
- next action ranking.
- debounce.
- subject isolation.
- AI context mapper.

## Repository

- write then emit.
- no event on failed write.
- transaction consistency.

## Provider

- correct projection invalidated.
- unrelated provider untouched.

## Integration

- full flow across multiple modules.

## Architecture

Phải chạy:

```text
test/architecture_version_boundary_test.dart
test/architecture_preservation_property_test.dart
```

---

# 70. Regression rules

Không được regression:

- guest onboarding.
- initial plan generation once.
- task photo/check-in completion flow.
- notification tap behavior.
- auth identity resolution.
- sign-out.
- cloud sync.
- Food Scan privacy.
- Sleep Safety.
- membership gates.
- quota.
- FamilyPlus boundary.
- Admin/Sale separation.

---

# 71. Acceptance Criteria — P0

Task chưa được coi là hoàn thành nếu:

- write tại feature A vẫn yêu cầu user restart page để feature B thấy data.
- task completed nhưng Dashboard/Health Score không phản ánh.
- Food Scan confirm nhưng Nutrition không thấy.
- Sleep update nhưng Health Context vẫn stale.
- Health Check-in mới nhưng NaBi vẫn dùng dữ liệu cũ.
- account A event có thể tác động account B.
- notification cũ không được reconcile sau schedule change.

---

# 72. Acceptance Criteria — Architecture

- Presentation không import DAO.
- Shared orchestration không import presentation.
- Core event contract không import app_versions.
- V3 không gọi V1 presentation/controller.
- Không dùng global dynamic event bus.
- Mọi event có typed contract.
- Event có source và subject.
- Không emit trước persist.
- Không loop orchestration.
- Không AI-call storm.

---

# 73. Acceptance Criteria — UX

Người dùng phải cảm nhận được các feature có liên quan.

Ví dụ:

```text
sleep kém
→ dashboard phản ánh
→ NaBi giải thích
→ có CTA phù hợp
→ schedule adjustment chỉ sau consent
```

không phải:

```text
sleep kém
→ phải tự nhớ mở 4 màn hình khác nhau
```

---

# 74. Acceptance Criteria — AI Safety

- Không chẩn đoán.
- Không tuyên bố chắc chắn bệnh lý.
- Không tự thay đổi medication.
- Không tự thay đổi kế hoạch quan trọng khi chưa có consent.
- Safety content phải qua policy hiện tại.
- Khi dữ liệu thiếu, AI phải biết dữ liệu thiếu.

---

# 75. Logging / observability

Không log dữ liệu sức khỏe đầy đủ.

Log kỹ thuật có thể gồm:

```text
eventType
eventId
source
handler
duration
result
```

Không log:

- raw health detail không cần thiết.
- prompt chứa PII.
- raw Food Scan image.
- raw sleep audio.
- token/key.

---

# 76. Metrics để đánh giá sau triển khai

Kỹ thuật:

- số stale projection bug.
- event handling latency.
- context build latency.
- AI call/event ratio.
- duplicated event ratio.
- notification generated/day.

Sản phẩm:

- feature discovery conversion.
- next-action click rate.
- weekly summary usage.
- completion rate.
- retention của health tracking.
- tỷ lệ dismiss notification.

Không cần thêm analytics mới nếu project chưa có privacy-approved pipeline; đây là measurement plan.

---

# 77. Rủi ro chính

## R1 — Overengineering

Không biến app thành Kafka/Event Sourcing.

Giải pháp:

- typed in-process dispatcher trước.
- durable outbox chỉ khi có requirement.

## R2 — Event loop

Giải pháp:

- causation ID.
- dedupe.
- idempotent handlers.

## R3 — AI cost/latency

Giải pháp:

- deterministic-first.
- debounce.
- AI only for meaningful event.

## R4 — stale async result

Giải pháp:

- context version.
- request ID.

## R5 — cross-version import

Giải pháp:

- shared contracts + adapters.

## R6 — privacy

Giải pháp:

- minimal payload.
- local-first.
- context minimization.

---

# 78. Definition of Done

Chỉ hoàn thành khi:

1. Integration inventory hoàn tất.
2. Data ownership rõ ràng.
3. Event taxonomy rõ ràng.
4. Unified Health Context hoạt động.
5. P0 feature flows liên kết.
6. Projection refresh deterministic.
7. NaBi phản ứng với meaningful events.
8. Next Best Action hoạt động tối thiểu.
9. Notification không spam.
10. AI dùng context chung.
11. Subject/account isolation có test.
12. Architecture tests pass.
13. Targeted tests pass.
14. Analyzer touched paths pass.
15. Không claim full-suite green nếu repo-wide test vẫn có pre-existing failures.
16. Worklog ghi rõ verified / implemented / planned.
17. Nếu có Supabase changes, canonical SQL được cập nhật và sandbox verification có bằng chứng.

---

# 79. Yêu cầu đối với coding agent

Trước khi sửa code, agent phải trả lời được:

- Data owner của từng concept là gì?
- Feature nào emit event?
- Event nào ảnh hưởng module nào?
- Có thực sự cần schema mới không?
- Có thể rebuild projection từ source hiện tại không?
- Event có cần persist không?
- AI có thực sự cần được gọi không?
- Feature có hoạt động cho Guest không?
- Access gate ở đâu?
- Có phá V1/V2/V3 boundary không?
- Có nguy cơ account A tác động account B không?
- Có nguy cơ stale AI response không?
- Notification có cần cancel/reschedule không?

Nếu chưa trả lời được, chưa được triển khai.

---

# 80. Kết quả sản phẩm mong muốn

NanoBioAI phải chuyển từ:

```text
Nhiều feature độc lập
```

thành:

```text
Một hệ sinh thái chăm sóc sức khỏe thống nhất
```

Trong đó:

```text
Health data
    ↓
Shared Health Context
    ↓
Deterministic intelligence
    ↓
NaBi intelligence
    ↓
Recommendation
    ↓
Next Best Action
    ↓
Relevant feature
    ↓
New health data
```

Tạo thành vòng lặp:

```text
Observe
→ Understand
→ Recommend
→ Act
→ Measure
→ Adapt
```

---

# 81. Nguyên tắc trải nghiệm cuối cùng

> Người dùng không cần biết NanoBioAI có bao nhiêu module.

> NanoBioAI phải biết **khi nào module nào có ích cho người dùng**, và đưa đúng hành động đến đúng thời điểm.

Ví dụ trải nghiệm cuối:

```text
Người dùng ngủ kém
↓
NanoBio tự hiểu dữ liệu
↓
Dashboard thay đổi
↓
NaBi nhẹ nhàng hỏi thăm
↓
Đề xuất giảm cường độ lịch hôm nay
↓
Người dùng đồng ý
↓
Schedule cập nhật
↓
Reminder được reconcile
↓
Weekly Summary ghi nhận
↓
Ngày hôm sau hệ thống đánh giá lại
```

Đây mới là mục tiêu của việc **“liên kết các chức năng”** trong NanoBioAI.

---

# 82. Lệnh task ngắn gọn cho agent

> Đọc source hiện tại của NanoBioAI và thực hiện audit toàn bộ cross-feature data flow. Xác định mọi feature reachable, owner của dữ liệu, repository/provider, downstream consumers và các điểm đang bị tách rời. Sau đó thiết kế cơ chế typed Health Domain Event + Health Event Impact Registry + Unified Health Context + Cross-feature Health Orchestrator + targeted Riverpod invalidation + NaBi Next Best Action để các chức năng sức khỏe liên kết với nhau mà không tạo direct dependency giữa page/controller của các feature. Ưu tiên P0 data consistency trước P1 intelligence, sau đó mới P2 feature discovery. Giữ local-first, Guest flow, Clean Architecture, V1/V2/V3 boundaries, Food Scan privacy, Sleep Safety, trusted membership/quota backend và notification completion flow hiện tại. Không coding trước khi integration matrix, data ownership matrix, event impact matrix và plan triển khai được hoàn tất và xác nhận.
