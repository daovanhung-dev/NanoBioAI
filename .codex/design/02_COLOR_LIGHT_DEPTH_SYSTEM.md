# Color, Light and Depth System — NanoBio Blue Wellness

Use semantic roles from the active theme, never raw colors in feature UI.

## Light source tokens

| Role | Value | Use |
| --- | --- | --- |
| Primary | `#285CC5` | Brand, navigation, focus and primary action |
| Primary dark | `#1C478F` | Pressed/strong emphasis and legible text on blue-tinted surfaces |
| Health accent | `#16845C` | Nutrition, positive health progress and success |
| CTA range | `#234FA8` → `#3971D3` | Subtle brand emphasis where a gradient clarifies hierarchy |
| Background | `#F4F7FB` | Consumer page canvas |
| Text primary | `#14243A` | Main text on light surfaces |
| Blue soft surface | `#E7EEFC` | Selected or lightly emphasized container |
| Health soft surface | `#E5F3EB` | Positive health container |

Status success, warning, error and information remain separate semantic families and must include text/icon/shape, not color alone. Violet remains reserved for AI or premium differentiation where the runtime capability actually exists.

## Dark scheme

Use one deterministic Material 3 semantic system for Blue Wellness and do not follow platform dynamic color. Presentation reads `AppSemanticColors` from `Theme.of(context)` so light and dark resolve the same semantic role. Record contrast evidence before acceptance. Green is reserved for health/success meanings, not navigation or general primary action.

## Depth

Content surfaces are opaque or tonal. Translucency is limited to transient controls and must remain readable when transparency is reduced. Prefer tonal separation and a 1 dp semantic border; reserve short shadows for raised interactive layers. Avoid ambient blur and decorative glow on health, payment, Sale or Admin data.
