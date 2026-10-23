# Decisions, Tradeoffs & Deviations

## Defaults (not immutable)

| ADR | Default | Status | Reason |
|---|---|---|---|
| ADR-000 | Modular monolith | `PROPOSED` | Keep deploy/ownership simple until measured needs |
| ADR-001 | FastAPI + Python 3.12+ | `PROPOSED` | Study-derived stack |
| ADR-002 | PostgreSQL + SQLAlchemy sync | `PROPOSED` | Explicit transaction model |
| ADR-003 | `models/validate/query/view` | `PROPOSED` | Easy code ownership and agent navigation |
| ADR-004 | Pydantic Settings env/secrets | `PROPOSED` | Correct limitation of Study hardcoded constants |
| ADR-005 | JWT access + opaque refresh | `PROPOSED` | Conditional on authentication requirements |
| ADR-006 | JSON envelope + trace ID | `PROPOSED` | Stable client contract |

Copy `templates/adr-template.md` to `docs/adr/NNN-short-title.md` to accept/modify a decision.

## Approval criteria for deviations

- Requirement/performance/operational evidence, alternatives, security impact, migration impact.
- Update architecture/tech/context pages and tests in same PR.
- No hidden switch to async DB, Redis persistence, microservices, OAuth, or full ORM from raw SQL without explicit reasoning.
