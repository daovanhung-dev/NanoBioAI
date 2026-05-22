# Login UI Refactor Issue

## Module

Auth

## File

`login_page.dart`

---

## Overview

File `login_page.dart` hiện đang chứa gần như toàn bộ phần UI, state management và reusable widget của màn hình đăng nhập trong cùng một file.

Điều này làm cho module Auth khó mở rộng, khó maintain và chưa đúng định hướng Feature-first + Clean Architecture của dự án BioAI.

Ngoài ra hiện tại design system của project đã có đầy đủ:

- Theme system
- Decoration system
- Typography
- Shadow
- Animation
- Gradient
- Spacing
- Radius

=> nhưng Login UI vẫn chưa được tách theo reusable UI architecture.

---

# Current Problems

## 1. `login_page.dart` quá lớn

File đang chứa:

- Full layout
- Form logic
- Animation UI
- Decorative widgets
- Input widgets
- Social auth widgets
- Validation
- Background rendering

=> Vi phạm nguyên tắc:

> One responsibility per file

---

## 2. Stateful Widget quản lý quá nhiều responsibility

`_LoginPageState` hiện đang xử lý:

- Form state
- Loading state
- Password visibility
- Validation
- Entire widget rendering
- Animation state

Điều này gây:

- Coupling UI + logic
- Khó test
- Khó mở rộng social auth
- Khó migrate sang Riverpod state

---

## 3. Widget private đang bị nhúng trực tiếp trong page

Các widget như:

- `_BrandMark`
- `_InputField`
- `_SocialButton`
- `_BackgroundOrbs`
- `_Orb`

đều đang nằm trực tiếp trong file page.

=> Không reusable cho:

- Register page
- Forgot password page
- OTP page
- Onboarding auth flow

---

## 4. Form validation đang hardcoded trong UI

Validation hiện đang viết inline:

```dart
validator: (value) {
  ...
}
```

Điều này dẫn đến:

- Khó tái sử dụng
- Logic validation bị duplicate
- Khó maintain khi thay đổi rule auth

Validation nên được tách về:

```txt
core/constants/validation/
```

---

## 5. UI chưa chia theo section architecture

Login UI hiện chưa được modular theo:

- Header section
- Form section
- Social auth section
- Footer section
- Background effect section

=> Sau này scale auth module sẽ rất khó maintain.

---

## 6. Decorative UI chưa reusable

Các thành phần:

- Orb
- Blur effect
- Glassmorphism
- Gradient overlay

đang hardcoded riêng cho Login page.

=> Cần reuse design system thay vì custom inline.

---

## 7. UI chưa tối ưu scalability cho Auth Module

Authentication module sẽ còn mở rộng thêm:

- OTP Verification
- Forgot Password
- Social Login
- Apple Login
- Multi-step onboarding

Nếu tiếp tục giữ toàn bộ UI trong một file:

- Sẽ rất khó maintain
- Dễ duplicate code
- Khó mở rộng animation/state

---

# Refactor Goals

## Mục tiêu chính

Tách `login_page.dart` thành hệ thống component modular, reusable và scalable theo chuẩn BioAI Architecture.

---

# Expected Folder Structure

```txt
features/
└── auth/
    └── presentation/
        ├── pages/
        │   └── login_page.dart
        │
        ├── widgets/
        │   ├── login_background.dart
        │   ├── login_glass_card.dart
        │   ├── login_header.dart
        │   ├── login_form.dart
        │   ├── login_input_field.dart
        │   ├── login_password_field.dart
        │   ├── login_social_section.dart
        │   ├── social_login_button.dart
        │   ├── remember_me_section.dart
        │   ├── forgot_password_button.dart
        │   ├── register_redirect.dart
        │   ├── decorative_orbs.dart
        │   └── auth_primary_button.dart
        │
        └── providers/
```

---

# Refactor Requirements

## 1. Tách UI components

Mỗi section phải là widget riêng.

Ví dụ:

```txt
LoginHeader
LoginForm
LoginSocialSection
LoginBackground
```

---

## 2. Reusable input system

Tạo reusable auth input:

```txt
AuthTextField
AuthPasswordField
```

Có support:

- validation
- prefix icon
- suffix icon
- loading
- error state
- focus state

---

## 3. Tách validation layer

Validation phải đưa về:

```txt
core/constants/validation/
```

Ví dụ:

```txt
email_validator.dart
password_validator.dart
```

---

## 4. Reuse design system

Bắt buộc sử dụng:

- `AppColors`
- `AppTextStyles`
- `AppSpacing`
- `AppRadius`
- `AppDecoration`
- `AppGradients`
- `AppAnimations`

---

## 5. Chuẩn bị cho Riverpod migration

State không nên phụ thuộc trực tiếp vào StatefulWidget.

Cần chuẩn bị:

- loading provider
- auth form provider
- remember me provider
- password visibility provider

---

## 6. Reusable auth components cho toàn module

Component phải dùng lại được cho:

- Register
- Forgot Password
- OTP
- Reset Password

---

# Expected Benefits

Sau refactor:

- File nhỏ hơn
- Dễ maintain
- Dễ scale
- UI reusable
- Dễ test
- Dễ migrate state management
- Chuẩn Clean Architecture
- Đồng bộ Design System
- Hỗ trợ future auth expansion

---

# Priority

High

---

# Labels

```txt
refactor
ui
auth
flutter
clean-architecture
modular-ui
tech-debt
```
