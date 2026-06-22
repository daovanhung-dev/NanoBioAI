---
name: nabi-character
description: Implement or modify the Nabi character system, including static asset state selection, Nami persona, UI integration and tests.
---

# Nabi Character Task Skill

## Read first

1. `.codex/AGENTS.md`
2. `.codex/PROJECT_MAP.md`
3. `docs/features/nabi_character/NABI_CHARACTER_CONTEXT.md`
4. `assets/config/nabi/nabi_asset_manifest.json`
5. `assets/config/nabi/nabi_state_matrix.yaml`
6. `docs/features/nabi_character/NABI_INTEGRATION_GUIDE.md`

## Contract

- Assets are static transparent PNGs at `assets/images/nabi/<group>/`.
- The asset resolver is the only code allowed to map `NabiVisualState` to asset paths.
- UI must receive a typed descriptor; it must not access SQLite/Supabase directly.
- Copy must follow Nabi: ấm áp, tinh tế, không phán xét, chủ động vừa đủ.
- Do not modify V1 core guest flow or replace actual data with mocks.

## Working sequence

1. Identify target feature and related current screen/provider/repository.
2. Select a `NabiVisualState` based on business facts, not widget-local logic.
3. Use `nabi_state_matrix.yaml` priority and selected engagement band.
4. Add relevant unit/widget/golden test.
5. Update docs/worklog and export changed files to a project-relative zip.
