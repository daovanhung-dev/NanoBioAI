# UI Development Rules - BioAI (nano_app)

> **Mục đích**: Tài liệu quy chuẩn phát triển UI để AI và lập trình viên khác có thể tiếp tục phát triển đúng chuẩn dự án, không phá kiến trúc, không phá theme, không viết code lệch style.
>
> **Ngày cập nhật**: 2026-06-18
>
> **Phạm vi**: Flutter application - BioAI (nano_app)

---

## Mục lục

1. [Tổng quan dự án](#1-tổng-quan-dự-án)
2. [Phân tích cấu trúc UI hiện tại](#2-phân-tích-cấu-trúc-ui-hiện-tại)
3. [Phân tích Design System](#3-phân-tích-design-system)
4. [Phân tích chi tiết các file quan trọng](#4-phân-tích-chi-tiết-các-file-quan-trọng)
5. [Bộ luật thiết kế UI bắt buộc](#5-bộ-luật-thiết-kế-ui-bắt-buộc)
6. [Bộ luật "Không được làm"](#6-bộ-luật-không-được-làm)
7. [Checklist bắt buộc trước khi code UI](#7-checklist-bắt-buộc-trước-khi-code-ui)
8. [Setup context cho AI khi lập trình UI](#8-setup-context-cho-ai-khi-lập-trình-ui)
9. [Prompt mẫu dùng lại cho AI](#9-prompt-mẫu-dùng-lại-cho-ai)

---

## 1. Tổng quan dự án

### 1.1. Framework và ngôn ngữ

- **Framework**: Flutter SDK `^3.9.2`
- **Ngôn ngữ**: Dart
- **State Management**: Riverpod 3 (Provider, FutureProvider, NotifierProvider, AsyncNotifierProvider, legacy StateNotifierProvider)
- **Navigation**: GoRouter
- **Storage**: SQLite (sqflite), SharedPreferences
- **Backend**: Supabase (auth), Gemini AI (google_generative_ai)


### 1.2. Kiến trúc tổng thể

**Kiến trúc chính**: Feature-first + Clean Architecture (một phần)

```
UI → Riverpod Provider/Controller → Repository → Datasource → SQLite/Supabase/AI
```

**Thực tế trong code**:
- Repository implementations thường nằm trong `domain/repositories/`
- Provider styles hỗn hợp: Provider, FutureProvider, NotifierProvider, AsyncNotifierProvider, legacy StateNotifierProvider
- AI/services vẫn import một số feature data models (architecture debt đã biết, KHÔNG refactor tự tiện)

### 1.3. Cách tổ chức thư mục

| Đường dẫn | Vai trò | Khi nào cần dùng | Lưu ý khi chỉnh sửa |
|-----------|---------|------------------|---------------------|
| `lib/app/` | App shell, entry point | Khởi tạo MaterialApp.router, theme, routing | **KHÔNG** chỉnh sửa app.dart, main.dart nếu chưa được yêu cầu |
| `lib/core/constants/` | Constants, app config | Lấy route names, config values | Không thay đổi route names hiện có |
| `lib/core/router/` | GoRouter configuration | Thêm/sửa routes | Phải đảm bảo auth guards hoạt động |
| `lib/core/storage/localdb/` | SQLite database | Thêm/sửa tables, migrations | **BẮT BUỘC** bump DB version khi thay đổi schema |
| `lib/core/theme/` | **Design system** | **MỌI** UI component phải dùng | **QUAN TRỌNG NHẤT** - đọc kỹ phần 3 |
| `lib/features/*/presentation/` | UI Pages và Widgets | Code UI cho từng feature | Tuân thủ feature-first structure |
| `lib/features/*/providers/` | Riverpod providers | State management | **KHÔNG** đổi tên provider public API |
| `lib/features/*/presentation/controllers/` | UI controllers/notifiers | Business logic cho UI | Giữ nguyên controller signatures |
| `lib/services/` | Shared services (AI, auth, notifications) | Gọi services từ controllers | **KHÔNG** gọi trực tiếp từ UI widgets |
| `lib/shared/widgets/` | Reusable widgets dùng chung | Widgets cross-feature | Ưu tiên dùng lại thay vì tạo mới |


### 1.4. Các module/chức năng lớn

| Feature | Trạng thái | UI Path | Lưu ý |
|---------|-----------|---------|-------|
| **Onboarding** | ✅ Active | `lib/features/onboarding/presentation/` | 7 steps, **BẮT BUỘC** giữ completion flow |
| **Dashboard** | ✅ Active | `lib/features/dashboard/presentation/` | Một số sections còn mock/fallback |
| **Meal Plan** | ✅ Active | `lib/features/meal_plan/presentation/` | 7 days, 5 meals/day, SQLite-backed |
| **Lifestyle Schedule** | ✅ Active | `lib/features/lifestyle_schedule/presentation/` | 70 items/7 days, completion sync |
| **AI Chat** | ✅ Active | `lib/features/ai_chat/presentation/` | In-memory history, Gemini chat |
| **Health Tracking** | ✅ Active | `lib/features/daily_health_tracking/presentation/` | Today tasks, progress |
| **Settings** | ⚠️ Partial | `lib/features/settings/presentation/` | UI hardcoded, chưa wire đủ |
| **Auth** | ✅ Active | `lib/features/auth/presentation/` | Supabase login works |
| **Profile, Nutrition, Sleep, Stress, Community** | ⚠️ Placeholder | `lib/features/*/presentation/` | UI partial hoặc placeholder |


### 1.5. Quy ước đặt tên

#### File naming
- **Pages**: `{feature}_page.dart` (VD: `onboarding_page.dart`, `dashboard_page.dart`)
- **Widgets**: `{feature}_widget.dart` hoặc `{component}_widget.dart`
- **Controllers**: `{feature}_controller.dart`
- **Providers**: `{feature}_provider.dart`
- **Models**: `{entity}_model.dart`

#### Class naming
- **Pages**: `{Feature}Page` (VD: `OnboardingPage`, `DashboardPage`)
- **Widgets**: `{Feature}{Component}` (VD: `OnboardingChip`, `OnboardingStepShell`)
- **Controllers**: `{Feature}Controller`
- **Providers**: `{feature}Provider`, `{feature}ControllerProvider`

#### Private widgets
- Prefix `_` cho widgets chỉ dùng nội bộ trong một file (VD: `_TopBar`, `_HeroHeader`, `_PrimaryButton`)

---

## 2. Phân tích cấu trúc UI hiện tại

### 2.1. Pattern tổ chức UI

**UI được chia theo Feature-first structure**:

```
lib/features/{feature_name}/
├── data/
│   ├── datasource/
│   └── models/
├── domain/
│   ├── entities/
│   └── repositories/
├── presentation/
│   ├── pages/          # Màn hình chính
│   ├── widgets/        # Widgets tái sử dụng trong feature
│   ├── controllers/    # State/business logic
│   └── constants/      # Constants cho feature
└── providers/          # Riverpod providers
```


### 2.2. Phân loại widgets

#### Shared Components (dùng chung toàn app)
- `lib/shared/widgets/ai_chat_fab.dart` - FAB để mở AI chat
- `lib/shared/widgets/loading_genAI.dart` - Loading indicator cho AI

#### Design System Primitives (components từ design system)
- `lib/core/theme/primitives/button.dart` - AppButton (primary, secondary, text, icon, outlined)
- `lib/core/theme/primitives/card.dart` - AppCard (default, elevated, outlined)
- `lib/core/theme/primitives/chip.dart` - AppChip (selectable, filter, action)
- `lib/core/theme/primitives/input.dart` - AppInput (textField, dropdown, search)
- `lib/core/theme/primitives/badge.dart` - AppBadge (status, count, dot)
- `lib/core/theme/primitives/section_header.dart` - SectionHeader (title + subtitle + action)

#### Feature-specific Components (chỉ dùng trong feature)
- **Onboarding**: 
  - `OnboardingStepShell` - Shell layout cho từng step
  - `OnboardingChip` - Custom chip với animation
  - `OnboardingTextField` - Custom text field
  - `HealthChip` - Chip với emoji và description
  
- **Dashboard**: Dashboard-specific cards và sections
- **Meal Plan**: Meal cards, nutrition display
- **Lifestyle Schedule**: Timeline items, completion UI

### 2.3. Pattern UI đang lặp lại

#### ✅ Patterns tốt đang dùng
1. **Shell pattern**: Wrapper widget chứa layout chung (VD: `OnboardingStepShell`)
2. **Composition over inheritance**: Xây dựng UI phức tạp từ widgets nhỏ
3. **Stateful animations**: Dùng AnimationController cho smooth transitions
4. **Glassmorphism**: BackdropFilter + blur cho premium feel
5. **Gradient emphasis**: Gradient cho selected states và premium features


#### ⚠️ Vấn đề cần chú ý
1. **Deprecated API**: Code đang dùng `.withOpacity()` thay vì `.withValues()` (Flutter deprecation)
2. **Mixed theme imports**: 
   - Old code: `import 'package:nano_app/core/theme/theme.dart'`
   - New code: `import 'package:nano_app/core/theme/design_system.dart'`
3. **Hardcoded values**: Vẫn còn một số nơi hardcode màu/spacing thay vì dùng tokens
4. **Inconsistent widget structure**: Một số widgets có description, một số không

### 2.4. Widgets nên tách thành reusable

**Đang làm tốt** - những thứ ĐÃ được tách:
- ✅ OnboardingChip - chip với emoji, gradient, animation
- ✅ OnboardingStepShell - shell layout với progress bar
- ✅ AppButton, AppCard, AppInput từ design system
- ✅ SectionHeader - header với title/subtitle/action

**Nên tách thêm** (nếu thấy lặp lại ≥3 lần):
- Progress indicator với percentage display
- Glass button (đang inline trong OnboardingStepShell)
- Animated floating orbs (đang inline)
- Empty state, Error state, Loading state (đã có trong design system primitives)

---

## 3. Phân tích Design System

### 3.1. Kiến trúc 3 lớp của Design System

BioAI sử dụng **Token-based Design System** với 3 lớp:

```
Layer 1: Foundation Tokens (Primitive values)
   ↓
Layer 2: Semantic Tokens (Meaningful names)
   ↓
Layer 3: Primitive Components (Reusable UI)
```

**⚠️ QUY TẮC VÀNG**:
- **LUÔN** dùng Layer 2 (Semantic Tokens)
- **KHÔNG BAO GIỜ** dùng trực tiếp Layer 1 (Foundation)
- **ƯU TIÊN** dùng Layer 3 (Primitive Components) khi có


### 3.2. Layer 1: Foundation Tokens (KHÔNG dùng trực tiếp)

#### Colors Foundation
**File**: `lib/core/theme/foundation/colors.dart`

Total: 28 color values

- **Brand Colors**: blue400, blue500, blue600, blue700, cyan400, cyan500, cyan600, purple500, purple600
- **Status Colors**: green500, green600, amber500, amber600, red500, red600, sky500, sky600
- **Neutral Slate**: slate50 → slate900 (10 values)
- **Pure**: white, black

**❌ KHÔNG dùng**: `ColorFoundation.blue500`
**✅ DÙNG**: `AppColorTokens.primary`

#### Spacing Foundation
**File**: `lib/core/theme/foundation/spacing.dart`

Base-8 system: `space0, space4, space8, space12, space16, space24, space32, space48, space64, space96`

**❌ KHÔNG dùng**: `SpacingFoundation.space16`
**✅ DÙNG**: `AppSpacingTokens.pagePadding`

#### Radius Foundation
**File**: `lib/core/theme/foundation/radius.dart`

Values: `radius0, radius4, radius8, radius12, radius16, radius24, radiusFull`

**❌ KHÔNG dùng**: `RadiusFoundation.radius12`
**✅ DÙNG**: `AppRadiusTokens.button`

#### Shadow Foundation
**File**: `lib/core/theme/foundation/shadows.dart`

Values: `shadowXs, shadowSm, shadowMd, shadowLg, shadowXl` (light & dark variants)

**❌ KHÔNG dùng**: `ShadowFoundation.shadowSm`
**✅ DÙNG**: `AppShadowTokens.card`

#### Typography Foundation
**File**: `lib/core/theme/foundation/typography.dart`

Font sizes: `size12, size14, size16, size20, size24, size32`
Weights: `regular (400), medium (500), semibold (600), bold (700)`
Line heights: `lineHeightTight (1.2), lineHeightNormal (1.4), lineHeightRelaxed (1.6)`

**❌ KHÔNG dùng**: Foundation typography values
**✅ DÙNG**: `AppTextStyles.heading1`, `AppTextStyles.bodyMedium`


### 3.3. Layer 2: Semantic Tokens (LUÔN dùng layer này)

#### AppColorTokens ⭐ BẮT BUỘC
**File**: `lib/core/theme/tokens/color_tokens.dart`

**Brand Colors**:
```dart
AppColorTokens.primary          // Main brand color (blue)
AppColorTokens.primaryHover     // Hover state
AppColorTokens.secondary        // Secondary accent (cyan)
AppColorTokens.tertiary         // Premium/special (purple)
```

**Surface Colors**:
```dart
AppColorTokens.background          // Main app background
AppColorTokens.surface             // Cards, sheets
AppColorTokens.surfaceElevated     // Elevated surfaces

// Dark mode
AppColorTokens.darkBackground
AppColorTokens.darkSurface
AppColorTokens.darkSurfaceElevated
```

**Text Colors**:
```dart
AppColorTokens.textPrimary       // Main content text
AppColorTokens.textSecondary     // Supporting text
AppColorTokens.textMuted         // Captions, hints
AppColorTokens.textInverse       // Text on dark/colored bg

// Dark mode
AppColorTokens.darkTextPrimary
AppColorTokens.darkTextSecondary
AppColorTokens.darkTextMuted
```

**Border Colors**:
```dart
AppColorTokens.border            // Default borders
AppColorTokens.borderStrong      // Emphasized borders

// Dark mode
AppColorTokens.darkBorder
AppColorTokens.darkBorderStrong
```

**Status Colors**:
```dart
AppColorTokens.success           // Success states
AppColorTokens.warning           // Warning states
AppColorTokens.error             // Error states
AppColorTokens.info              // Info states

// Light backgrounds for badges
AppColorTokens.successLight
AppColorTokens.warningLight
AppColorTokens.errorLight
AppColorTokens.infoLight
AppColorTokens.primaryLight
```


**Cách dùng với Dark Mode**:
```dart
// ✅ ĐÚNG - Check theme brightness
final isDark = Theme.of(context).brightness == Brightness.dark;
final textColor = isDark 
    ? AppColorTokens.darkTextPrimary 
    : AppColorTokens.textPrimary;

// ❌ SAI - Hardcode color
final textColor = Color(0xFF0F172A);
```

#### AppSpacingTokens ⭐ BẮT BUỘC
**File**: `lib/core/theme/tokens/spacing_tokens.dart`

**Semantic spacing names**:
```dart
// Page/Section
AppSpacingTokens.pagePadding              // 16px - page horizontal padding
AppSpacingTokens.sectionSpacing           // 24px - between sections
AppSpacingTokens.sectionSpacingLarge      // 32px - large section gaps

// Card
AppSpacingTokens.cardPadding              // 16px - default card padding
AppSpacingTokens.cardPaddingLarge         // 24px - large card padding

// Item/Element
AppSpacingTokens.itemSpacing              // 8px - between list items
AppSpacingTokens.itemSpacingLarge         // 16px - larger gaps

// Button
AppSpacingTokens.buttonPaddingH           // Horizontal padding
AppSpacingTokens.buttonPaddingV           // Vertical padding
AppSpacingTokens.buttonMinHeight          // 48px - min touch target

// Input
AppSpacingTokens.inputPaddingH            // Input horizontal padding
AppSpacingTokens.inputPaddingV            // Input vertical padding
AppSpacingTokens.inputMinHeight           // 56px - min input height

// Touch Targets
AppSpacingTokens.touchTargetMin           // 48px - min touch target size
```

**Ví dụ sử dụng**:
```dart
// ✅ ĐÚNG
Padding(
  padding: EdgeInsets.all(AppSpacingTokens.pagePadding),
  child: Column(
    children: [
      Text('Title'),
      SizedBox(height: AppSpacingTokens.sectionSpacing),
      Text('Content'),
    ],
  ),
)

// ❌ SAI - Hardcode spacing
Padding(
  padding: EdgeInsets.all(16),
  child: Column(
    children: [
      Text('Title'),
      SizedBox(height: 24),
      Text('Content'),
    ],
  ),
)
```


#### AppRadiusTokens ⭐ BẮT BUỘC
**File**: `lib/core/theme/tokens/component_tokens.dart`

```dart
AppRadiusTokens.button      // 12px - buttons
AppRadiusTokens.card        // 16px - cards
AppRadiusTokens.input       // 12px - input fields
AppRadiusTokens.chip        // 8px - chips
AppRadiusTokens.badge       // 9999px - circular badges
AppRadiusTokens.dialog      // 24px - dialogs/modals
AppRadiusTokens.avatar      // 9999px - circular avatars
```

**Ví dụ**:
```dart
// ✅ ĐÚNG
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppRadiusTokens.card),
  ),
)

// ❌ SAI
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(16),
  ),
)
```

#### AppShadowTokens
**File**: `lib/core/theme/tokens/component_tokens.dart`

```dart
AppShadowTokens.card              // Default card shadow (light)
AppShadowTokens.cardDark          // Card shadow (dark mode)
AppShadowTokens.cardElevated      // Elevated card (light)
AppShadowTokens.cardElevatedDark  // Elevated card (dark)
AppShadowTokens.dialog            // Dialog/modal shadow
AppShadowTokens.button            // Button shadow
```

**Ví dụ với dark mode**:
```dart
// ✅ ĐÚNG
final isDark = Theme.of(context).brightness == Brightness.dark;
Container(
  decoration: BoxDecoration(
    boxShadow: isDark 
        ? AppShadowTokens.cardDark 
        : AppShadowTokens.card,
  ),
)
```


#### AppMotionTokens
**File**: `lib/core/theme/tokens/component_tokens.dart`

```dart
AppMotionTokens.button       // 150ms - button interactions
AppMotionTokens.card         // 250ms - card transitions
AppMotionTokens.dialog       // 250ms - dialog animations
AppMotionTokens.page         // 350ms - page transitions
AppMotionTokens.defaultCurve // Curves.easeInOut
```

#### AppTextStyles ⭐ BẮT BUỘC
**File**: `lib/core/theme/tokens/component_tokens.dart`

```dart
// Display
AppTextStyles.displayLarge    // 32px, bold - hero headlines

// Headings
AppTextStyles.heading1        // 24px, bold - page titles
AppTextStyles.heading2        // 20px, semibold - section headers

// Body
AppTextStyles.bodyLarge       // 16px, regular - primary body text
AppTextStyles.bodyMedium      // 14px, regular - secondary body text

// Labels
AppTextStyles.labelLarge      // 14px, semibold - button labels
AppTextStyles.labelMedium     // 12px, semibold - chip labels

// Caption
AppTextStyles.caption         // 12px, regular - supplementary info
```

**Ví dụ apply color**:
```dart
// ✅ ĐÚNG - Apply color với copyWith
Text(
  'Hello',
  style: AppTextStyles.heading1.copyWith(
    color: AppColorTokens.textPrimary,
  ),
)

// ❌ SAI - Hardcode style
Text(
  'Hello',
  style: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  ),
)
```


### 3.4. Backward-Compatible Theme (Legacy - đang được migrate)

#### AppColors (Legacy)
**File**: `lib/core/theme/app_colors.dart`

**⚠️ LƯU Ý**: Đây là legacy system. Code cũ đang dùng, code mới NÊN dùng `AppColorTokens` từ design system.

```dart
// Brand
AppColors.primary
AppColors.primaryDark
AppColors.primaryLight
AppColors.secondary

// Status
AppColors.success
AppColors.warning
AppColors.error
AppColors.info

// Surface
AppColors.background
AppColors.surface
AppColors.card

// Text
AppColors.textPrimary
AppColors.textSecondary
AppColors.textMuted
AppColors.textHint

// Border
AppColors.border
AppColors.divider
```

**Migration Path**:
- Existing code: Có thể tiếp tục dùng `AppColors`
- New code: NÊN dùng `AppColorTokens` từ `design_system.dart`
- Refactoring: CHỈ refactor khi được yêu cầu rõ ràng

#### AppSpacing, AppRadius, AppShadows, AppGradients (Legacy)
**Files**: 
- `lib/core/theme/app_spacing.dart`
- `lib/core/theme/app_radius.dart`
- `lib/core/theme/app_shadows.dart`
- `lib/core/theme/app_gradients.dart`

**Cách import**:
```dart
// Legacy way (đang dùng trong code cũ)
import 'package:nano_app/core/theme/theme.dart';

// New way (ưu tiên cho code mới)
import 'package:nano_app/core/theme/design_system.dart';
```


### 3.5. Layer 3: Primitive Components ⭐ ƯU TIÊN DÙNG

#### AppButton
**File**: `lib/core/theme/primitives/button.dart`

**Variants**:
- `ButtonVariant.primary` - Main CTA with filled background
- `ButtonVariant.secondary` - Secondary actions with subtle styling
- `ButtonVariant.text` - Tertiary actions, text-only
- `ButtonVariant.icon` - Icon-only compact buttons
- `ButtonVariant.outlined` - Border-emphasized buttons

**Usage**:
```dart
// Primary button
AppButton(
  variant: ButtonVariant.primary,
  onPressed: () {},
  child: Text('Save'),
)

// Loading state
AppButton(
  variant: ButtonVariant.primary,
  onPressed: () {},
  loading: true,
  child: Text('Save'),
)

// Disabled
AppButton(
  variant: ButtonVariant.primary,
  onPressed: null, // null = disabled
  child: Text('Save'),
)

// Icon button
AppButton(
  variant: ButtonVariant.icon,
  onPressed: () {},
  icon: Icons.favorite,
)
```

**⭐ KHI NÀO DÙNG**:
- ✅ LUÔN dùng AppButton cho buttons mới
- ✅ Dùng cho forms, CTAs, navigation
- ❌ KHÔNG tạo custom button nếu AppButton đáp ứng được


#### AppCard
**File**: `lib/core/theme/primitives/card.dart`

**Variants**:
- `CardVariant.defaultCard` - Standard card with shadow
- `CardVariant.elevated` - Emphasized card with more shadow
- `CardVariant.outlined` - Border-based card, no shadow

**Usage**:
```dart
// Default card
AppCard(
  variant: CardVariant.defaultCard,
  child: Column(
    children: [
      Text('Title'),
      Text('Content'),
    ],
  ),
)

// Interactive card
AppCard(
  variant: CardVariant.defaultCard,
  onTap: () {
    // Navigate or action
  },
  child: Text('Tap me'),
)

// Custom padding
AppCard(
  variant: CardVariant.defaultCard,
  padding: EdgeInsets.all(24),
  child: Text('Custom padding'),
)

// No padding
AppCard(
  variant: CardVariant.defaultCard,
  padding: EdgeInsets.zero,
  child: Image.network('...'),
)
```

**⭐ KHI NÀO DÙNG**:
- ✅ Container cho content groups
- ✅ List items cần elevation
- ✅ Information panels
- ❌ KHÔNG dùng cho buttons


#### AppInput
**File**: `lib/core/theme/primitives/input.dart`

**Variants**:
- `InputVariant.textField` - Standard text input
- `InputVariant.dropdown` - Dropdown selection
- `InputVariant.search` - Search input with icon

**Usage**:
```dart
// Text field
AppInput(
  variant: InputVariant.textField,
  label: 'Full Name',
  hint: 'Enter your full name',
  controller: nameController,
)

// Search
AppInput(
  variant: InputVariant.search,
  hint: 'Search meals...',
  controller: searchController,
  onChanged: (value) {
    // Handle search
  },
)

// Error state
AppInput(
  variant: InputVariant.textField,
  label: 'Email',
  errorText: 'Invalid email format',
  controller: emailController,
)

// Password field
AppInput(
  variant: InputVariant.textField,
  label: 'Password',
  obscureText: true,
  controller: passwordController,
)

// Multiline
AppInput(
  variant: InputVariant.textField,
  label: 'Notes',
  maxLines: 4,
  controller: notesController,
)
```

**⭐ KHI NÀO DÙNG**:
- ✅ LUÔN dùng cho text inputs mới
- ✅ Forms, search bars
- ❌ KHÔNG tạo custom TextField nếu AppInput đủ


#### SectionHeader
**File**: `lib/core/theme/primitives/section_header.dart`

**Usage**:
```dart
// Basic
SectionHeader(
  title: 'Health Goals',
)

// With subtitle
SectionHeader(
  title: 'Meal Plan',
  subtitle: '7-day personalized nutrition plan',
)

// With action
SectionHeader(
  title: 'Recent Activities',
  actionLabel: 'View All',
  onAction: () {
    // Navigate
  },
)
```

**⭐ KHI NÀO DÙNG**:
- ✅ Đầu mỗi section trong page
- ✅ Khi cần consistent header style
- ❌ KHÔNG dùng cho page title (dùng AppBar)

#### Empty State, Loading State, Error State
**Files**: 
- `lib/core/theme/primitives/states/empty_state.dart`
- `lib/core/theme/primitives/states/loading_state.dart`
- `lib/core/theme/primitives/states/error_state.dart`

**⭐ QUAN TRỌNG**: Đây là primitives đã có sẵn trong design system. **BẮT BUỘC** dùng khi cần hiển thị trạng thái empty/loading/error.

---

## 4. Phân tích chi tiết các file quan trọng

### 4.1. Onboarding Feature (Ví dụ mẫu)

#### OnboardingPage
**File**: `lib/features/onboarding/presentation/pages/onboarding_page.dart`

| Thuộc tính | Giá trị |
|------------|---------|
| Loại | Page (ConsumerWidget) |
| Mục đích | Điều phối 7 steps của onboarding |
| State management | Riverpod (onboardingProvider) |
| Animation | AnimatedSwitcher (260ms) |
| Phụ thuộc | onboardingProvider, step widgets |
| Được dùng ở | Route `/onboarding` |
| Có thể tái sử dụng | ❌ Không - specific cho onboarding flow |
| Lưu ý | **KHÔNG** sửa step navigation logic, **KHÔNG** xóa completion callback |


#### OnboardingStepShell
**File**: `lib/features/onboarding/presentation/widgets/onboarding_step_shell.dart`

| Thuộc tính | Giá trị |
|------------|---------|
| Loại | Widget (StatefulWidget) |
| Mục đích | Shell layout cho mỗi onboarding step |
| Features | Progress bar, glassmorphism hero header, animated background, floating orbs |
| Input | stepIndex, totalSteps, title, subtitle, child, footer, callbacks |
| Animations | Background (18s), floating orbs (6s), fade-slide-in stagger |
| Phụ thuộc | AppColors, AppSpacing, AppRadius, AppGradients, AppAnimations |
| Được dùng ở | Tất cả onboarding steps |
| Có thể tái sử dụng | ⚠️ Partial - có thể adapt cho multi-step flows khác |
| Lưu ý | **KHÔNG** phá animation controllers, glassmorphism effects là signature style |

**Private widgets trong file**:
- `_HeroHeader` - Glass card with progress
- `_TopBar` - Step indicator with progress bar
- `_PrimaryButton` - Animated gradient button
- `_GlassButton` - Glass-effect back button
- `_FadeSlideIn` - Stagger animation wrapper
- `_FloatingOrb` - Animated gradient orb
- `_BackgroundPainter` - Animated gradient grid background


#### OnboardingChip
**File**: `lib/features/onboarding/presentation/widgets/onboarding_chip.dart`

| Thuộc tính | Giá trị |
|------------|---------|
| Loại | Widget (StatefulWidget) |
| Mục đích | Selectable chip với emoji, gradient khi selected |
| Features | Hover, press animation, scale transform, gradient background |
| Input | label, emoji, selected, onTap, description (optional), icon (optional) |
| Animations | Scale on press (AnimationController), color/gradient transition |
| States | enabled, hovered, pressed, selected |
| Phụ thuộc | AppColors, AppSpacing, AppRadius, AppGradients, AppDecoration |
| Được dùng ở | Goals, Conditions, Lifestyle steps |
| Có thể tái sử dụng | ✅ Có thể - reusable cho selection UI |
| Lưu ý | **KHÔNG** remove animations, gradient là key visual identity |

**Private widgets**:
- `_LeadingSection` - Emoji container with gradient
- `_SelectionIndicator` - Checkmark with glass effect

**Key Pattern**: Sử dụng `AnimationController` với `lowerBound: 0.965, upperBound: 1` để tạo subtle press effect.

---

## 5. Bộ luật thiết kế UI bắt buộc

### 5.1. Luật sử dụng Theme ⭐ QUAN TRỌNG NHẤT

#### ✅ DO - Phải làm

```dart
// ✅ Dùng semantic tokens
Container(
  color: AppColorTokens.surface,
  padding: EdgeInsets.all(AppSpacingTokens.pagePadding),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppRadiusTokens.card),
    boxShadow: AppShadowTokens.card,
  ),
)

// ✅ Dùng text styles
Text(
  'Hello',
  style: AppTextStyles.heading1.copyWith(
    color: AppColorTokens.textPrimary,
  ),
)

// ✅ Check dark mode
final isDark = Theme.of(context).brightness == Brightness.dark;
final color = isDark 
    ? AppColorTokens.darkTextPrimary 
    : AppColorTokens.textPrimary;

// ✅ Dùng motion tokens
AnimatedContainer(
  duration: AppMotionTokens.card,
  curve: AppMotionTokens.defaultCurve,
  // ...
)
```


#### ❌ DON'T - Không được làm

```dart
// ❌ Hardcode colors
Container(
  color: Color(0xFFFFFFFF),
  child: Text(
    'Hello',
    style: TextStyle(color: Color(0xFF0F172A)),
  ),
)

// ❌ Hardcode spacing
Padding(
  padding: EdgeInsets.all(16),
  child: SizedBox(height: 24),
)

// ❌ Hardcode radius
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(12),
  ),
)

// ❌ Hardcode text styles
Text(
  'Hello',
  style: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  ),
)

// ❌ Dùng Foundation tokens trực tiếp
color: ColorFoundation.blue500  // WRONG!
color: AppColorTokens.primary   // CORRECT!

// ❌ Deprecated API
color: Colors.blue.withOpacity(0.5)         // DEPRECATED!
color: Colors.blue.withValues(alpha: 0.5)   // CORRECT!
```

### 5.2. Luật Layout

#### Padding và Margin
```dart
// ✅ Dùng semantic spacing
Padding(
  padding: EdgeInsets.symmetric(
    horizontal: AppSpacingTokens.pagePadding,
    vertical: AppSpacingTokens.sectionSpacing,
  ),
)

// ✅ Vertical spacing giữa elements
Column(
  children: [
    Widget1(),
    SizedBox(height: AppSpacingTokens.itemSpacing),
    Widget2(),
    SizedBox(height: AppSpacingTokens.sectionSpacing),
    Widget3(),
  ],
)
```


#### Responsive và Screen Size
```dart
// ✅ Dùng MediaQuery cho responsive
final screenWidth = MediaQuery.of(context).size.width;
final isMobile = screenWidth < 600;

// ✅ Constraints cho max width
Container(
  constraints: BoxConstraints(maxWidth: 600),
  child: content,
)

// ✅ Flexible/Expanded trong Row/Column
Row(
  children: [
    Icon(Icons.star),
    SizedBox(width: AppSpacingTokens.itemSpacing),
    Expanded(child: Text('Long text...')),
  ],
)
```

#### Tránh Overflow
```dart
// ✅ SingleChildScrollView cho scrollable content
SingleChildScrollView(
  physics: BouncingScrollPhysics(),
  child: Column(
    children: [
      // Long content
    ],
  ),
)

// ✅ ListView.builder cho danh sách
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ItemWidget(items[index]);
  },
)

// ✅ Text overflow handling
Text(
  'Very long text...',
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
)
```

#### SafeArea và Keyboard
```dart
// ✅ SafeArea cho tránh notch/status bar
Scaffold(
  body: SafeArea(
    child: content,
  ),
)

// ✅ Keyboard handling
Scaffold(
  resizeToAvoidBottomInset: true,  // Mặc định là true
  body: SingleChildScrollView(
    child: Form(
      child: Column(
        children: [
          // Input fields
        ],
      ),
    ),
  ),
)
```


### 5.3. Luật Component

#### Khi nào phải tách widget
**BẮT BUỘC tách khi**:
1. Widget lặp lại ≥ 3 lần
2. Widget > 150 lines
3. Widget có logic phức tạp riêng
4. Widget cần reusable across features

**Ví dụ tách widget**:
```dart
// ❌ BAD - Inline phức tạp
Column(
  children: [
    Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Title', style: AppTextStyles.heading3),
                Text('Subtitle', style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          Icon(Icons.arrow_forward),
        ],
      ),
    ),
    // Lặp lại 3 lần...
  ],
)

// ✅ GOOD - Tách thành widget
class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: CardVariant.defaultCard,
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon),
          SizedBox(width: AppSpacingTokens.itemSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.heading3),
                Text(subtitle, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          Icon(Icons.arrow_forward),
        ],
      ),
    );
  }
}
```


#### Khi nào KHÔNG nên tách widget
- Widget chỉ dùng 1-2 lần
- Widget quá simple (< 20 lines)
- Widget chỉ là layout wrapper đơn giản

#### Đặt tên widget
```dart
// ✅ GOOD naming
OnboardingChip           // Feature-specific
HealthGoalCard           // Clear purpose
MealPlanListItem         // Context + type
_PrivateButton           // Private widget

// ❌ BAD naming
MyWidget                 // Vague
Widget1                  // No meaning
CustomThing              // Unclear
```

#### Stateless vs Stateful
```dart
// ✅ Stateless khi KHÔNG cần local state
class HealthCard extends StatelessWidget {
  final String title;
  final String value;
  
  const HealthCard({
    super.key,
    required this.title,
    required this.value,
  });
  
  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: CardVariant.defaultCard,
      child: Column(
        children: [
          Text(title),
          Text(value),
        ],
      ),
    );
  }
}

// ✅ Stateful khi CẦN animation hoặc local state
class AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  
  const AnimatedButton({super.key, required this.onPressed});
  
  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _hovered = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotionTokens.button,
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // ... animation logic
  }
}
```


### 5.4. Luật State Management

#### UI không xử lý business logic
```dart
// ❌ BAD - Business logic trong UI
class DashboardPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        // ❌ WRONG - API call trong UI
        final response = await http.get('...');
        final data = json.decode(response.body);
        await database.insert(data);
      },
      child: Text('Save'),
    );
  }
}

// ✅ GOOD - Gọi controller/provider
class DashboardPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(dashboardControllerProvider.notifier);
    
    return AppButton(
      variant: ButtonVariant.primary,
      onPressed: () {
        // ✅ CORRECT - Delegate to controller
        controller.saveDashboardData();
      },
      child: Text('Save'),
    );
  }
}
```

#### Page gọi Controller/Provider
```dart
// ✅ Watch provider state
class MealPlanPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mealPlanProvider);
    
    return state.when(
      data: (meals) => MealPlanList(meals: meals),
      loading: () => LoadingState(variant: LoadingVariant.spinner),
      error: (error, stack) => ErrorState(
        message: error.toString(),
        onRetry: () {
          ref.invalidate(mealPlanProvider);
        },
      ),
    );
  }
}

// ✅ Call controller methods
class OnboardingPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(onboardingProvider.notifier);
    
    return AppButton(
      variant: ButtonVariant.primary,
      onPressed: () {
        controller.nextStep();
      },
      child: Text('Continue'),
    );
  }
}
```


#### Widget con chỉ nhận data/callback
```dart
// ✅ GOOD - Props-based widget
class MealCard extends StatelessWidget {
  final String mealName;
  final String calories;
  final VoidCallback onTap;
  
  const MealCard({
    super.key,
    required this.mealName,
    required this.calories,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: CardVariant.defaultCard,
      onTap: onTap,
      child: Column(
        children: [
          Text(mealName, style: AppTextStyles.heading3),
          Text('$calories kcal', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

// ❌ BAD - Widget tự access provider
class MealCard extends ConsumerWidget {
  final String mealId;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ❌ WRONG - Không nên access provider trong widget con
    final meal = ref.watch(mealProvider(mealId));
    // ...
  }
}
```

#### Không đổi tên Provider/Controller public API
```dart
// ✅ GOOD - Giữ nguyên tên provider
final onboardingProvider = 
    StateNotifierProvider<OnboardingController, OnboardingState>(...);

final dashboardControllerProvider = 
    AsyncNotifierProvider<DashboardController, DashboardEntity>(...);

// ❌ BAD - Đổi tên provider đang được dùng
// KHÔNG làm điều này nếu chưa được yêu cầu!
```

### 5.5. Luật Copywriting UI

#### Nguyên tắc chung
- **Ngắn gọn**: Tối đa 1-2 câu cho description
- **Thân thiện**: Dùng "bạn" thay vì "người dùng"
- **Dễ hiểu**: Tránh thuật ngữ kỹ thuật
- **Không máy móc**: Tránh câu văn cứng nhắc
- **Không gây áp lực**: Không dùng "phải", "bắt buộc" trừ khi thật sự required


#### Ứng dụng sức khỏe - Giọng văn đặc biệt
```dart
// ✅ GOOD - Nhẹ nhàng, quan tâm
'Hãy cho chúng tôi biết về mục tiêu sức khỏe của bạn'
'Bạn có thể chia sẻ thêm về tình trạng sức khỏe không?'
'Tuyệt vời! Bạn đang làm rất tốt'
'Đừng lo, chúng tôi sẽ giúp bạn'

// ❌ BAD - Máy móc, lạnh lùng
'Nhập mục tiêu sức khỏe'
'Khai báo tình trạng bệnh lý'
'Dữ liệu không hợp lệ'
'Bạn phải hoàn thành bước này'

// ✅ GOOD - Không phán xét
'Hôm nay bạn cảm thấy thế nào?'
'Bạn muốn điều chỉnh kế hoạch không?'

// ❌ BAD - Phán xét
'Tại sao bạn không hoàn thành?'
'Bạn đã bỏ qua quá nhiều'
```

#### Button labels
```dart
// ✅ GOOD
'Tiếp tục'
'Xem thêm'
'Lưu thay đổi'
'Thử lại'
'Đồng ý'

// ❌ BAD
'Next' (English trong app Tiếng Việt)
'Submit' (quá kỹ thuật)
'OK' (quá ngắn gọn)
```

### 5.6. Luật Animation/Motion

#### Khi nào dùng animation
- ✅ State transitions (loading → success)
- ✅ Page/screen transitions
- ✅ User interactions (button press, selection)
- ✅ Feedback (success, error)
- ❌ KHÔNG animation mọi thứ

#### Duration chuẩn
```dart
// ✅ Dùng motion tokens
AnimatedContainer(
  duration: AppMotionTokens.button,    // 150ms - fast feedback
  duration: AppMotionTokens.card,      // 250ms - normal
  duration: AppMotionTokens.page,      // 350ms - slower for big changes
)

// ✅ Từ legacy system
AnimatedContainer(
  duration: AppDuration.fast,     // 200ms
  duration: AppDuration.normal,   // 350ms
  duration: AppDuration.slow,     // 600ms
)
```


#### Curve chuẩn
```dart
// ✅ Dùng từ tokens
curve: AppMotionTokens.defaultCurve       // easeInOut

// ✅ Từ legacy system
curve: AppAnimations.smoothCurve          // fastOutSlowIn
curve: AppAnimations.emphasizedCurve      // easeInOutCubic
curve: AppAnimations.decelerateCurve      // easeOutCubic
```

#### Animation helpers
```dart
// ✅ Dùng AppAnimations helpers
AppAnimations.fadeSlide(
  child: widget,
  animation: animation,
)

AppAnimations.fadeScale(
  child: widget,
  animation: animation,
)

// ✅ AnimatedSwitcher
AnimatedSwitcher(
  duration: AppMotionTokens.card,
  child: currentWidget,
)
```

#### Không lạm dụng animation
```dart
// ❌ BAD - Quá nhiều animation
AnimatedContainer(
  duration: Duration(milliseconds: 200),
  child: AnimatedOpacity(
    duration: Duration(milliseconds: 200),
    child: AnimatedScale(
      duration: Duration(milliseconds: 200),
      child: AnimatedRotation(
        duration: Duration(milliseconds: 200),
        child: Text('Hello'),
      ),
    ),
  ),
)

// ✅ GOOD - Vừa đủ
AnimatedContainer(
  duration: AppMotionTokens.card,
  curve: AppMotionTokens.defaultCurve,
  decoration: BoxDecoration(
    color: isSelected ? AppColorTokens.primary : AppColorTokens.surface,
  ),
  child: Text('Hello'),
)
```

### 5.7. Luật Form/Input/Selectbox

#### TextField validation
```dart
// ✅ GOOD - Hiển thị error rõ ràng
AppInput(
  variant: InputVariant.textField,
  label: 'Email',
  controller: emailController,
  errorText: emailError,  // Set khi validate fail
  keyboardType: TextInputType.emailAddress,
)

// ✅ Helper text
AppInput(
  variant: InputVariant.textField,
  label: 'Password',
  hint: 'Tối thiểu 8 ký tự',
  obscureText: true,
)
```


#### Chip/Selectbox thay vì nhập tay
```dart
// ✅ GOOD - Dùng chip cho options có sẵn
Wrap(
  spacing: AppSpacingTokens.itemSpacing,
  runSpacing: AppSpacingTokens.itemSpacing,
  children: goals.map((goal) {
    return OnboardingChip(
      label: goal.name,
      emoji: goal.emoji,
      selected: selectedGoals.contains(goal.id),
      onTap: () => toggleGoal(goal.id),
    );
  }).toList(),
)

// ⚠️ OK - TextField cho custom input
AppInput(
  variant: InputVariant.textField,
  label: 'Mục tiêu khác (nếu có)',
  hint: 'Nhập mục tiêu của bạn',
)
```

#### Empty, Loading, Disabled states
```dart
// ✅ Empty state
if (items.isEmpty) {
  return EmptyState(
    icon: Icons.inbox,
    title: 'Chưa có dữ liệu',
    description: 'Hãy thêm mục tiêu đầu tiên của bạn',
    actionLabel: 'Thêm mục tiêu',
    onAction: () {},
  );
}

// ✅ Loading state
if (isLoading) {
  return LoadingState(variant: LoadingVariant.spinner);
}

// ✅ Disabled button
AppButton(
  variant: ButtonVariant.primary,
  onPressed: isValid ? onSave : null,  // null = disabled
  child: Text('Save'),
)
```

### 5.8. Luật Loading/Error/Empty State

#### Loading states
```dart
// ✅ Toàn trang
Scaffold(
  body: Center(
    child: LoadingState(variant: LoadingVariant.spinner),
  ),
)

// ✅ Từng section
Column(
  children: [
    SectionHeader(title: 'Meal Plan'),
    isLoading 
        ? LoadingState(variant: LoadingVariant.spinner)
        : MealPlanList(meals: meals),
  ],
)

// ✅ Button loading
AppButton(
  variant: ButtonVariant.primary,
  onPressed: onSave,
  loading: isSaving,
  child: Text('Save'),
)
```


#### Error states
```dart
// ✅ Error với retry
ErrorState(
  message: 'Không thể tải dữ liệu',
  onRetry: () {
    ref.invalidate(mealPlanProvider);
  },
)

// ✅ AsyncValue error handling
final state = ref.watch(mealPlanProvider);

return state.when(
  data: (meals) => MealPlanList(meals: meals),
  loading: () => LoadingState(variant: LoadingVariant.spinner),
  error: (error, stack) => ErrorState(
    message: 'Không thể tải kế hoạch ăn uống',
    onRetry: () => ref.invalidate(mealPlanProvider),
  ),
);
```

#### Empty states
```dart
// ✅ Empty với action
EmptyState(
  icon: Icons.restaurant_menu,
  title: 'Chưa có kế hoạch ăn uống',
  description: 'Hãy tạo kế hoạch đầu tiên cho bạn',
  actionLabel: 'Tạo kế hoạch',
  onAction: () => context.push('/meal-plan/create'),
)

// ✅ Empty không action (chỉ thông báo)
EmptyState(
  icon: Icons.check_circle,
  title: 'Hoàn thành!',
  description: 'Bạn đã hoàn thành tất cả nhiệm vụ',
)
```

#### Câu chữ thông báo lỗi
```dart
// ✅ GOOD - Thân thiện, hướng dẫn
'Không thể tải dữ liệu. Vui lòng thử lại.'
'Đã có lỗi xảy ra. Hãy kiểm tra kết nối mạng.'
'Email không hợp lệ. Vui lòng kiểm tra lại.'

// ❌ BAD - Máy móc, kỹ thuật
'Error 500: Internal Server Error'
'Network exception occurred'
'Validation failed'
```

### 5.9. Luật Accessibility

#### Font size dễ đọc
```dart
// ✅ GOOD - Dùng text styles với size phù hợp
Text('Title', style: AppTextStyles.heading1)      // 24px
Text('Body', style: AppTextStyles.bodyMedium)     // 14px
Text('Caption', style: AppTextStyles.caption)     // 12px

// ❌ BAD - Quá nhỏ
Text('Important info', style: TextStyle(fontSize: 8))
```


#### Touch target
```dart
// ✅ GOOD - Min 48x48 dp
AppButton(
  variant: ButtonVariant.primary,
  onPressed: () {},
  child: Text('Button'),
)
// AppButton tự động có minHeight = 48px

// ✅ Icon button với padding
IconButton(
  iconSize: 24,
  padding: EdgeInsets.all(12),  // Total = 48x48
  onPressed: () {},
  icon: Icon(Icons.favorite),
)

// ❌ BAD - Quá nhỏ
GestureDetector(
  onTap: () {},
  child: Icon(Icons.close, size: 16),  // Quá nhỏ để tap
)
```

#### Contrast màu
```dart
// ✅ GOOD - Contrast tốt
Text(
  'Important',
  style: AppTextStyles.bodyMedium.copyWith(
    color: AppColorTokens.textPrimary,  // Dark on light
  ),
)

// ⚠️ WARNING - Cần kiểm tra contrast
Text(
  'Subtle',
  style: AppTextStyles.bodyMedium.copyWith(
    color: AppColorTokens.textMuted,  // Lower contrast
  ),
)
```

#### Semantic labels
```dart
// ✅ GOOD - Có semantics cho screen readers
Semantics(
  label: 'Đóng hộp thoại',
  button: true,
  child: IconButton(
    icon: Icon(Icons.close),
    onPressed: () => Navigator.pop(context),
  ),
)

// ✅ Image semantics
Semantics(
  label: 'Avatar của người dùng',
  image: true,
  child: CircleAvatar(
    backgroundImage: NetworkImage(avatarUrl),
  ),
)
```

---

## 6. Bộ luật "Không được làm"

### 6.1. Architecture

- ❌ **KHÔNG** phá kiến trúc Feature-first structure
- ❌ **KHÔNG** move files ra khỏi feature folders
- ❌ **KHÔNG** gộp nhiều features vào một folder
- ❌ **KHÔNG** tạo "utils" folder to chứa mọi thứ


### 6.2. Navigation và Routes

- ❌ **KHÔNG** đổi route names trong `route_names.dart`
- ❌ **KHÔNG** xóa routes hiện có
- ❌ **KHÔNG** thay đổi auth guards nếu chưa được yêu cầu
- ❌ **KHÔNG** hard-code navigation paths (dùng constants)

### 6.3. State Management

- ❌ **KHÔNG** đổi tên provider/controller public API
- ❌ **KHÔNG** xóa callback/provider hiện có
- ❌ **KHÔNG** thay đổi provider type (StateNotifier → Notifier) nếu chưa yêu cầu
- ❌ **KHÔNG** gọi API/database trực tiếp từ widget
- ❌ **KHÔNG** phá onboarding completion callback flow

### 6.4. Theme và Design System

- ❌ **KHÔNG** hardcode colors, spacing, radius, shadows
- ❌ **KHÔNG** dùng Foundation tokens trực tiếp
- ❌ **KHÔNG** tạo custom text styles nếu AppTextStyles đủ
- ❌ **KHÔNG** tạo custom buttons nếu AppButton đủ
- ❌ **KHÔNG** copy-paste theme values
- ❌ **KHÔNG** dùng deprecated API (`.withOpacity()` → `.withValues()`)

### 6.5. Components

- ❌ **KHÔNG** copy component giống nhau nhiều nơi
- ❌ **KHÔNG** tạo file mới nếu có thể tái sử dụng file cũ
- ❌ **KHÔNG** viết inline style tràn lan
- ❌ **KHÔNG** tạo widget khi có sẵn primitive component
- ❌ **KHÔNG** duplicate logic đã có trong shared/widgets

### 6.6. UI Quality

- ❌ **KHÔNG** làm UI đẹp nhưng phá logic
- ❌ **KHÔNG** làm logic chạy được nhưng UI lệch design system
- ❌ **KHÔNG** bỏ qua responsive
- ❌ **KHÔNG** bỏ qua loading/error/empty states
- ❌ **KHÔNG** để màn hình trắng không giải thích
- ❌ **KHÔNG** tạo overflow không xử lý

### 6.7. Business Logic

- ❌ **KHÔNG** thay đổi meal plan logic (7 days, 5 meals/day)
- ❌ **KHÔNG** thay đổi lifestyle schedule structure (70 items/7 days)
- ❌ **KHÔNG** phá onboarding 7-step flow
- ❌ **KHÔNG** thay đổi notification scheduling logic
- ❌ **KHÔNG** refactor AIService imports (đã biết là architecture debt)


---

## 7. Checklist bắt buộc trước khi code UI

### Pre-coding Checklist

- [ ] **Đã đọc `UI_DEVELOPMENT_RULES.md` này chưa?**
- [ ] **Đã đọc `lib/core/theme/design_system.dart` chưa?**
- [ ] **Đã kiểm tra component tương tự trong `lib/shared/widgets/` chưa?**
- [ ] **Đã kiểm tra primitive components trong `lib/core/theme/primitives/` chưa?**
- [ ] **Đã xác định feature và vị trí file trong `lib/features/*/presentation/` chưa?**

### During Coding Checklist

- [ ] **Đã dùng `AppColorTokens` thay vì hardcode màu chưa?**
- [ ] **Đã dùng `AppSpacingTokens` thay vì hardcode spacing chưa?**
- [ ] **Đã dùng `AppRadiusTokens` thay vì hardcode radius chưa?**
- [ ] **Đã dùng `AppTextStyles` thay vì tạo TextStyle mới chưa?**
- [ ] **Đã check dark mode với `Theme.brightness` chưa?**
- [ ] **Đã xử lý loading/error/empty states chưa?**
- [ ] **Đã xử lý overflow với `Expanded`, `Flexible`, hoặc `maxLines` chưa?**
- [ ] **Đã dùng `AppButton`, `AppCard`, `AppInput` thay vì custom chưa?**
- [ ] **Đã giữ đúng provider/controller signatures chưa?**
- [ ] **Đã tách widget nếu lặp lại ≥3 lần chưa?**

### Post-coding Checklist

- [ ] **Code compile được không?** (`flutter analyze` pass?)
- [ ] **Responsive trên màn hình nhỏ chưa?**
- [ ] **Dark mode render đúng chưa?**
- [ ] **Touch targets ≥ 48dp chưa?**
- [ ] **Text contrast đủ chưa?**
- [ ] **Loading states hoạt động chưa?**
- [ ] **Error states có retry action chưa?**
- [ ] **Empty states có hướng dẫn chưa?**
- [ ] **Giọng văn UI nhẹ nhàng, thân thiện chưa?**
- [ ] **KHÔNG hardcode theme values chứ?**
- [ ] **KHÔNG phá provider/controller/route hiện có chứ?**

---

## 8. Setup context cho AI khi lập trình UI

### 8.1. Files bắt buộc phải đọc trước

**Thứ tự đọc khuyến nghị**:

1. **`UI_DEVELOPMENT_RULES.md`** (file này) - Đọc toàn bộ
2. **`.codex/CODEX_CONTEXT_ULTRA_COMPACT.md`** - Context tổng quan
3. **`lib/core/theme/design_system.dart`** - Design system exports
4. **`lib/core/theme/tokens/color_tokens.dart`** - Color semantic tokens
5. **`lib/core/theme/tokens/component_tokens.dart`** - Component tokens
6. **`lib/core/theme/primitives/*.dart`** - Primitive components nếu cần dùng


### 8.2. Khi làm việc với feature cụ thể

**Nếu sửa/thêm UI cho Onboarding**:
```
Đọc:
- lib/features/onboarding/presentation/pages/onboarding_page.dart
- lib/features/onboarding/presentation/widgets/onboarding_step_shell.dart
- lib/features/onboarding/presentation/widgets/onboarding_chip.dart
- lib/features/onboarding/providers/onboarding_provider.dart
```

**Nếu sửa/thêm UI cho Dashboard**:
```
Đọc:
- lib/features/dashboard/presentation/pages/dashboard_page.dart
- lib/features/dashboard/providers/dashboard_provider.dart
```

**Nếu sửa/thêm UI cho Meal Plan**:
```
Đọc:
- lib/features/meal_plan/presentation/pages/meal_plan_page.dart
- lib/features/meal_plan/providers/meal_plan_provider.dart
```

### 8.3. Folders ưu tiên tra cứu

**Khi cần tìm component có sẵn**:
1. `lib/core/theme/primitives/` - Design system primitives
2. `lib/shared/widgets/` - Shared components
3. `lib/features/{feature}/presentation/widgets/` - Feature-specific widgets

**Khi cần tìm theme values**:
1. `lib/core/theme/tokens/` - Semantic tokens (ƯU TIÊN)
2. `lib/core/theme/` - Legacy theme files (backward-compatible)

**Khi cần tìm provider/controller**:
1. `lib/features/{feature}/providers/` - Feature providers
2. `lib/features/{feature}/presentation/controllers/` - UI controllers

### 8.4. Files KHÔNG được sửa nếu không có yêu cầu

- ❌ `lib/app/app.dart` - App shell
- ❌ `lib/main.dart` - Entry point
- ❌ `lib/core/router/app_router.dart` - Router config
- ❌ `lib/core/constants/routes/route_names.dart` - Route constants
- ❌ `lib/core/storage/localdb/database_service.dart` - Database service
- ❌ `lib/services/**` - Core services
- ❌ Provider public APIs - Tên và signatures


### 8.5. Cách tìm component có sẵn

**Bước 1**: Search trong primitives
```bash
# Tìm button component
grep -r "class AppButton" lib/core/theme/primitives/

# Tìm card component
grep -r "class AppCard" lib/core/theme/primitives/

# Tìm input component
grep -r "class AppInput" lib/core/theme/primitives/
```

**Bước 2**: Search trong shared widgets
```bash
# Tìm shared widgets
ls lib/shared/widgets/
```

**Bước 3**: Search trong feature widgets
```bash
# Tìm trong feature cụ thể
ls lib/features/onboarding/presentation/widgets/
```

### 8.6. Cách xác định page/widget thuộc feature nào

**Pattern**: `lib/features/{feature_name}/presentation/`

- `lib/features/onboarding/presentation/` → Onboarding feature
- `lib/features/dashboard/presentation/` → Dashboard feature
- `lib/features/meal_plan/presentation/` → Meal Plan feature
- `lib/features/lifestyle_schedule/presentation/` → Lifestyle Schedule feature
- `lib/features/ai_chat/presentation/` → AI Chat feature

### 8.7. Cách thêm UI mới đúng kiến trúc

**Thêm page mới**:
```
1. Tạo file: lib/features/{feature}/presentation/pages/{name}_page.dart
2. Implement ConsumerWidget hoặc StatefulWidget
3. Connect với provider: ref.watch(featureProvider)
4. Thêm route vào app_router.dart
5. Thêm route name vào route_names.dart (nếu cần)
```

**Thêm widget mới**:
```
1. Kiểm tra xem có thể dùng primitive component không?
2. Nếu không, kiểm tra shared/widgets
3. Nếu vẫn không, tạo widget trong feature:
   lib/features/{feature}/presentation/widgets/{name}_widget.dart
4. Nếu widget dùng >1 feature, consider move sang shared/widgets
```

**Thêm component reusable**:
```
1. Nếu UI-only, không có business logic:
   → lib/shared/widgets/{name}.dart
   
2. Nếu là primitive của design system:
   → lib/core/theme/primitives/{name}.dart
   (CHỈ khi được yêu cầu mở rộng design system)
```


### 8.8. Cách refactor UI cũ an toàn

**Step 1: Read before refactor**
```dart
// Đọc file cần refactor
// Hiểu logic hiện tại
// Identify dependencies (providers, controllers)
```

**Step 2: Prepare**
```dart
// ✅ Kiểm tra test coverage
flutter test test/features/{feature}/

// ✅ Check diagnostics
flutter analyze
```

**Step 3: Refactor từng bước nhỏ**
```dart
// ✅ GOOD - Refactor từng phần
// 1. Thay hardcode colors → AppColorTokens
// 2. Thay hardcode spacing → AppSpacingTokens
// 3. Thay custom widgets → Primitive components
// 4. Test sau mỗi bước

// ❌ BAD - Refactor toàn bộ một lúc
// → Dễ break logic
```

**Step 4: Preserve behavior**
```dart
// ✅ MUST - Giữ nguyên behavior
// - Provider/controller calls
// - Callbacks
// - Navigation
// - Business logic

// ❌ NEVER - Đổi behavior khi refactor UI
```

**Step 5: Test sau refactor**
```dart
flutter test
flutter analyze
// Manual test: Loading, Error, Empty states
// Manual test: Dark mode
// Manual test: Responsive
```

### 8.9. Cách báo cáo nếu thiếu file/context

**Format báo cáo**:
```
⚠️ THIẾU CONTEXT

Tôi cần thêm thông tin để hoàn thành task:

**Đã đọc**:
- UI_DEVELOPMENT_RULES.md
- lib/core/theme/design_system.dart
- lib/features/onboarding/presentation/pages/onboarding_page.dart

**Thiếu**:
- [ ] Provider logic: lib/features/onboarding/providers/onboarding_provider.dart
- [ ] Controller state: Cần biết OnboardingState structure

**Câu hỏi**:
1. OnboardingState có fields nào?
2. nextStep() method có parameters không?

**Đề xuất**:
Có thể cung cấp file onboarding_provider.dart để tôi hiểu đầy đủ flow?
```


---

## 9. Prompt mẫu dùng lại cho AI

### 9.1. Prompt chuẩn khi sửa màn hình UI

```
Tôi cần sửa UI cho màn hình {TÊN_MÀN_HÌNH}.

YÊU CẦU:
1. Đọc UI_DEVELOPMENT_RULES.md
2. Đọc lib/core/theme/design_system.dart
3. Đọc file UI hiện tại: {ĐƯỜNG_DẪN_FILE}
4. Giữ đúng kiến trúc Feature-first
5. KHÔNG phá controller/provider/route hiện có
6. KHÔNG hardcode theme values
7. Dùng AppColorTokens, AppSpacingTokens, AppTextStyles
8. Dùng AppButton, AppCard, AppInput thay vì custom
9. Xử lý loading/error/empty states
10. Check dark mode support

THAY ĐỔI CẦN THỰC HIỆN:
{MÔ TẢ THAY ĐỔI CỤ THỂ}

OUTPUT YÊU CẦU:
- Code hoàn chỉnh, compile được
- Giải thích những gì đã thay đổi
- List các token/component đã dùng
- Note về dark mode handling
```

### 9.2. Prompt tạo component mới

```
Tôi cần tạo một component mới: {TÊN_COMPONENT}

YÊU CẦU:
1. Đọc UI_DEVELOPMENT_RULES.md
2. Kiểm tra xem đã có primitive component tương tự chưa trong lib/core/theme/primitives/
3. Kiểm tra shared/widgets xem có thể reuse không
4. Nếu cần tạo mới:
   - Dùng AppColorTokens cho colors
   - Dùng AppSpacingTokens cho spacing
   - Dùng AppRadiusTokens cho radius
   - Dùng AppTextStyles cho text
   - Support dark mode
   - Handle loading/error states nếu có

MÔ TẢ COMPONENT:
{MÔ TẢ CHỨC NĂNG}

PROPS/PARAMETERS:
{DANH SÁCH PROPS}

VÍ DỤ SỬ DỤNG:
{VÍ DỤ CODE}

OUTPUT:
- Code component hoàn chỉnh
- Ví dụ sử dụng
- Documentation comments
```


### 9.3. Prompt refactor UI cũ

```
Tôi cần refactor UI của {TÊN_FILE} để tuân thủ design system.

YÊU CẦU:
1. Đọc UI_DEVELOPMENT_RULES.md
2. Đọc file hiện tại: {ĐƯỜNG_DẪN_FILE}
3. Đọc providers/controllers liên quan
4. GIỮ NGUYÊN 100% behavior và logic
5. CHỈ refactor UI/styling

REFACTOR TASKS:
- [ ] Thay hardcode colors → AppColorTokens
- [ ] Thay hardcode spacing → AppSpacingTokens
- [ ] Thay hardcode radius → AppRadiusTokens
- [ ] Thay hardcode text styles → AppTextStyles
- [ ] Thay custom buttons → AppButton
- [ ] Thay custom cards → AppCard
- [ ] Thay custom inputs → AppInput
- [ ] Add dark mode support
- [ ] Add loading/error/empty states nếu thiếu

⚠️ CRITICAL:
- KHÔNG đổi provider/controller calls
- KHÔNG đổi navigation logic
- KHÔNG đổi business logic
- KHÔNG đổi callbacks/events

OUTPUT:
- Refactored code
- List changes made
- Before/After comparison cho key changes
```

### 9.4. Prompt debug UI issues

```
Tôi gặp vấn đề UI: {MÔ TẢ VẤN ĐỀ}

FILE LIÊN QUAN:
{ĐƯỜNG_DẪN_FILE}

CHECKLIST DEBUG:
1. Đã check UI_DEVELOPMENT_RULES.md chưa?
2. Đã check design_system.dart chưa?
3. Có hardcode theme values không?
4. Có dùng deprecated API không? (.withOpacity)
5. Dark mode có vấn đề không?
6. Responsive có vấn đề không?
7. Có overflow không?
8. Loading/error states có thiếu không?

VẤN ĐỀ CỤ THỂ:
{MÔ TẢ CHI TIẾT}

YÊU CẦU:
- Xác định root cause
- Đề xuất solution tuân thủ design system
- Code fix hoàn chỉnh
```



### 9.3. Prompt refactor UI cũ

```
Tôi cần refactor UI của {TÊN_FILE} để tuân thủ design system.

YÊU CẦU:
1. Đọc UI_DEVELOPMENT_RULES.md
2. Đọc file hiện tại: {ĐƯỜNG_DẪN_FILE}
3. Đọc providers/controllers liên quan
4. GIỮ NGUYÊN 100% behavior và logic
5. CHỈ refactor UI/styling

REFACTOR TASKS:
- [ ] Thay hardcode colors → AppColorTokens
- [ ] Thay hardcode spacing → AppSpacingTokens
- [ ] Thay hardcode radius → AppRadiusTokens
- [ ] Thay hardcode text styles → AppTextStyles
- [ ] Thay custom buttons → AppButton
- [ ] Thay custom cards → AppCard
- [ ] Thay custom inputs → AppInput
- [ ] Add dark mode support
- [ ] Add loading/error/empty states nếu thiếu

⚠️ CRITICAL:
- KHÔNG đổi provider/controller calls
- KHÔNG đổi navigation logic
- KHÔNG đổi business logic
- KHÔNG đổi callbacks/events

OUTPUT:
- Refactored code
- List changes made
- Before/After comparison cho key changes
```

### 9.4. Prompt debug UI issues

```
Tôi gặp vấn đề UI: {MÔ TẢ VẤN ĐỀ}

FILE LIÊN QUAN:
{ĐƯỜNG_DẪN_FILE}

CHECKLIST DEBUG:
1. Đã check UI_DEVELOPMENT_RULES.md chưa?
2. Đã check design_system.dart chưa?
3. Có hardcode theme values không?
4. Có dùng deprecated API không? (.withOpacity)
5. Dark mode có vấn đề không?
6. Responsive có vấn đề không?
7. Có overflow không?
8. Loading/error states có thiếu không?

VẤN ĐỀ CỤ THỂ:
{MÔ TẢ CHI TIẾT}

YÊU CẦU:
- Xác định root cause
- Đề xuất solution tuân thủ design system
- Code fix hoàn chỉnh
```

---

## 10. Summary và Next Steps

### 10.1. Những điểm quan trọng nhất

1. **⭐ Token-based Design System** - LUÔN dùng semantic tokens (Layer 2)
2. **⭐ Primitive Components** - Ưu tiên AppButton, AppCard, AppInput
3. **⭐ Dark Mode** - Check `Theme.brightness` và dùng dark variants
4. **⭐ KHÔNG hardcode** - Màu, spacing, radius, text styles
5. **⭐ Feature-first Architecture** - Giữ cấu trúc presentation/widgets/pages
6. **⭐ State Management** - UI gọi controller/provider, không gọi trực tiếp API
7. **⭐ Giọng văn** - Nhẹ nhàng, thân thiện, không phán xét (ứng dụng sức khỏe)
8. **⭐ Loading/Error/Empty** - Luôn xử lý đầy đủ 3 states

### 10.2. Files thiếu hoặc cần bổ sung

**Chưa đủ dữ liệu** về:
- Chi tiết implementation của `EmptyState`, `LoadingState`, `ErrorState` widgets
- Chi tiết của `AppChip`, `AppBadge` primitives
- Legacy constants trong `lib/core/constants/app/` (AppRadius, AppSpacing cũ)
- Detailed provider/controller implementations cho từng feature

**Đề xuất**: Nếu cần làm việc với features cụ thể, nên đọc thêm:
- Provider files trong `lib/features/{feature}/providers/`
- Controller files trong `lib/features/{feature}/presentation/controllers/`

### 10.3. Đề xuất bước tiếp theo chuẩn hóa UI

**Phase 1: Cleanup hiện tại**
1. Replace `.withOpacity()` → `.withValues()` toàn project
2. Identify hardcoded values và tạo tasks refactor

**Phase 2: Migrate legacy theme**
1. Audit code đang dùng `import 'theme.dart'`
2. Migrate từng file sang `import 'design_system.dart'`
3. Test sau mỗi migration batch

**Phase 3: Complete primitives**
1. Implement thiếu EmptyState, LoadingState, ErrorState nếu chưa có
2. Document AppChip, AppBadge usage
3. Create reusable patterns (glass button, floating orbs)

**Phase 4: Feature audit**
1. Audit từng feature để đảm bảo tuân thủ design system
2. Refactor Dashboard sections để remove mock/fallback
3. Complete Settings UI wiring

---

## Appendix: Quick Reference

### Import Paths

```dart
// ✅ NEW - Design System (Ưu tiên)
import 'package:nano_app/core/theme/design_system.dart';

// ⚠️ LEGACY - Backward Compatible (code cũ)
import 'package:nano_app/core/theme/theme.dart';

// Primitives (nếu cần import riêng)
import 'package:nano_app/core/theme/primitives/button.dart';
import 'package:nano_app/core/theme/primitives/card.dart';
import 'package:nano_app/core/theme/primitives/input.dart';
```

### Common Patterns

```dart
// Dark mode check
final isDark = Theme.of(context).brightness == Brightness.dark;

// Semantic color
final textColor = isDark 
    ? AppColorTokens.darkTextPrimary 
    : AppColorTokens.textPrimary;

// Button
AppButton(
  variant: ButtonVariant.primary,
  onPressed: () {},
  child: Text('Save'),
)

// Card
AppCard(
  variant: CardVariant.defaultCard,
  child: content,
)

// Input
AppInput(
  variant: InputVariant.textField,
  label: 'Name',
  controller: controller,
)

// Section Header
SectionHeader(
  title: 'Title',
  subtitle: 'Subtitle',
  actionLabel: 'View All',
  onAction: () {},
)
```

---

**END OF DOCUMENT**

