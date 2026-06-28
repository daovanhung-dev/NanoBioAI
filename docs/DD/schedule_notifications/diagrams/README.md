# diagrams/ — SCHEDULE_NOTIFICATIONS / Thông báo lịch trình

## Required Diagrams

| Diagram | Purpose | Related IDs | Status |
|---|---|---|---|
| context.mmd | Show actor, module, dependency, and data boundary. | SCHEDULE_NOTIFICATIONS-Fxx | Planned |
| overall-flow.mmd | Summarize main flow and failure branches. | SCHEDULE_NOTIFICATIONS-Fxx, SCHEDULE_NOTIFICATIONS-FNxx | Planned |
| state-schedule_notifications.mmd | Document state lifecycle from BD Appendix B where applicable. | SCHEDULE_NOTIFICATIONS-BRxx | Planned |
| sequence-core-flow.mmd | Sequence from View/API -> Use case -> Repository -> datasource/event/audit. | SCHEDULE_NOTIFICATIONS-FNxx | Planned |

## Notes
- Markdown flow tables in Overall/List_Features are the source until Mermaid files are added.
- Diagrams must not replace business rules or traceability tables.
- Do not include real user health data, payment evidence, secret, or production screenshot in diagrams.
