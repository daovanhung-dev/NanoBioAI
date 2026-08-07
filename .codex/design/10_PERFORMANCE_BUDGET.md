# Performance Budget

Avoid multiple simultaneous blur layers, unbounded shadows and full-screen repainting. Use RepaintBoundary only where profiling justifies it. Infinite animation is offscreen-paused and performance-tier aware. Large lists/tables use lazy rendering. Motion should not create layout thrash; prefer transform/opacity for short transitions and animate only changed regions.
