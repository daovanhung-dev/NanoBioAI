# diagrams/ — AUTH_PROFILE_SYNC / Xác thực, hồ sơ và đồng bộ Guest

## Required Diagrams

| Diagram | Purpose | Related IDs | Status |
|---|---|---|---|
| context.mmd | Show actor, module, dependency, and data boundary. | AUTH_PROFILE_SYNC-Fxx | Planned |
| overall-flow.mmd | Summarize main flow and failure branches. | AUTH_PROFILE_SYNC-Fxx, AUTH_PROFILE_SYNC-FNxx | Planned |
| state-auth_profile_sync.mmd | Document state lifecycle from BD Appendix B where applicable. | AUTH_PROFILE_SYNC-BRxx | Planned |
| sequence-core-flow.mmd | Sequence from View/API -> Use case -> Repository -> datasource/event/audit. | AUTH_PROFILE_SYNC-FNxx | Planned |

## Notes
- Markdown flow tables in Overall/List_Features are the source until Mermaid files are added.
- Diagrams must not replace business rules or traceability tables.
- Do not include real user health data, payment evidence, secret, or production screenshot in diagrams.
