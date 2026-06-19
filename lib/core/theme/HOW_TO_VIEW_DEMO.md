# Cách Xem Design System Demo Page

## 🎨 Design System Demo Page đã được tạo!

File: `lib/core/theme/design_system_demo_page.dart`

Demo page này hiển thị:
- ✅ Tất cả primitive components với variants
- ✅ Design tokens (colors, spacing, radius, typography)
- ✅ Light/Dark mode toggle
- ✅ Interactive examples
- ✅ State widgets (loading, empty, error)

---

## 🚀 Cách 1: Thay Thế Home Page Tạm Thời (Nhanh Nhất)

### Bước 1: Mở file `lib/main.dart`

### Bước 2: Import demo page

Thêm import ở đầu file:

```dart
import 'core/theme/design_system_demo_page.dart';
```

### Bước 3: Thay `home` trong MaterialApp

Tìm dòng `home: ...` hoặc `initialLocation: ...` và comment out, sau đó thêm:

```dart
// Before:
// home: const SplashPage(),

// After (temporary):
home: const DesignSystemDemoPage(),
```

### Bước 4: Run app

```bash
flutter run
```

### Bước 5: Xem demo và test

- Toggle light/dark mode với icon ở AppBar
- Click vào sidebar để xem các sections khác nhau
- Test các interactive elements (buttons, chips, inputs)

### Bước 6: Revert về home page cũ

Sau khi xem xong, uncomment lại home page cũ:

```dart
// Restore:
home: const SplashPage(),
// home: const DesignSystemDemoPage(),
```

---

## 🚀 Cách 2: Thêm Route Mới (Khuyến Nghị)

### Bước 1: Mở `lib/app_versions/v1/router/app_router.dart`

### Bước 2: Import demo page

```dart
import '../theme/design_system_demo_page.dart';
```

### Bước 3: Thêm route mới

Trong `routes:` list, thêm:

```dart
GoRoute(
  path: '/design-system-demo',
  name: 'design-system-demo',
  builder: (context, state) => const DesignSystemDemoPage(),
),
```

### Bước 4: Navigate đến demo page

Từ bất kỳ đâu trong app, navigate:

```dart
context.go('/design-system-demo');
// hoặc
context.pushNamed('design-system-demo');
```

Hoặc tạo một button tạm trong app:

```dart
ElevatedButton(
  onPressed: () => context.go('/design-system-demo'),
  child: const Text('View Design System'),
)
```

---

## 🚀 Cách 3: Run Standalone (Test Riêng)

### Tạo file test main

Tạo file `lib/main_demo.dart`:

```dart
import 'package:flutter/material.dart';
import 'core/theme/design_system_demo_page.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: DesignSystemDemoPage(),
  ));
}
```

### Run file này

```bash
flutter run lib/main_demo.dart
```

---

## 📸 Sections Trong Demo Page

### 1. **Components** (Default)
- Buttons (5 variants)
- Cards (3 variants)  
- Chips (4 examples)
- Inputs (3 types)
- Badges (8 examples)
- Section Headers (3 examples)

### 2. **Tokens**
- Color swatches
- Spacing examples
- Radius examples

### 3. **Typography**
- All text styles
- Size comparisons

### 4. **States**
- Loading state
- Empty state
- Error state

---

## 🎯 Những Gì Cần Test

### ✅ Visual Testing
- [ ] Tất cả components hiển thị đúng
- [ ] Colors match design tokens
- [ ] Spacing consistent
- [ ] Border radius correct

### ✅ Interaction Testing
- [ ] Buttons clickable và show loading state
- [ ] Chips toggle selection
- [ ] Inputs accept text
- [ ] Cards show tap feedback

### ✅ Theme Testing
- [ ] Toggle light/dark mode
- [ ] Verify colors change correctly
- [ ] Check text readability in both modes
- [ ] Verify shadows visible in both modes

### ✅ Responsive Testing
- [ ] Test on different screen sizes
- [ ] Sidebar navigation works
- [ ] Content scrollable

---

## 🐛 Nếu Gặp Lỗi

### Lỗi Import
Nếu gặp lỗi import:

```dart
// Make sure you have:
import 'package:nano_app/core/theme/design_system.dart';
```

### Lỗi Theme
Nếu colors không hiển thị đúng, check:
- `Theme.of(context).brightness` đang return đúng giá trị
- Dark mode toggle đang update state

### Lỗi Layout
Nếu layout bị vỡ:
- Check screen size
- Try full screen vs windowed mode
- Check sidebar width

---

## 📝 Sau Khi Test Xong

### Findings cần note:
1. **Bugs phát hiện** → Fix trong primitives
2. **Missing features** → Add vào components
3. **Visual issues** → Update tokens
4. **Performance issues** → Optimize

### Next Steps:
1. Fix bugs nếu có
2. Verify tất cả primitives hoạt động đúng
3. Bắt đầu refactor Onboarding với confidence!

---

## 💡 Tips

- **Screenshot** mỗi section để reference sau này
- **Test thoroughly** trong both light và dark mode
- **Note any issues** để fix trước khi refactor production code
- **Share with team** để gather feedback

---

**Demo page này là công cụ quan trọng để ensure design system hoạt động đúng trước khi migrate production code!**
