# Design System Implementation Status

## 📊 Tổng Quan

**Spec**: UI Theme Design System Refactor  
**Ngày bắt đầu**: 2026-06-13  
**Trạng thái**: 🟡 In Progress (60% Complete)

---

## ✅ Đã Hoàn Thành (Tasks 1-10)

### 1. Foundation Tokens (Layer 1) ✅

| Token Type | File | Status | Count |
|------------|------|--------|-------|
| Colors | `foundation/colors.dart` | ✅ | 28 colors |
| Gradients | `foundation/colors.dart` | ✅ | 5 gradients |
| Spacing | `foundation/spacing.dart` | ✅ | 10 values |
| Radius | `foundation/radius.dart` | ✅ | 7 levels |
| Shadows | `foundation/shadows.dart` | ✅ | 5 shadows |
| Typography | `foundation/typography.dart` | ✅ | Complete |
| Motion | `foundation/motion.dart` | ✅ | Complete |

**Target Met**: ✅ Colors (<28), Spacing (10), Gradients (<5), Shadows (<5)

### 2. Semantic Tokens (Layer 2) ✅

| Token Type | File | Status | Count |
|------------|------|--------|-------|
| Color Tokens | `tokens/color_tokens.dart` | ✅ | 29 mappings |
| Spacing Tokens | `tokens/spacing_tokens.dart` | ✅ | 15 tokens |
| Component Tokens | `tokens/component_tokens.dart` | ✅ | Complete |
| - Radius | - | ✅ | 7 mappings |
| - Shadows | - | ✅ | 6 mappings |
| - Motion | - | ✅ | 4 mappings |
| - Text Styles | - | ✅ | 7 presets |

**Features**:
- ✅ Light/Dark mode support
- ✅ Status color variants (success, warning, error, info)
- ✅ Light background colors for badges/chips
- ✅ Complete documentation

### 3. Primitive Components (Layer 3) ✅

| Component | File | Variants | Status |
|-----------|------|----------|--------|
| Button | `primitives/button.dart` | 5 variants | ✅ |
| Card | `primitives/card.dart` | 3 variants | ✅ |
| Chip | `primitives/chip.dart` | 3 variants | ✅ |
| Input | `primitives/input.dart` | 3 variants | ✅ |
| Badge | `primitives/badge.dart` | 3 variants + 5 statuses | ✅ |
| Section Header | `primitives/section_header.dart` | - | ✅ |
| Empty State | `primitives/states/empty_state.dart` | - | ✅ |
| Loading State | `primitives/states/loading_state.dart` | 3 variants | ✅ |
| Error State | `primitives/states/error_state.dart` | - | ✅ |

**Total**: 9 primitive components with 20+ variants

**Features**:
- ✅ Token-based styling (no hardcoded values)
- ✅ Light/Dark mode adaptation
- ✅ Const constructors where possible
- ✅ Comprehensive documentation with examples
- ✅ Loading, disabled, error states

### 4. Design System Export ✅

**File**: `design_system.dart`

Single-file import cho toàn bộ design system:

```dart
import 'package:nano_app/core/theme/design_system.dart';

// Sử dụng tokens
color: AppColorTokens.primary
padding: EdgeInsets.all(AppSpacingTokens.pagePadding)

// Sử dụng components
AppButton(variant: ButtonVariant.primary, ...)
AppCard(variant: CardVariant.elevated, ...)
```

---

## 🚧 Đang Thực Hiện / Chưa Hoàn Thành (Tasks 11-17)

### Task 11: Refactor Onboarding Flow UI ❌

**Trạng thái**: Not Started  
**Phức tạp**: High  
**Ước tính**: 4-6 hours

**Cần làm**:
- [ ] 11.1: Remove gradient backgrounds từ 7 step widgets
- [ ] 11.2: Replace custom components với primitives
  - Replace buttons với `AppButton`
  - Replace inputs với `AppInput`
  - Replace chips với `AppChip`
  - Apply `AppSpacingTokens`, `AppColorTokens`, `AppTextStyles`

