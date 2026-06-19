Commit de xuat: docs(dd): them mau design document phuc vu coding

# Coding DD Template - <module-or-feature-name>

## 1. Metadata

| Field | Value |
| --- | --- |
| Status | Draft / Proposed / Accepted / Implemented / Deprecated |
| Owner | <person/team/agent> |
| Last updated | YYYY-MM-DD |
| Related code | `lib/...`, `test/...` |
| Related docs | worklog/ADR/issue links |

## 2. Goal

- User/problem goal:
- Product goal:
- Engineering goal:

## 3. Scope And Non-Goals

In scope:

- ...

Out of scope:

- ...

## 4. Current State

- Code da co:
- Data da co:
- UI da co:
- Test da co:
- Known gaps so voi DD/san pham:

## 5. Users And Entry Points

| Entry point | Trigger | Expected result |
| --- | --- | --- |
| `<screen/widget/provider>` | app open / button / notification / background action | ... |

## 6. Architecture Mapping

```text
Presentation
-> Provider/Controller
-> Repository
-> Datasource
-> DAO/API/Service
```

| Layer | File/class/provider | Responsibility |
| --- | --- | --- |
| Presentation | `...` | ... |
| Provider/Controller | `...` | ... |
| Domain | `...` | ... |
| Repository | `...` | ... |
| Datasource | `...` | ... |
| DAO/API/Service | `...` | ... |

## 7. Runtime Flow

```text
1. User/system trigger
2. Provider action
3. Repository orchestration
4. Datasource/DAO/API read-write
5. State emitted
6. UI renders loading/empty/error/data
```

Important branches:

- Success:
- Empty:
- Recoverable error:
- Fatal/blocking error:
- Offline/fallback:

## 8. Data Contract

Source of truth:

- SQLite / Supabase / AI response / local memory / notification payload:

Entities/models/tables:

| Name | Type | Required fields | Notes |
| --- | --- | --- | --- |
| `...` | entity/model/table | ... | ... |

Schema impact:

- New table:
- Changed column:
- Migration:
- Database version:
- Backfill/default:

## 9. UI/UX Contract

- Loading:
- Empty:
- Error:
- Success:
- Disabled/pending action:
- Vietnamese copy/Nami tone:
- Accessibility/responsive concerns:

## 10. Business Rules

- ...

## 11. Decisions

Link ADRs or summarize accepted decisions:

- `docs/DD/decisions/...` or `docs/...`

## 12. Test And Verification Plan

Automated:

- Unit:
- Widget:
- Integration:
- Architecture:

Manual:

- ...

Commands:

```powershell
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## 13. Risks And Rollback

- Risk:
- Mitigation:
- Rollback:

## 14. Implementation Checklist

- [ ] Update model/entity/DTO.
- [ ] Update provider/controller state.
- [ ] Update repository/datasource/DAO/API.
- [ ] Update SQLite version/migration/onCreate/table/model/DAO if schema changed.
- [ ] Update UI states and Vietnamese copy.
- [ ] Add/update tests.
- [ ] Update DD/worklog/ADR/issue docs.
- [ ] Run validation or record why skipped.

