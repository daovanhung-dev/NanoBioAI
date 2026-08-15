# Fixbug - Meal image compatibility + analyzer cleanup

Date: 2026-08-15
Workflow: `bugfix`

## Root causes

1. `MealPhoto` calls `MealImageResolver.assetPathFor(meal)`, while the exact-image resolver package introduced a newer `resolveAssetPath(String)` API and dropped the compatibility method. This caused `undefined_method`.
2. Riverpod 3.x marks `AsyncValue.copyWithPrevious` as internal. Application code in `AuthController` called it three times.
3. Two imports and one test helper were genuinely unused.
4. `TickerMode.of` has a public replacement: `TickerMode.valuesOf(context).enabled`.
5. The editor-wide `RegExp` deprecation diagnostics are not a request to replace normal regex usage. Dart only deprecated implementing `RegExp`/`RegExpMatch`; SDK tooling had a known presentation/analysis issue around the annotation.

## Fix strategy

- Restore `assetPathFor`, `assetPathForName`, and `slugFor` as compatibility APIs while retaining exact allow-list resolution.
- Unknown meals resolve to a guaranteed-missing sentinel path for legacy `Image.asset(..., errorBuilder:)` call sites; `resolveAssetPath` itself returns `null`. No fuzzy matching is introduced.
- Remove artificial `AsyncLoading.copyWithPrevious` transitions. Keep the currently resolved auth route unchanged during imperative operations and publish only the resolved success/error state. `_runAccountMutation` retains its explicit previous state for rollback on failure.
- Remove only confirmed dead imports/helper.
- Migrate the real Flutter deprecation and the VietQR string-composition lint.
- Do not mass-suppress `deprecated_member_use` for ordinary `RegExp(...)` usage.

## Validation

The package installer was applied twice to a source fixture containing all targeted anchors. Checks confirmed:

- no `.copyWithPrevious(` call remains;
- only the rollback `previousState` declaration remains;
- unused imports are removed while the auth dependency export remains;
- dead `_functionBlock` is removed and `_lastFunctionBlock` remains;
- `TickerMode.valuesOf(context).enabled` is applied;
- resolver compatibility APIs and exact unknown fallback are present;
- installer is repeat-safe.

Flutter/Dart runtime validation cannot be executed in the artifact sandbox because the SDK binaries are not installed there. Run `validate_after_apply.ps1` in the real NanoBio checkout.
