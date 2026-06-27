# DD Module From BD Reference

Use this reference together with `docs/DD/DD_Module_Creation_Guide_EN.md` and `docs/DD/DD_Module_Template/`.

## Input Extraction

Extract only evidence-backed information from the BD source:

- Module purpose and boundary.
- Roles and actors.
- User journeys and state transitions.
- Business rules, acceptance criteria, and constraints.
- Data entities, ownership, retention, and privacy/security notes.
- API, Supabase, local storage, notification, AI, or third-party dependencies.
- Feature list, function list, view list, and import/source impact.
- Open questions, assumptions, proposals, and out-of-scope items.

When the BD conflicts with existing DD/source behavior, preserve both facts and mark the conflict explicitly.

## Folder And File Responsibilities

`README.md`
: Entry point for the DD module. Include source BD path, module scope, status, document map, traceability summary, open questions, and validation notes.

`Overall.md`
: Describe the module objective, actors, end-to-end flows, states, business rules, non-functional requirements, architecture impact, dependency map, risks, and implementation order.

`List_Features.md`
: List module features with IDs, source evidence, priority, status, acceptance criteria, business rules, dependencies, test references, and open questions.

`Function_List.md`
: Convert features into implementation functions, services, APIs, providers/controllers, repositories, data operations, background jobs, and error paths. Include ownership, inputs, outputs, side effects, dependencies, and tests.

`Views.md`
: Define screens, components, navigation, states, permissions, empty/error/loading behavior, copy requirements, analytics if applicable, and traceability to feature/function IDs.

`Import_File.md`
: Map the files that should be created, changed, imported, or referenced. Include source roots, dependencies, layering rules, and risky imports to avoid.

`diagrams/README.md`
: Document required diagrams in text form first. Add Mermaid diagrams only when they clarify flow, state, data, sequence, or dependency relationships.

Module-level assets README
: List required images, icons, copy assets, prompt assets, fixtures, or other non-code artifacts. Mark missing assets as open questions.

`history/CHANGELOG.md`
: Record DD creation and each meaningful revision with date, source, author/agent, scope, validation, and unresolved decisions.

## Traceability Pattern

Prefer compact tables that keep evidence visible:

- BD source -> feature ID.
- Feature ID -> function/API/business-rule IDs.
- Function ID -> view/source/test IDs.
- Open question -> affected feature/function/view IDs.

Do not leave a DD item without a source reference unless it is clearly marked as an assumption or proposal.

## Quality Gate

Before finishing, verify:

- Required files exist and placeholders are removed or deliberately marked.
- Feature/function/view IDs are stable and cross-linked.
- Open questions are explicit and not hidden as implementation defaults.
- Data/security/payment/auth behavior is not guessed.
- Folder names and source paths are real or marked as planned.
- Runtime code was not changed unless separately requested.
- Worklog and generated context refresh completed.
