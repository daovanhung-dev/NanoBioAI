# Design Token Mapping - Stitch Green Wellness

| Contract | Canonical value | Implementation direction |
| --- | --- | --- |
| Brand primary | `#006A46` | Semantic primary, focus and selected roles |
| Brand accent | `#14A36F` | Supporting highlight |
| Primary CTA | `#0F8E62 -> #32C789` | Named CTA/hero gradient only |
| Light background | `#F5FAF7` | Consumer page canvas |
| Primary text | `#12352A` | Light on-surface text |
| Mint surface | `#EAF9F1` | Soft wellness container |
| Page gutter | 16 dp | Compact page padding |
| Input/card/sheet radius | 14/20/28 dp | Semantic component radii |
| Typography | Roboto 400/500/600/700 | Bundled and deterministic |
| Dark | M3 fidelity from `#006A46` | Frozen `ColorScheme`; no dynamic color |

Map these contracts through `AppSemanticColors`, `ColorScheme`, `AppSpacing`, `AppRadius`, `AppTextStyles`, `AppGradients`, `AppShadows`, motion scope and medical primitives. `AppColors` remains a temporary compatibility facade. New feature UI reads context-aware semantic roles. Admin uses its own workspace palette.
