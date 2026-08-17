# Group - 01_foundation_shell

App composition, router, navigation, theme/motion scope and global feedback. Preserve app-surface selection and redirect semantics.

## Blue Wellness foundation contract

- Consumer/Sale seed: `#2F6FED`; wellness accent `#14A36F`; CTA `#245CC5 -> #4D8DF7`.
- Light canvas `#F7FAFF`, text `#15253D`, soft blue surface `#F4F8FF`.
- Blue owns brand/navigation/CTA; green owns leaf/health/success/nutrition/positive progress.
- Roboto weights 400/500/600/700; page gutter 16; input/card/sheet radii 14/20/28.
- Expose light and deterministic Material 3 fidelity dark schemes through semantic theme roles.
- Preserve the static facade only during migration; new presentation reads context-aware semantic colors. `STITCH_GREEN_UI_ENABLED=true` is rollback compatibility.
- Apply safe area, keyboard/focus, 48 dp targets, text scale and reduced-motion settings at the app shell.
- Admin keeps its independent workspace palette and lower-motion density while sharing typography, accessibility and dark compatibility.

## Source precedence

Stitch PNG/HTML governs consumer visual intent. Runtime and Approved DD govern routes, data and behavior. Unlicensed remote assets remain reference-only.

## Surfaces

- [V1-07 - Main Navigation](../screens/v1-07-main-navigation.md) - active-route
