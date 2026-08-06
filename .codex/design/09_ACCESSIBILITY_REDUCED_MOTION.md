# Accessibility and Reduced Motion

## 1. Motion settings resolution

Priority:

1. Operating system `disableAnimations`.
2. User explicit `reduced/static` setting.
3. App performance tier.
4. Full motion default.

## 2. Reduced behavior

- Translation/scale/parallax/loop: disabled.
- Opacity/color: 0–120 ms.
- Shimmer: static skeleton or low-frequency opacity.
- Nabi: static expression.
- Charts: final state, optional short opacity reveal.
- Celebration: static success icon + optional haptic/sound per setting.

## 3. Text scale

- Combine OS TextScaler + app preference once.
- Sticky CTA remains reachable.
- Cards expand vertically; no fixed text-height assumptions.
- Large numbers use responsive fit/min size but remain semantic.
- Test at 1.0, 1.3, 1.6 and max supported scale.

## 4. Semantics and focus

- Interactive motion wrappers preserve button/selected/enabled semantics.
- AnimatedSwitcher excludes outgoing duplicate semantics during transition.
- Dialog/sheet traps focus and returns focus on close.
- Sound/haptic is supplemental; never sole state signal.
- Color is not sole status signal.

## 5. Vestibular safety

- No large zoom, continuous parallax or rapid full-screen movement.
- No flashing/pulsing faster than safe limits.
- Critical state uses clarity, not repeated pulse.
