# DD — Thông báo lịch trình

| Attribute | Value |
|---|---|
| Module Code | SCHEDULE_NOTIFICATIONS |
| BD Module | M09 |
| Version | v1.5 |
| Status | Approved - DD docs complete |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-08-17 |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M09, 13, Appendix A UC-04 |
| Approved Addendum | docs/BD/wellness_rewards/BD_BioAI_Daily_Proof_Wellness_Rewards_v1.0.md (BD-BIOAI-WELLNESS-REWARDS-001) |

## Purpose
Lên lịch nhắc theo plan/item và xử lý thao tác mở nhiệm vụ hoặc **Để sau (defer)** từ thông báo. Defer không phải hoàn thành hoặc bỏ qua task.

## Documents in This Module
- [Overall](./Overall.md)
- [Feature List](./List_Features.md)
- [Function List](./Function_List.md)
- [Views](./Views.md)
- [Import and File Mapping](./Import_File.md)
- [Diagrams](./diagrams/README.md)
- [Assets](./assets/README.md)
- [Change History](./history/CHANGELOG.md)
- [Implementation Delta 2026-08-17 — Notification Defer](./Implementation_Delta_2026-08-17_Notification_Defer.md)
- [Implementation Delta 2026-08-16 — Daily Health Hub](./Implementation_Delta_2026-08-16_Daily_Health_Hub.md)
- [Implementation Delta 2026-07-15 — Logbug 14-7-26](./Implementation_Delta_2026-07-15_Logbug_14-7-26.md)
- [Implementation Delta 2026-07-13](./Implementation_Delta_2026-07-13.md)

## Traceability Summary
- SCHEDULE_NOTIFICATIONS-F01: Lên lịch thông báo.
- SCHEDULE_NOTIFICATIONS-F02: Xử lý action từ thông báo.
- Delta 2026-08-17: “Để sau” = defer 30 phút, source vẫn pending, không cộng điểm; legacy `skipped` chỉ là compatibility input.
- Delta 2026-08-16: manual health task tái sử dụng scheduler hiện tại và hỗ trợ opt-out reminder theo item.
- Delta 2026-07-13: hành động mở nhiệm vụ không hoàn thành nền.

## Dependent Modules
- PERSONAL_SCHEDULE_AI: source plan items.
- DASHBOARD_SCHEDULE: source task state và completion flow.
- FAMILYPLUS: subject and privacy boundary.

## Answered Questions
| ID | Question | Decision | Status |
|---|---|---|---|
| Q-16 | Which timezone is authoritative? | Use Vietnam timezone, Asia/Ho_Chi_Minh. | Answered - User decision 2026-06-30 |
| Q-15 | How does FamilyPlus member visibility work? | FamilyPlus has up to 5 members. Every joined member in the package can view all information of every other member in the package. | Answered - User decision 2026-06-30 |
| Q-20 | How do manual task reminders work? | Reuse the existing deterministic schedule reminder path; each manual task can opt out without creating a second notification system. | Answered - User decision 2026-08-16 |
| Q-21 | What does “Để sau” do? | Defer the reminder by 30 minutes. Keep source pending. Do not award Health Score/Wellness Point. | Answered - User decision 2026-08-17 |

## Approval Status
| Role | Approver | Status | Date |
|---|---|---|---|
| BA/PO | Product Owner | Approved by DD acceptance pass | 2026-06-30 |
| Tech Lead | Tech Lead | Approved by DD acceptance pass | 2026-06-30 |
| QA Lead | QA Lead | Approved by DD acceptance pass | 2026-06-30 |
| Product delta | User instruction | Approved for implementation | 2026-08-17 |

## Validation Notes
- M09 canonical secondary action is defer, not source/task skip.
- Existing task completion/photo-proof rules remain unchanged.
- Real-device notification delivery and 30-minute redelivery require device smoke evidence before production release.