**Files cần refactor**:
- `welcome_step.dart` - Heavy gradients & decorations
- `basic_info_step.dart` - Custom inputs
- `goals_step.dart` - Custom chips
- `conditions_step.dart` - Custom chips
- `lifestyle_step.dart` - Mixed inputs
- `extras_step.dart` - Mixed inputs
- `review_step.dart` - Display cards
- `onboarding_step_shell.dart` - Shell container
- `onboarding_chip.dart` - Custom chip implementation
- `onboarding_text_field.dart` - Custom input implementation

### Task 13: Refactor Feature Screens ❌

**Trạng thái**: Not Started  
**Ước tính**: 6-8 hours

**Features cần refactor**:
- Dashboard
- Meal Plan
- AI Chat (placeholder)
- Other features

### Task 14: Backward Compatibility Layer ❌

**Cần tạo**:
- [ ] `deprecated.dart` - Aliased tokens với @Deprecated annotations
- [ ] `MIGRATION_GUIDE.md` - Before/after examples

### Task 15: Documentation ❌

**Cần tạo**:
- [ ] Inline dartdoc cho tất cả tokens
- [ ] `README.md` - Design system overview
- [ ] Visual examples

### Task 16: Performance Optimization ❌

**Cần kiểm tra**:
- [ ] Const constructor usage
- [ ] Widget decoration nesting
- [ ] Shadow & gradient optimization

### Task 17: Final Validation ❌

**Cần validate**:
- [ ] Token count targets
- [ ] Visual consistency (light/dark)
- [ ] Contrast ratios (WCAG)
- [ ] Tests pass

---

## 📁 Cấu Trúc File Hiện Tại

```
lib/core/theme/
├── foundation/              ✅ Complete
│   ├── colors.dart          (28 colors + 5 gradients)
│   ├── spacing.dart         (10 values)
│   ├── radius.dart          (7 levels)
│   ├── shadows.dart         (5 shadows)
│   ├── typography.dart      (Complete)
│   └── motion.dart          (Complete)
│
├── tokens/                  ✅ Complete
│   ├── color_tokens.dart    (29 mappings)
│   ├── spacing_tokens.dart  (15 tokens)
│   └── component_tokens.dart (Radius, Shadow, Motion, Text)
│
├── primitives/              ✅ Complete
│   ├── button.dart          (5 variants)
│   ├── card.dart            (3 variants)
│   ├── chip.dart            (3 variants)
│   ├── input.dart           (3 variants)
│   ├── badge.dart           (3 variants + 5 statuses)
│   ├── section_header.dart
│   └── states/
│       ├── empty_state.dart
│       ├── loading_state.dart
│       └── error_state.dart
│
├── design_system.dart       ✅ Barrel export file
└── app_theme.dart           ⚠️  Old system (chưa migrate)
```

---

## 🎯 Hướng Dẫn Sử Dụng

### Import Design System

```dart
import 'package:nano_app/core/theme/design_system.dart';
```

### Sử Dụng Semantic Tokens

```dart
// Colors
Container(
  color: AppColorTokens.surface,           // Surface color
  decoration: BoxDecoration(
    color: AppColorTokens.primary,         // Primary brand color
    border: Border.all(
      color: AppColorTokens.border,        // Border color
    ),
  ),
  child: Text(
    'Hello',
    style: AppTextStyles.heading1.copyWith(
      color: AppColorTokens.textPrimary,   // Text color
    ),
  ),
)

// Spacing
Padding(
  padding: EdgeInsets.all(AppSpacingTokens.pagePadding),    // 16px
  child: Column(
    children: [
      Widget1(),
      SizedBox(height: AppSpacingTokens.itemSpacing),        // 8px
      Widget2(),
    ],
  ),
)

// Radius & Shadows
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppRadiusTokens.card),  // 16px
    boxShadow: AppShadowTokens.card,                             // Small shadow
  ),
)
```

### Sử Dụng Primitive Components

