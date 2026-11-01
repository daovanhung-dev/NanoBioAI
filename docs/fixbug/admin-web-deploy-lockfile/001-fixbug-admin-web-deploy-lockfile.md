Commit de xuat: fix(ci): restore Admin Web Pages deployment

# Fix GitHub Pages deployment for Admin Web

## Symptom

The GitHub Actions run for the Admin Web deployment stopped during `actions/setup-node@v4` with `Some specified paths were not resolved, unable to cache dependencies.` The workflow points its npm cache at `admin-web/package-lock.json`, but that file was absent. The run did not reach dependency installation, typecheck, tests, build, or Pages deployment.

## Root cause

- The Admin Web package had no npm lockfile, although the workflow configured npm caching against that lockfile and ran `npm ci`.
- `admin-web/package.json` did not define the `test` script required by the workflow.
- The local checkout has Deno-managed packages under `admin-web/node_modules`; running npm lockfile resolution there encountered an unrelated `workspace:*` entry from that Deno package tree.

## Fix

- Add a reproducible npm lockfile generated from the Admin Web manifest using Node 22 and npm 10 in an isolated clean directory.
- Add Vitest 5.0.5 and `npm test` (`vitest run`), and align the Vite minimum to 6.4 for the Vitest peer requirement. The npm registry did not contain the planned Vitest 5.1 range; 5.0.5 was the latest published 5.x version available during this change.
- Add regression tests for the global `fetch` receiver, readiness failure responses, and connection errors.
- Keep the existing workflow order and cache path. With the lockfile committed, `npm ci` can install the locked dependencies and the test step has a real script.

## Verification

- Official Node 22.23.4 archive checksum: PASS.
- Isolated `npm install --package-lock-only`: PASS; lockfile v3 resolves Vite 6.4.5 and Vitest 5.0.5.
- Isolated `npm ci`: PASS; npm reported zero vulnerabilities.
- `npm run typecheck`: PASS.
- `npm test`: PASS, 3 tests.
- `npm run build`: PASS.
- GitHub Actions / Pages deployment after push: NOT RUN; this change is committed locally only.

## Constraints

No backend API contract or Ubuntu service configuration changed. The existing Pages bundle remains unchanged until a later push triggers a successful deployment.
