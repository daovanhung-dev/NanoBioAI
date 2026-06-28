# diagrams/ — PAYMENT_MEMBERSHIP / Thanh toán, xác minh và quyền gói

## Required Diagrams

| Diagram | Purpose | Related IDs | Status |
|---|---|---|---|
| context.mmd | Show actor, module, dependency, and data boundary. | PAYMENT_MEMBERSHIP-Fxx | Planned |
| overall-flow.mmd | Summarize main flow and failure branches. | PAYMENT_MEMBERSHIP-Fxx, PAYMENT_MEMBERSHIP-FNxx | Planned |
| state-payment_membership.mmd | Document state lifecycle from BD Appendix B where applicable. | PAYMENT_MEMBERSHIP-BRxx | Planned |
| sequence-core-flow.mmd | Sequence from View/API -> Use case -> Repository -> datasource/event/audit. | PAYMENT_MEMBERSHIP-FNxx | Planned |

## Notes
- Markdown flow tables in Overall/List_Features are the source until Mermaid files are added.
- Diagrams must not replace business rules or traceability tables.
- Do not include real user health data, payment evidence, secret, or production screenshot in diagrams.
