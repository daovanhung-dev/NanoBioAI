# Worklogs for AI Coding Agents

Every task (`coding`, `fix`, `docs`, `test`, `refactor`, `operations`) writes `.agents/worklog/YYYY-MM-DD/<task-slug>.md` with the template below.

## Preflight

```bash
python3 scripts/select_worklogs.py --type coding --limit 3
```

Read selected worklogs **before editing**; the selector provides paths, not evidence read. If fewer than 3 matching logs exist, record shortage. Exact `primary_task_type` match; no substitution with other types. Avoid bloated logs: 1 useful handoff per task.

## Must record

- Prior logs read and learnings
- Expected/current behavior and source
- Caller/callee/DB/provider/response/tests trace
- Changes, affected interfaces and assumptions
- Actual verification commands with `PASS|FAIL|NOT_RUN|BLOCKED`
- Context update, blockers and handoff

Do not store credentials, PII, raw secret-bearing logs or private payloads in worklogs.
