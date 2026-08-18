# DD — Onboarding & Hồ sơ sức khỏe

| Attribute | Value |
|---|---|
| Module Code | ONBOARDING_PROFILE |
| BD Module | M01 |
| Version | v1.1 |
| Status | Approved - DD docs complete |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-08-17 |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M01, 13, 16.1 AC-01, Appendix A UC-01 |

## Purpose
Thu thập dữ liệu đầu vào tối thiểu để cá nhân hóa lịch trình AI, công cụ tính toán và hồ sơ sức khỏe, bao gồm bước Nhịp sống mỗi ngày dùng cho timing của lịch được tạo mới.

## Documents in This Module
- [Overall](./Overall.md)
- [Feature List](./List_Features.md)
- [Function List](./Function_List.md)
- [Views](./Views.md)
- [Import and File Mapping](./Import_File.md)
- [Diagrams](./diagrams/README.md)
- [Assets](./assets/README.md)
- [Change History](./history/CHANGELOG.md)
- [Implementation Delta 2026-08-17 — Daily Routine Onboarding](./Implementation_Delta_2026-08-17_Daily_Routine_Onboarding.md)
- [Implementation Delta 2026-07-15 — Logbug 14-7-26](./Implementation_Delta_2026-07-15_Logbug_14-7-26.md)

## Traceability Summary
- ONBOARDING_PROFILE-F01: Thu thập dữ liệu onboarding, bao gồm Daily Routine Preferences.
- ONBOARDING_PROFILE-F02: Xác nhận hoàn tất onboarding.
- Delta 2026-08-17: Daily Routine dùng explicit/canonical subject ownership; storage recency không phải identity signal; load error không được coi là empty/default state.

## Dependent Modules
- PERSONAL_SCHEDULE_AI: dùng hồ sơ và Daily Routine để sinh lịch trình đầu tiên.
- AUTH_PROFILE_SYNC: đồng bộ Guest -> Member.
- FAMILYPLUS: subject_member_id khi onboarding cho thành viên gia đình.

## Answered Questions
| ID | Question | Decision | Status |
|---|---|---|---|
| Q-14 | Which health formulas are used? | Use reference wellness formulas only, not diagnosis: BMI by CDC, BMR/RMR by Mifflin-St Jeor, TDEE by activity factor, hydration by National Academies DRI, sleep/activity by CDC. M08 health score is versioned and separate from daily local score. | Answered - User decision 2026-06-30 |
| Q-15 | How does FamilyPlus member visibility work? | FamilyPlus has up to 5 members. Every joined member in the package can view all information of every other member in the package. | Answered - User decision 2026-06-30 |
| Q-21 | How is Daily Routine local ownership resolved? | Canonical subject resolver: authenticated/trusted subject, else durable pending guest; fail closed when unresolved; never use record recency. | Answered - implementation correction 2026-08-17 |

## Approval Status
| Role | Approver | Status | Date |
|---|---|---|---|
| BA/PO | Product Owner | Approved by DD acceptance pass | 2026-06-30 |
| Tech Lead | Tech Lead | Approved by DD acceptance pass | 2026-06-30 |
| QA Lead | QA Lead | Approved by DD acceptance pass | 2026-06-30 |
| Implementation delta | Audit fix | Aligned to runtime correction | 2026-08-17 |

## Validation Notes
- DD docs include the current Daily Routine onboarding step and ownership/error invariants.
- Runtime/device acceptance evidence remains tracked separately from documentation completeness.
