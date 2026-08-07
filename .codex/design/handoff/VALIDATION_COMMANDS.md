# Validation Commands

Docs-only overlay:
```powershell
rg "d126e8ad|Material 3 Expressive|Screen Registry" .codex/design
powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1
git diff --check
```

Runtime UI implementation later:
```powershell
dart format <touched paths>
flutter analyze <touched paths>
flutter test <matching tests>
```
Do not claim repository-local validation was run when working only from this detached artifact.
