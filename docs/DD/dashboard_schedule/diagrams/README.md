# diagrams/ — DASHBOARD_SCHEDULE / Dashboard & Thực hiện lịch trình

## Required Diagrams

| Diagram | Purpose | Related IDs | Status |
|---|---|---|---|
| context.mmd | Show actor, module, dependency, and data boundary. | DASHBOARD_SCHEDULE-Fxx | Planned |
| overall-flow.mmd | Summarize main flow and failure branches. | DASHBOARD_SCHEDULE-Fxx, DASHBOARD_SCHEDULE-FNxx | Planned |
| state-dashboard_schedule.mmd | Document state lifecycle from BD Appendix B where applicable. | DASHBOARD_SCHEDULE-BRxx | Planned |
| sequence-core-flow.mmd | Sequence from View/API -> Use case -> Repository -> datasource/event/audit. | DASHBOARD_SCHEDULE-FNxx | Planned |

## Notes
- Markdown flow tables in Overall/List_Features are the source until Mermaid files are added.
- Diagrams must not replace business rules or traceability tables.
- Do not include real user health data, payment evidence, secret, or production screenshot in diagrams.
