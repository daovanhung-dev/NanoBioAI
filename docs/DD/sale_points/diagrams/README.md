# diagrams/ — SALE_POINTS / Điểm Sale & quy đổi

## Required Diagrams

| Diagram | Purpose | Related IDs | Status |
|---|---|---|---|
| context.mmd | Show actor, module, dependency, and data boundary. | SALE_POINTS-Fxx | Planned |
| overall-flow.mmd | Summarize main flow and failure branches. | SALE_POINTS-Fxx, SALE_POINTS-FNxx | Planned |
| state-sale_points.mmd | Document state lifecycle from BD Appendix B where applicable. | SALE_POINTS-BRxx | Planned |
| sequence-core-flow.mmd | Sequence from View/API -> Use case -> Repository -> datasource/event/audit. | SALE_POINTS-FNxx | Planned |

## Notes
- Markdown flow tables in Overall/List_Features are the source until Mermaid files are added.
- Diagrams must not replace business rules or traceability tables.
- Do not include real user health data, payment evidence, secret, or production screenshot in diagrams.
