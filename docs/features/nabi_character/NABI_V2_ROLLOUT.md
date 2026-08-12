# Nabi v2 rollout

## Purpose

Nabi v2 replaces the incompatible robot and humanoid treatments with one
gender-neutral botanical companion. The asset contract is presentation-only:
it does not change health logic, quota, routes, notification scheduling,
membership gates, FamilyPlus, or sale behaviour.

## Canonical identity

- Pearly ivory seed body, two-leaf mint crown, forest-green details, and one
  restrained aqua drop.
- Soft matte 3D render, transparent background, no text, UI, watermark, or
  copied Stitch details.
- Legacy technical IDs are preserved. Formerly negative labels render as
  empathy, calm pause, quiet safety, or a gentle retry prompt.

The source images and construction constraints are in
`assets/nabi_v2/00_master/nabi_v2_character_sheet.md`.

## Asset contract

| Asset set | Path | Contract |
| --- | --- | --- |
| Static visual states | `assets/images/nabi_v2/<category>/` | 84 PNG, 512x512 RGBA |
| Static expressions | `assets/nabi_v2/01_character/01_static_expressions/` | 10 PNG, 512x512 RGBA |
| Character frames | `assets/nabi_v2/01_character/02_30fps_frames/` | 30 animations x 30 PNG, 384x384 RGBA |
| Effects | `assets/nabi_v2/03_effects/` | 7 sequences x 30 PNG, 256x256 RGBA |
| Derived outputs | `assets/nabi_v2/02_spritesheets/`, `previews/` | Generated only from approved frames |
| Metadata | `assets/config/nabi_v2/` | Lowercase catalog, manifest, state/expression/motion maps |

All physical asset paths and filenames are lowercase. The catalog intentionally
uses separate static and sprite roots because static onboarding/fallback UI and
the 30-fps player have different size contracts.

Only static poses, fallback expressions, and runtime frame directories are
declared in Flutter's release bundle. Effects, spritesheets, contact sheets,
and master sources remain in Git as verified derivative/QA material until a
runtime surface consumes them.

## QA switch and release handoff

`NABI_V2_ASSETS_ENABLED` is a compile-time switch. It is `true` by default,
so an unqualified build uses the release v2 package.

```powershell
flutter test --dart-define=NABI_V2_ASSETS_ENABLED=true test/features/nabi
flutter run --dart-define=NABI_V2_ASSETS_ENABLED=true
```

The release manifest declares only v2 roots; the v1 source files stay in Git
but are not bundled. To rollback, restore the archived v1 asset declaration
and build with `NABI_V2_ASSETS_ENABLED=false`; no data migration or entitlement
change is involved.

Validate a release candidate after generating the bundle:

```powershell
python tools/generate_nabi_v2_assets.py validate --static-root assets/images/nabi_v2 --sprite-root assets/nabi_v2 --catalog-root assets/config/nabi_v2
python tools/verify_nabi_v2_release_assets.py --apk build/app/outputs/flutter-apk/app-debug.apk
```

## Runtime ownership

`NabiAssetCatalog` is the only root selector. V1 overlay, AI Voice,
onboarding, chat avatar, and the legacy compatibility renderer all resolve
through it. `NabiAppShell` remains unmounted in the V1 shell, preventing a
second global mascot owner from being introduced.

Future/FamilyPlus/Sale assets are included as visual inventory only. Their
existing feature gates remain authoritative.
