Commit de xuat: docs(issue): ghi nhan loi env tracked bundled

# Issue - Env tracked and bundled

## Summary

`.env` was tracked by git while `.gitignore` already declared it should be
ignored, and `pubspec.yaml` bundled `.env` as a Flutter asset.

## Severity

- Severity: blocker
- Security impact: local secrets/config can enter source control and app
  bundles.

## Evidence

- Technical debt checklist recorded `git ls-files -- .env` returning `.env`.
- `pubspec.yaml` had `assets: - .env`.
- `.gitignore` already contained `.env` and `*.env`, so tracked state
  contradicted repo policy.

## Expected

- Real `.env` remains local and ignored.
- Flutter app does not package `.env` as an asset.
- Runtime config uses `--dart-define` or another secret-safe platform channel.

## Suggested Fix

- Remove `.env` from git tracking without deleting the local file.
- Remove `.env` from Flutter assets.
- Add a config helper that reads compile-time defines first and only treats
  dotenv as an optional legacy fallback.
- Update `.env.example` to avoid instructing developers to bundle secrets.