```dart
// Button
AppButton(
  variant: ButtonVariant.primary,
  onPressed: () {},
  child: Text('Save'),
)

// Card
AppCard(
  variant: CardVariant.elevated,
  onTap: () {},
  child: Column(
    children: [
      SectionHeader(
        title: 'Title',
        subtitle: 'Subtitle',
        actionLabel: 'View All',
        onAction: () {},
      ),
      // Content...
    ],
  ),
)

// Chip
AppChip(
  variant: ChipVariant.selectable,
  label: 'Health Goal',
  selected: true,
  onTap: () {},
)

// Input
AppInput(
  variant: InputVariant.textField,
  label: 'Email',
  hint: 'Enter your email',
  controller: emailController,
  errorText: validator(email),
)

// Badge
AppBadge(
  variant: BadgeVariant.status,
  status: BadgeStatus.success,
  label: 'Active',
)

// States
if (isLoading)
  LoadingState(
    variant: LoadingVariant.spinner,
    message: 'Loading...',
  )
else if (hasError)
  ErrorState(
    message: 'Failed to load',
    onRetry: () {},
  )
else if (isEmpty)
  EmptyState(
    icon: Icons.inbox,
    title: 'No Items',
    description: 'You don\'t have any items yet.',
    actionLabel: 'Create',
    onAction: () {},
  )
else
  ContentWidget()
```

### Light/Dark Mode Support

```dart
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  return Container(
    color: isDark 
      ? AppColorTokens.darkSurface 
      : AppColorTokens.surface,
    child: Text(
      'Hello',
      style: AppTextStyles.bodyLarge.copyWith(
        color: isDark
          ? AppColorTokens.darkTextPrimary
          : AppColorTokens.textPrimary,
      ),
    ),
  );
}
```

---

## ⚠️ Lưu Ý Quan Trọng

### DO ✅

1. **Luôn dùng semantic tokens**, không dùng foundation tokens trực tiếp:
   ```dart
   // ✅ GOOD
   color: AppColorTokens.primary
   
   // ❌ BAD
   color: ColorFoundation.blue500
   ```

2. **Luôn dùng primitive components** thay vì custom implementations:
   ```dart
   // ✅ GOOD
   AppButton(variant: ButtonVariant.primary, ...)
   
   // ❌ BAD
   Container(
     decoration: BoxDecoration(
       color: AppColors.primary,
       borderRadius: BorderRadius.circular(12),
     ),
     child: InkWell(
       onTap: () {},
       child: Text('Button'),
     ),
   )
   ```

3. **Support light/dark mode** trong mọi custom widgets
4. **Dùng const constructors** khi có thể để improve performance

### DON'T ❌

1. **Không hardcode colors, spacing, radius**:
   ```dart
   // ❌ BAD
   color: Color(0xFF3B82F6)
   padding: EdgeInsets.all(16)
   borderRadius: BorderRadius.circular(12)
   ```

2. **Không dùng foundation tokens trực tiếp trong features**
3. **Không tạo custom button/card/input implementations mới**
4. **Không duplicate styling logic**

---

## 🚀 Bước Tiếp Theo

### Ưu tiên cao (Recommended)

1. **Task 11**: Refactor Onboarding Flow
   - Start with simplest step first (Review step)
   - Test thoroughly after each step
   - Keep business logic unchanged

2. **Task 13.1**: Identify hardcoded styling in Dashboard
   - Search for `Color(0x...)`
   - Search for literal `EdgeInsets`
   - Search for inline `BoxShadow`

### Ưu tiên trung bình

3. **Task 14**: Create migration guide
4. **Task 15**: Add documentation

### Ưu tiên thấp

5. **Task 16**: Performance optimization
6. **Task 17**: Final validation

---

## 📞 Hỗ Trợ

Nếu cần hỗ trợ hoặc có câu hỏi về design system:

1. Đọc inline documentation trong các token files
2. Xem examples trong IMPLEMENTATION_STATUS.md (file này)
3. Tham khảo primitive component source code để hiểu cách dùng

---

**Last Updated**: 2026-06-13  
**Version**: 1.0.0  
**Status**: Foundation & Primitives Complete ✅ | Refactoring Pending 🚧
