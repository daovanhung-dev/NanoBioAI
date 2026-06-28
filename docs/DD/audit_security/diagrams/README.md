# diagrams/ — AUDIT_SECURITY / Audit, bảo mật & hỗ trợ

## Required Diagrams

| Diagram | Purpose | Related IDs | Status |
|---|---|---|---|
| context.mmd | Show actor, module, dependency, and data boundary. | AUDIT_SECURITY-Fxx | Planned |
| overall-flow.mmd | Summarize main flow and failure branches. | AUDIT_SECURITY-Fxx, AUDIT_SECURITY-FNxx | Planned |
| state-audit_security.mmd | Document state lifecycle from BD Appendix B where applicable. | AUDIT_SECURITY-BRxx | Planned |
| sequence-core-flow.mmd | Sequence from View/API -> Use case -> Repository -> datasource/event/audit. | AUDIT_SECURITY-FNxx | Planned |

## Notes
- Markdown flow tables in Overall/List_Features are the source until Mermaid files are added.
- Diagrams must not replace business rules or traceability tables.
- Do not include real user health data, payment evidence, secret, or production screenshot in diagrams.
