# Motion Performance Budget

## 1. Global targets

- 60 FPS target on mid-range Android.
- Frame budget: 16.7 ms; no sustained raster/UI jank during scroll.
- Maximum two page-level animation controllers active per visible route.
- One Nabi animation owner active.
- No large BackdropFilter blur in scrolling lists on balanced/reduced tier.

## 2. Tier policy

| Tier | Effects |
|---|---|
| Full | Shared element, limited glow/blur, Nabi 30fps if asset allows |
| Balanced | No large blur/parallax; fewer stagger/particles; Nabi reduced frame/cache |
| Reduced | Opacity/color only; static Nabi; no loops |

## 3. Widget rules

- Prefer implicit animations for one-property state.
- Controller must be disposed and paused via visibility/lifecycle.
- `RepaintBoundary` only around expensive isolated animation, not every card.
- Stable keys prevent recreation/replay.
- Do not rebuild whole list for one item status.
- Image/SVG/spritesheet decode must be bounded and precached selectively.

## 4. Nabi/audio

- Preload only active/next likely animation first frame.
- Stop ticker and audio on background.
- Do not load all frame sequences into memory.
- Short SFX player pool bounded; no concurrent duplicate cue.

## 5. Evidence required

- Flutter performance overlay/profile capture.
- Frame timing around Dashboard, Meal Plan, Schedule, AI Voice and Admin table.
- Memory before/after Nabi animation cycle.
- Real-device smoke on low/mid/high tier.
