# Nabi v2 asset manifest

The canonical, machine-readable manifest is
`assets/config/nabi_v2/nabi_v2_asset_manifest.json`.

- 84 static state PNGs: `assets/images/nabi_v2/<category>/nabi_*.png`
- 10 fallback expressions: `assets/nabi_v2/01_character/01_static_expressions/nabi_exp_*.png`
- 30 animation sequences, each with `frame_0001.png` through
  `frame_0030.png`
- 7 effect sequences, each with 30 frames
- all physical paths are lowercase PNG RGBA with transparent backgrounds

The JSON catalog preserves old animation/expression identifiers in
`legacy_id` only. Runtime code resolves physical paths through
`NabiAssetCatalog`; do not copy paths into feature widgets.

Use the generated `nabi_v2_state_matrix.json`, `nabi_v2_expression_map.json`,
and `nabi_v2_motion_map.json` to inspect visual semantics. Future/FamilyPlus/
Sale records are visual inventory only and do not change their existing access
gates.

Validate before release:

```powershell
python tools/generate_nabi_v2_assets.py validate --static-root assets/images/nabi_v2 --sprite-root assets/nabi_v2 --catalog-root assets/config/nabi_v2
python tools/verify_nabi_v2_release_assets.py --apk build/app/outputs/flutter-apk/app-debug.apk
```
