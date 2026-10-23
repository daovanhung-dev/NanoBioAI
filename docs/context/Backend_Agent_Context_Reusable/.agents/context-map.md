# Agent Context Map

```text
AGENTS.md
  └─ .agents/AGENTS.md
      └─ .agents/context-map.md
          ├─ preflight: scripts/select_worklogs.py -> .agents/worklog/
          ├─ .agents/project/INDEX.md
          │   ├─ 01-product-context.md   (requirements, actors, scope)
          │   ├─ 02-architecture.md      (code ownership, DI)
          │   ├─ 03-technology.md        (stack/decision matrix)
          │   ├─ 04-coding-conventions.md
          │   ├─ 05-api-contract.md
          │   ├─ 06-validation.md
          │   ├─ 07-database.md
          │   ├─ 08-auth-security.md
          │   ├─ 09-error-observability.md
          │   ├─ 10-testing.md
          │   ├─ 11-devops-operations.md
          │   ├─ 12-task-workflows.md
          │   └─ 13-decisions.md
          ├─ .agents/modules/README.md -> TEMPLATE.md -> module doc
          └─ exact code + schema + config + tests + worklog
```

## Router by task

| Task | Context pages | Verify |
|---|---|---|
| Add endpoint | 01, 02, 04, 05, 06, 07, 10, 12 | HTTP, schema, auth, transaction |
| Auth / RBAC | 05, 06, 08, 09, 10 | token/session, 401/403, role/ownership |
| DB/migration | 02, 07, 10, 11 | migrate up/down or rollback plan, indexes |
| Fix bug | 02, 04, 09, 10, 12 | failing reproduction then regression |
| API integration | 05, 09, 11, 12 | producer/consumer and contract tests |
| Release/operations | 03, 08, 09, 10, 11 | backup, health, rollback, monitoring |
| Documentation | 01, 02, 05, 12, source/tests | source-backed statuses |

## Guardrails

Load progressively: read the minimum needed for the task, then follow dependencies. Cross-module concerns must identify producer, consumer, version and failure mode. `scripts/validate_agent_context.py` validates references, not code runtime.
