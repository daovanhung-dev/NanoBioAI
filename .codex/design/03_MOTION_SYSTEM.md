# Motion System

Motion is causal. Default interaction timing: selection 120–180 ms, local state 160–240 ms, container/route 220–320 ms, numeric/progress 300–500 ms. Long ambient animation is exceptional and visibility/performance-gated.

Preferred patterns: fade-through for state replacement, shared-axis for peer navigation, container transform when object identity is preserved, shape morph for selection. Reduce Motion collapses translation/scale and loops, retaining short opacity/state changes. Do not restart whole-page animation on provider refresh when the information identity is unchanged.
