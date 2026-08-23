# Design System Demo Page

Lifecycle: `Reference`. Implementation: `Source-only` at baseline `25018e8`.

`lib/core/theme/design_system_demo_page.dart` exists and renders tokens,
primitives, typography and state examples. It is not imported by `lib/main.dart`
or any registered route, so it is not part of the production runtime.

## Safe way to inspect

Use a temporary, uncommitted harness or widget test that mounts:

```dart
MaterialApp(home: DesignSystemDemoPage())
```

Import:

```dart
import 'package:nano_app/core/theme/design_system_demo_page.dart';
```

Do not replace `lib/main.dart` or document `/design-system-demo` as an existing
route. If a permanent developer-only route is intentionally added later, wire
it through the unified user router and protect it from release builds.

## What to check

- Light/dark theme.
- Text scale and narrow layouts.
- Button, card, chip, input, badge and state variants.
- Reduced motion and economical performance tier.
- Semantic colors and readable contrast.

Visual/device status remains `UNVERIFIED` until the demo is mounted and tested.
