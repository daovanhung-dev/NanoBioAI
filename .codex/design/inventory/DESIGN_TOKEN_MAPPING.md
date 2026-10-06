# Design Token Mapping — NanoBio Blue Wellness

| Contract | Canonical value | Implementation direction |
| --- | --- | --- |
| Brand primary | `#285CC5` | Semantic primary, focus and selected roles |
| Health accent | `#16845C` | Health, nutrition and positive-progress roles |
| Primary CTA | `#234FA8 -> #3971D3` | Subtle CTA range, used selectively |
| Light background | `#F5FAF7` | Consumer page canvas |
| Primary text | `#12352A` | Light on-surface text |
| Mint surface | `#EAF9F1` | Soft wellness container |
| Page gutter | 16 dp | Compact page padding |
| Input/card/sheet radius | 14/20/28 dp | Semantic component radii |
| Typography | Roboto 400/500/600/700 | Bundled and deterministic |
| Dark | Blue Wellness semantic snapshot | Frozen `ColorScheme`; no dynamic color |

Map these contracts through `AppSemanticColors`, `ColorScheme`, `AppSpacing`, `AppRadius`, `AppTextStyles`, `AppGradients`, `AppShadows`, motion scope and medical primitives. `AppColors` remains a temporary compatibility facade. New feature UI reads context-aware semantic roles. Admin uses its own workspace palette.
