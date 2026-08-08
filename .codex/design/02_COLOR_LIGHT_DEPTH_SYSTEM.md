# Color, Light and Depth System - Stitch Green Wellness

Use semantic roles from the active theme, never raw colors in feature UI.

## Light source tokens

| Role | Value | Use |
| --- | --- | --- |
| Primary | `#006A46` | Navigation, focus, selected state and trusted primary action |
| Accent | `#14A36F` | Supporting highlight; never a replacement for semantic status |
| CTA start | `#0F8E62` | Start of primary CTA/hero gradient |
| CTA end | `#32C789` | End of primary CTA/hero gradient |
| Background | `#F5FAF7` | Consumer page canvas |
| Text primary | `#12352A` | Main text on light surfaces |
| Mint surface | `#EAF9F1` | Soft wellness container |

Status success, warning, error and information remain separate semantic families and must include text/icon/shape, not color alone. Violet remains reserved for AI or premium differentiation where the runtime capability actually exists.

## Dark scheme

Generate one deterministic Material 3 fidelity `ColorScheme` from seed `#006A46`, snapshot it into theme tokens and do not follow platform dynamic color. Presentation reads `AppSemanticColors` from `Theme.of(context)` so light and dark resolve the same semantic role. Record contrast evidence before acceptance.

## Depth

Content surfaces are opaque or tonal. Translucency is limited to floating navigation and transient controls and must remain readable when transparency is reduced. Prefer tonal separation, a 1 dp semantic border and a short soft shadow; avoid stacked blur and decorative glow on health, payment or Admin data.
