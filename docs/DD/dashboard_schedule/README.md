# DD — Dashboard & Thực hiện lịch trình

| Attribute | Value |
|---|---|
| Module Code | DASHBOARD_SCHEDULE |
| BD Module | M03 |
| Version | v1.4 |
| Status | Approved - DD docs complete |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-08-16 |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M03, 13, Appendix A UC-09 |
| Approved Addendum | docs/BD/wellness_rewards/BD_BioAI_Daily_Proof_Wellness_Rewards_v1.0.md (BD-BIOAI-WELLNESS-REWARDS-001) |

## Purpose
Hiển thị lịch trình hiện hành, cho phép đánh dấu hoàn thành/bỏ qua và theo dõi tiến độ theo đúng owner/subject.

## Documents in This Module
- [Overall](./Overall.md)
- [Feature List](./List_Features.md)
- [Function List](./Function_List.md)
- [Views](./Views.md)
- [Import and File Mapping](./Import_File.md)
- [Diagrams](./diagrams/README.md)
- [Assets](./assets/README.md)
- [Change History](./history/CHANGELOG.md)
- [Implementation Delta 2026-08-16 — Daily Health Hub](./Implementation_Delta_2026-08-16_Daily_Health_Hub.md)
- [Implementation Delta 2026-07-15 — Logbug 14-7-26](./Implementation_Delta_2026-07-15_Logbug_14-7-26.md)
- [Implementation Delta 2026-07-13](./Implementation_Delta_2026-07-13.md)

## Traceability Summary
- DASHBOARD_SCHEDULE-F01: Xem lịch trình hôm nay
- DASHBOARD_SCHEDULE-F02: Đánh dấu thực hiện lịch trình
- DASHBOARD_SCHEDULE-F03: Daily Health Hub, check-in theo loại và nhiệm vụ sức khỏe tự tạo
- Delta 2026-08-16: `Ngày của tôi`, health snapshot, quick check-in, manual tasks, non-photo completion và server-authoritative weighted rewards.
- Delta 2026-07-13: cửa sổ 30 phút, camera proof, proof gallery và Điểm chăm sóc server-authoritative.

## Dependent Modules
- PERSONAL_SCHEDULE_AI: nguồn Plan/Plan Item.
- HEALTH_SCORE_HABITS: dùng completion events; manual tasks bị loại khỏi Health Score chính thức.
- SCHEDULE_NOTIFICATIONS: reminder cho generated/manual schedule items.
- FAMILYPLUS: phân quyền subject.

## Answered Questions
| ID | Question | Decision | Status |
|---|---|---|---|
| Q-15 | How does FamilyPlus member visibility work? | FamilyPlus has up to 5 members. Every joined member in the package can view all information of every other member in the package. | Answered - User decision 2026-06-30 |
| Q-20 | How are daily health tasks completed? | Meal/exercise keep camera proof; hydration/mood/sleep/weight/quick tasks use typed check-ins. | Answered - User decision 2026-08-16 |
| Q-21 | Can users create schedule tasks? | Yes. Manual health tasks support bounded recurrence and an optional reminder. | Answered - User decision 2026-08-16 |

## Approval Status
| Role | Approver | Status | Date |
|---|---|---|---|
| BA/PO | Product Owner | Approved by DD acceptance pass | 2026-06-30 |
| Tech Lead | Tech Lead | Approved by DD acceptance pass | 2026-06-30 |
| QA Lead | QA Lead | Approved by DD acceptance pass | 2026-06-30 |
| Product delta | User instruction | Approved for implementation | 2026-08-16 |

## Validation Notes
- DD docs complete: all product questions for this delta are explicitly resolved above.
- Runtime source and focused tests are included in the same change package.
- Supabase migration must be applied and smoke-tested in a disposable sandbox before production reward rollout.
- M20–M29 advanced clinical modules remain outside this delta.
