# Domain - UI / Theme / Nami Copy

## Source

- `lib/core/theme/`
- Feature page/widget files in scope.
- Widget tests when present.

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
