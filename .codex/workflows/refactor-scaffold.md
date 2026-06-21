# Workflow - Refactor Scaffold

Use for restructuring version folders, feature scaffolds, route shells, or module boundaries.

## Required Context

- `.codex/AGENTS.md`
- `.codex/PROJECT_MAP.md`
- `.codex/DOCS_WORKFLOW.md`
- `.codex/domains/access-membership-referral.md`
- `test/architecture_version_boundary_test.dart`
- `test/architecture_preservation_property_test.dart` when architecture contracts are touched.

## Rules

- Keep v1 guest/basic, v2 authenticated free, v3 Plus/FamilyPlus planned, sale/referral independent.
- Do not move business logic across versions unless BD/DD requires it.
- Preserve existing routes and public providers unless usage has been checked by `rg`.

## Completion

- Update project map, map tree, architecture tests, docs/worklog, and history.
