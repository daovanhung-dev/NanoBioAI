# diagrams/ — ADMIN_DASHBOARD / Admin View / Dashboard

## Required Diagrams

| Diagram | Purpose | Related IDs | Status |
|---|---|---|---|
| context.mmd | Show actor, module, dependency, and data boundary. | ADMIN_DASHBOARD-Fxx | Planned |
| overall-flow.mmd | Summarize main flow and failure branches. | ADMIN_DASHBOARD-Fxx, ADMIN_DASHBOARD-FNxx | Planned |
| state-admin_dashboard.mmd | Document state lifecycle from BD Appendix B where applicable. | ADMIN_DASHBOARD-BRxx | Planned |
| sequence-core-flow.mmd | Sequence from View/API -> Use case -> Repository -> datasource/event/audit. | ADMIN_DASHBOARD-FNxx | Planned |

## Notes
- Markdown flow tables in Overall/List_Features are the source until Mermaid files are added.
- Diagrams must not replace business rules or traceability tables.
- Do not include real user health data, payment evidence, secret, or production screenshot in diagrams.
