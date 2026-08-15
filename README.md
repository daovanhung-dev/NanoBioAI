# NanoBio bugfix package - 2026-08-15

This package fixes the concrete analyzer errors/warnings reported after the Meal Plan image integration without mass-editing valid `RegExp` code.

## Apply

From PowerShell:

```powershell
python .\apply_fix.py D:\Project\NanoBio\nano_app
```

The installer creates a timestamped `.nanobio_fix_backup_*` directory before modifying project files.

## Validate

```powershell
powershell -ExecutionPolicy Bypass -File .\validate_after_apply.ps1 D:\Project\NanoBio\nano_app
```

If VS Code still shows `RegExp is deprecated` on normal constructor usage while command-line analysis does not, refresh project packages and restart the Dart analysis server:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\refresh_dart_analysis.ps1 D:\Project\NanoBio\nano_app
```

Then run **Dart: Restart Analysis Server** from the VS Code command palette.

## Important Meal Plan behavior

The resolver still uses an exact verified asset allow-list. Unknown dishes do not fuzzy-match to a similar image. Legacy `MealPhoto` call sites receive a guaranteed-missing sentinel asset path so their existing `errorBuilder` renders the neutral placeholder.
