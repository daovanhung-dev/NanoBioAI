# Agent Coding Workflows

## Common preflight

1. `AGENTS.md` -> context map -> worklog selector. Read selected logs before deep edit.
2. Identify `primary_task_type`, owner module, contract, affected DB/external interfaces.
3. Write down **expected** behavior (requirement/contract) and **current** behavior (source/test/observed runtime).
4. Trace `caller -> callee -> DB/provider side effect -> response -> tests`.
5. Define smallest scoped implementation and how to verify.

## Coding a new API

`requirements -> API contract -> model fields -> pure validations -> DB contract/migration -> SQL with bound params -> view with auth/business/txn -> router/DI -> tests -> docs/context/worklog`.

- For no database feature, omit `query.py` unless useful; don't create empty placeholders solely to match template.
- Response business code/status mapping must be agreed before implementation. If not agreed, write a proposal and mark `ASSUMPTION`.

## Fixing a bug

`reproduce failing case -> collect evidence -> trace root cause across layers -> smallest fix -> regression test -> full related tests -> context/log update`.

- Do not randomly catch exceptions to silence test. Don't weaken tests to make broken behavior pass.

## Refactoring

`baseline tests -> establish behavior to preserve -> incremental refactor -> verify no API/schema side effects -> update context if ownership changed`.

## Documentation

`current source -> live tests/config/migration -> approved requirements -> docs update`. Mark `SOURCE_BACKED`, `UNWIRED`, `DISCREPANCY` truthfully.

## Delivery / release

`review -> lint/typecheck/test -> DB migration dry run -> security scan -> stage verify -> rollback preparation -> deploy only with authorization -> monitor`.

## Required final handoff

```text
SCOPE:
REQUIREMENT/CONTRACT:
CURRENT SOURCE:
FILES CHANGED:
IMPACTED INTERFACES:
VERIFICATION (exact commands + outcomes):
DISCREPANCIES/ASSUMPTIONS:
CONTEXT/WORKLOG UPDATED:
REMAINING BLOCKERS:
```

Never claim tests passed if commands weren't run. Context validator checks docs wiring only, not backend correctness.
