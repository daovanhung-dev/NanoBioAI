# Component Design System

## Canonical layers

1. Foundation values.
2. Semantic tokens.
3. Interactive primitives.
4. Medical/wellness compositions.
5. Feature-specific assemblies.

## State matrix bắt buộc

Mọi interactive primitive phải có:

- Resting.
- Hover/focus nếu platform hỗ trợ.
- Pressed.
- Selected.
- Loading.
- Disabled.
- Success.
- Error.
- Reduced motion.
- High text scale.

## Components

### KineticButton
Primary, secondary, tertiary, destructive, icon, voice, premium, admin compact.

### KineticCard
Data, action, insight, warning, timeline, meal, goal, premium, admin metric.

### KineticChip
Choice, filter, input/removable, segmented item.

### KineticInput
Text, password, number, search, multiline, picker launcher.

### KineticStateTransition
Loading/empty/error/ready switch với stable key và layout preservation.

### KineticProgress
Linear, ring, step, timeline line, indeterminate.

### KineticListItem
Insert/delete/reorder/highlight và swipe threshold feedback.

### KineticSheet/Dialog
Spring/fade, focus trap, keyboard-safe, route semantics.

## Migration rule

- Không tạo component mới nếu primitive có variant phù hợp.
- Feature widget chỉ giữ layout/nghiệp vụ hiển thị đặc thù.
- `AppColors/AppSpacing/AppRadius/AppTextStyles/AppDuration` là compatibility facade trong migration.
- Không raw color/duration trong feature UI sau wave cleanup.
