# Theme and Design System Status

Lifecycle: `Current`. Baseline: `25018e8`.

The production app primarily imports `lib/core/theme/theme.dart`, which exports
the active app theme, semantic colors, typography, spacing, motion, experience,
medical UI and feedback layers. `design_system.dart` and the three-layer
foundation/token/primitive library also have active consumers, but are not the
only production styling API.

## Status by area

| Area | Status | Evidence |
| --- | --- | --- |
| App light/dark theme | `Implemented` | User and Admin `MaterialApp.router` use `AppTheme`; Settings controls theme mode. |
| Semantic colors/typography/spacing/radius | `Implemented` | Exported by `theme.dart` and used across presentation source. |
| Motion policy and reduced motion | `Implemented` | `AppMotionScope`, performance tiers and shared transition primitives have runtime consumers. |
| Feedback/haptic/sound abstraction | `Implemented/Partial` | Central feedback service is used; hardware/audio behavior needs device verification. |
| Foundation/tokens/primitives | `Implemented` library | `design_system.dart` exports the three layers and production files import them. |
| Medical UI components | `Implemented` library | `medical_ui.dart` primitives are used by V1/V2/V3/Admin/Sale screens. |
| Design-system demo | `Source-only` | `DesignSystemDemoPage` has no main/router consumer. |
| Full visual parity/accessibility | `UNVERIFIED` | Requires screenshot/device/text-scale/reduced-motion test evidence. |

## Canonical entrypoints

- Production shared theme: `package:nano_app/core/theme/theme.dart`.
- Three-layer design-system API:
  `package:nano_app/core/theme/design_system.dart`.
- UI/motion design source: `.codex/design/README.md` and its routed matrix.

Do not use historic task percentages or old “Tasks 1-17” checklists as current
implementation evidence. For file-level migration status, use the current
design registry and static reachability; for visual claims, run the relevant
tests/device review and record evidence.

## Validation

```powershell
python tools/validate_kinetic_aura.py
flutter test <targeted-theme-and-widget-tests>
git diff --check
```

If Flutter/device tooling is unavailable, record those checks as `UNVERIFIED`,
not PASS.
