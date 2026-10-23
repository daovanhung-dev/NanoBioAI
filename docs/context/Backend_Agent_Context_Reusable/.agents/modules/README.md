# Business Module Context Registry

Create one `.agents/modules/<feature>.md` (copy `TEMPLATE.md`) when a business feature is approved/implemented.

## Responsibility map

```text
app/modules/<bounded_context>/<feature>/
    models.py     -> pure transport DTO/contracts
    validate.py   -> pure special contract validation (optional)
    query.py      -> bound SQL/DB helpers; never commit (optional)
    view.py       -> business orchestration & transaction owner
```

`app/api/v1.py` imports only exposed `view` function and request models. Bounded contexts can be nested by product domain; do not force `guest` or `student` namespaces from Study2Work.

## Module checklist

- Public function/route + HTTP contract
- Input fields and strict type/normalization
- Auth/ownership checks and business invariants
- SQL queries, indexes, affected tables, DB migrations
- External side effects, timeout/retry/idempotency
- Transaction ownership, rollback, concurrency behavior
- Response projection, business code and trace
- Happy/negative/integration tests
- Status + evidence links

Module context is a **navigation map**, not proof of implementation. Source + verified tests take precedence.
