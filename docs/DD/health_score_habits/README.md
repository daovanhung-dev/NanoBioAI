# DD — Điểm sức khỏe & thói quen

| Attribute | Value |
|---|---|
| Module Code | HEALTH_SCORE_HABITS |
| BD Module | M08 |
| Version | v1.4 |
| Status | Approved - DD docs complete |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-08-16 |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M08, 9, 13, Appendix A UC-09 |
| Approved Addendum | docs/BD/wellness_rewards/BD_BioAI_Daily_Proof_Wellness_Rewards_v1.0.md (BD-BIOAI-WELLNESS-REWARDS-001) |

## Purpose
Tính điểm sức khỏe và tiến độ thói quen từ lịch sử thực hiện lịch trình, tách biệt hoàn toàn với Điểm Sale.

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
- [Implementation Delta 2026-07-13](./Implementation_Delta_2026-07-13.md)

## Traceability Summary
- HEALTH_SCORE_HABITS-F01: Tính điểm sức khỏe
- HEALTH_SCORE_HABITS-F02: Theo dõi thói quen
- Delta 2026-08-16: `manual_health_task` bị loại khỏi Health Score chính thức; formula version `daily_schedule_equal_v2_2026_08`.
- Delta 2026-07-13: Điểm sức khỏe, Điểm chăm sóc và Điểm Sale là ba hệ điểm độc lập.

## Dependent Modules
- DASHBOARD_SCHEDULE: completion events.
- FAMILYPLUS: subject boundary.
- BASIC_HEALTH_CALC: formula governance.

## Answered Questions
| ID | Question | Decision | Status |
|---|---|---|---|
| Q-14 | Which health formulas are used? | Use reference wellness formulas only, not diagnosis: BMI by CDC, BMR/RMR by Mifflin-St Jeor, TDEE by activity factor, hydration by National Academies DRI, sleep/activity by CDC. M08 health score is versioned and separate from daily local score. | Answered - User decision 2026-06-30 |
| Q-15 | How does FamilyPlus member visibility work? | FamilyPlus has up to 5 members. Every joined member in the package can view all information of every other member in the package. | Answered - User decision 2026-06-30 |
| Q-20 | Do user-authored schedule tasks affect Health Score? | No. Manual tasks are useful planning/reward items but are excluded from the official due-item score set. | Answered - User decision 2026-08-16 |

## Approval Status
| Role | Approver | Status | Date |
|---|---|---|---|
| BA/PO | Product Owner | Approved by DD acceptance pass | 2026-06-30 |
| Tech Lead | Tech Lead | Approved by DD acceptance pass | 2026-06-30 |
| QA Lead | QA Lead | Approved by DD acceptance pass | 2026-06-30 |
| Product delta | User instruction | Approved for implementation | 2026-08-16 |

## Validation Notes
- Formula eligibility-set change is versioned instead of silently reusing the old formula version.
- Supabase sandbox/RLS/API smoke remains production acceptance evidence, not a local source-code claim.
