# Login UI Refactor TODO

## Module

Auth

## Target File

`login_page.dart`

---

# Main Goal

Tách toàn bộ Login UI thành hệ thống component modular, reusable và scalable theo chuẩn BioAI Architecture.

---

# TODO LIST

## 1. Tách Login Layout

### Tasks

- [ ] Tạo `login_background.dart`
- [ ] Tạo `login_glass_card.dart`
- [ ] Tách layout wrapper khỏi `login_page.dart`
- [ ] Tách background gradient
- [ ] Tách blur / glassmorphism layer
- [ ] Tách decorative overlay

### Expected Result

`login_page.dart` chỉ còn nhiệm vụ:

- render page
- connect providers
- handle navigation

---

## 2. Tách Header Section

### Tasks

- [ ] Tạo `login_header.dart`
- [ ] Tách logo UI
- [ ] Tách app branding
- [ ] Tách subtitle / description
- [ ] Hỗ trợ reusable cho Register / Forgot Password

### Expected Result

Header trở thành reusable auth component.

---

## 3. Tách Login Form

### Tasks

- [ ] Tạo `login_form.dart`
- [ ] Tách form state
- [ ] Tách submit handler
- [ ] Tách validation trigger
- [ ] Tách loading UI

### Expected Result

Form có thể tái sử dụng cho:

- login
- register
- forgot password
- reset password

---

## 4. Tạo Reusable Auth Input

### Tasks

- [ ] Tạo `auth_text_field.dart`
- [ ] Tạo `auth_password_field.dart`
- [ ] Support error state
- [ ] Support loading state
- [ ] Support suffix icon
- [ ] Support prefix icon
- [ ] Support obscure toggle
- [ ] Support reusable validator

### Expected Result

Auth module có input system riêng và reusable.

---

## 5. Tách Validation Layer

### Tasks

- [ ] Tạo `email_validator.dart`
- [ ] Tạo `password_validator.dart`
- [ ] Chuyển toàn bộ validation khỏi UI
- [ ] Loại bỏ inline validator
- [ ] Reuse validator cho Register page

### Expected Result

Validation nằm trong:

```txt
core/constants/validation/
```

---

## 6. Tách Remember Me Section

### Tasks

- [ ] Tạo `remember_me_section.dart`
- [ ] Tách checkbox state
- [ ] Tách remember logic

### Expected Result

Reusable component cho future auth flows.

---

## 7. Tách Forgot Password Action

### Tasks

- [ ] Tạo `forgot_password_button.dart`
- [ ] Tách navigation logic
- [ ] Tách text button style

### Expected Result

Có thể tái sử dụng ở nhiều auth screens.

---

## 8. Tạo Reusable Auth Button

### Tasks

- [ ] Tạo `auth_primary_button.dart`
- [ ] Support loading state
- [ ] Support disabled state
- [ ] Support animation
- [ ] Reuse AppTheme button style

### Expected Result

Toàn bộ auth module dùng chung button system.

---

## 9. Tách Social Login Section

### Tasks

- [ ] Tạo `login_social_section.dart`
- [ ] Tạo `social_login_button.dart`
- [ ] Tách Google login button
- [ ] Tách Apple login button
- [ ] Tách divider section

### Expected Result

Social auth scalable và reusable.

---

## 10. Tách Register Redirect Section

### Tasks

- [ ] Tạo `register_redirect.dart`
- [ ] Tách navigation text
- [ ] Tách CTA action

### Expected Result

Reusable footer auth navigation component.

---

## 11. Tách Decorative Components

### Tasks

- [ ] Tạo `decorative_orbs.dart`
- [ ] Tạo reusable `orb.dart`
- [ ] Tách animation logic
- [ ] Tách blur effect
- [ ] Tách positioning logic

### Expected Result

Decorative UI reusable cho:

- splash
- onboarding
- auth
- dashboard hero

---

## 12. Reuse Design System

### Tasks

- [ ] Replace hardcoded colors
- [ ] Replace hardcoded radius
- [ ] Replace hardcoded spacing
- [ ] Replace hardcoded shadows
- [ ] Replace hardcoded text styles
- [ ] Replace hardcoded gradients
- [ ] Replace hardcoded durations

### Required Classes

- `AppColors`
- `AppTextStyles`
- `AppSpacing`
- `AppRadius`
- `AppShadows`
- `AppGradients`
- `AppDecoration`
- `AppDuration`

### Expected Result

UI đồng bộ hoàn toàn với global theme system.

---

## 13. Chuẩn bị Riverpod State Management

### Tasks

- [ ] Tạo auth form provider
- [ ] Tạo loading provider
- [ ] Tạo password visibility provider
- [ ] Tạo remember me provider
- [ ] Loại bỏ state logic khỏi StatefulWidget

### Expected Result

UI dễ migrate sang scalable architecture.

---

## 14. Performance Optimization

### Tasks

- [ ] Dùng const widget khi có thể
- [ ] Giảm rebuild không cần thiết
- [ ] Tách animation khỏi main tree
- [ ] Optimize blur usage
- [ ] Optimize glass effect

### Expected Result

Login UI mượt và tối ưu hiệu năng.

---

## 15. Final Cleanup

### Tasks

- [ ] Giảm size `login_page.dart`
- [ ] Remove duplicated code
- [ ] Remove inline styles
- [ ] Remove private reusable widgets
- [ ] Check responsive layout
- [ ] Check dark mode compatibility
- [ ] Check tablet support

---

# Expected Final Structure

```txt
features/
└── auth/
    └── presentation/
        ├── pages/
        │   └── login_page.dart
        │
        ├── widgets/
        │   ├── auth_primary_button.dart
        │   ├── auth_password_field.dart
        │   ├── auth_text_field.dart
        │   ├── decorative_orbs.dart
        │   ├── forgot_password_button.dart
        │   ├── login_background.dart
        │   ├── login_form.dart
        │   ├── login_glass_card.dart
        │   ├── login_header.dart
        │   ├── login_social_section.dart
        │   ├── register_redirect.dart
        │   ├── remember_me_section.dart
        │   └── social_login_button.dart
        │
        └── providers/
```

---

# Priority

High

---

# Labels

```txt
todo
refactor
flutter
auth
ui
clean-architecture
modular-ui
tech-debt
```
