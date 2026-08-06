# Domain - UI / Theme / NabiCopy

## Source

- `.codex/design/README.md` and the exact group/file matrix for UI refactor tasks.
- `lib/core/theme/`
- Feature page/widget files in scope.
- Widget tests when present.

## Required Design Read Pack For UI Refactor

1. `.codex/design/00_NABI_KINETIC_AURA_MASTER_DESIGN.md`
2. `.codex/design/03_MOTION_SYSTEM.md`
3. `.codex/design/05_SOUND_HAPTIC_SYSTEM.md`
4. `.codex/design/12_UI_FILE_DESIGN_MATRIX.md`
5. One matching file under `.codex/design/groups/`
6. `.codex/design/15_CODING_PLAN.md`

Do not read all group files by default. Use the matrix to select the exact group and files.

## Rules

- Prefer theme tokens: `AppColors`, `AppSpacing`, `AppRadius`, `AppTextStyles`, `AppDecoration`, `AppGradients`, `AppShadows`, `AppDuration`.
- Avoid overflow with proper constraints, scroll views, `Flexible`, or `Expanded`.
- Loading/error/empty/success states should be complete.
- User-facing text is Vietnamese, gentle, non-judgmental, and avoids internal technical terms.
- Do not expose database/table/query/parser/exception/stack trace/log to end users.

## Search

```powershell
rg "database|table|query|exception|stack trace|parser|log" lib/app_versions lib/services
rg "AppColors|AppSpacing|AppRadius|AppTextStyles|AppDuration" lib/core/theme lib/app_versions
```
