# 🏥 BioAI - AI-Powered Health Tracking Application

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.9.2-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)

**Ứng dụng mobile AI-powered giúp người dùng theo dõi sức khỏe cá nhân, gợi ý kế hoạch dinh dưỡng và phân tích lối sống thông qua AI.**

[Features](#-features) • [Tech Stack](#-tech-stack) • [Getting Started](#-getting-started) • [Architecture](#-architecture) • [Documentation](#-documentation)

</div>

---

## 📋 Table of Contents

- [About](#-about)
- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Getting Started](#-getting-started)
- [Project Structure](#-project-structure)
- [Design System](#-design-system)
- [Development](#-development)
- [Testing](#-testing)
- [Deployment](#-deployment)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 About

**BioAI** là ứng dụng mobile theo dõi sức khỏe cá nhân được xây dựng trên nền tảng Flutter, tích hợp Google Gemini AI để cung cấp:

- 📊 Theo dõi sức khỏe toàn diện (BMI, giấc ngủ, stress)
- 🍽️ Kế hoạch dinh dưỡng 7 ngày được AI cá nhân hóa
- 💬 Tư vấn sức khỏe thông minh qua AI Chat
- 📱 Offline-first: Dữ liệu lưu trữ local, bảo mật cao
- 🎨 Modern UI với design system mới

### 🎯 Target Users

- Người dùng quan tâm đến sức khỏe và dinh dưỡng
- Người muốn quản lý cân nặng và lối sống
- Người cần tư vấn dinh dưỡng cá nhân hóa

---

## ✨ Features

### 🔐 **Authentication**
- Đăng nhập/Đăng ký qua Supabase
- Email/Password authentication
- Secure session management

### 📝 **Onboarding (7-Step Wizard)**
1. **Welcome** - Giới thiệu ứng dụng
2. **Basic Info** - Thông tin cơ bản (tên, giới tính, chiều cao, cân nặng)
3. **Health Goals** - Mục tiêu sức khỏe (giảm cân, tăng cơ, cải thiện giấc ngủ...)
4. **Health Conditions** - Tình trạng sức khỏe hiện tại
5. **Lifestyle** - Thói quen ăn uống, vận động, giấc ngủ
6. **Extras** - Dị ứng thực phẩm, điều trị y tế
7. **Review** - Xem lại thông tin và bắt đầu

### 🏠 **Dashboard**
- Tổng quan sức khỏe (BMI, cân nặng, chiều cao)
- Health goals tracking
- Health insights từ AI
- Quick actions

### 🍽️ **AI Meal Planning**
- Kế hoạch dinh dưỡng 7 ngày do Gemini AI sinh
- Dựa trên health profile cá nhân
- Chi tiết dinh dưỡng (calories, protein, carbs, fat, fiber)
- Gợi ý món ăn phù hợp với điều kiện sức khỏe

### 💬 **AI Chat** (Coming Soon)
- Tư vấn sức khỏe 24/7
- Trả lời câu hỏi về dinh dưỡng
- Gợi ý thực đơn realtime

### 🎨 **Modern Design System**
- 3-layer token architecture (Foundation → Semantic → Component)
- 9 primitive components
- Light/Dark mode support
- Accessible & responsive

---

## 🛠️ Tech Stack

### **Core**
- **Framework**: Flutter 3.9.2+
- **Language**: Dart 3.0+
- **State Management**: Riverpod 3.3.1
- **Navigation**: GoRouter 17.2.3

### **Backend & Services**
- **Authentication**: Supabase 2.12.4
- **AI Service**: Google Gemini 2.5 Flash
- **Local Database**: SQLite (sqflite 2.4.2)
- **HTTP Client**: Dio

### **UI & Design**
- **Design System**: Custom 3-layer token architecture
- **Theme**: Light/Dark mode support
- **Icons**: Material Icons + Custom

### **Development**
- **Environment**: flutter_dotenv
- **Preferences**: shared_preferences
- **Code Generation**: build_runner

### **Testing** (Planned)
- flutter_test
- mockito
- integration_test

---

## 🏗️ Architecture

### **Pattern**: Feature-First + Clean Architecture

```
lib/
├── core/                    # Core utilities & shared resources
│   ├── constants/           # App constants
│   ├── router/              # Navigation (GoRouter)
│   ├── storage/             # Database & preferences
│   ├── theme/               # Design system (NEW!)
│   └── utils/               # Helper functions
│
├── features/                # Feature modules
│   ├── auth/                # Authentication
│   ├── onboarding/          # 7-step health wizard
│   ├── dashboard/           # Home screen
│   ├── meal_plan/           # AI meal planning
│   ├── ai_chat/             # AI chat assistant
│   └── [feature]/
│       ├── data/            # Data layer
│       │   ├── datasources/ # API/DB access
│       │   └── models/      # Data models
│       ├── domain/          # Business logic
│       │   ├── entities/    # Domain entities
│       │   └── repositories/# Repository interfaces
│       ├── presentation/    # UI layer
│       │   ├── pages/       # Screens
│       │   ├── controllers/ # Riverpod controllers
│       │   └── widgets/     # UI components
│       └── providers/       # Riverpod providers
│
├── services/                # External services
│   ├── ai/                  # Gemini AI integration
│   └── supabase/            # Supabase client
│
└── shared/                  # Shared widgets
    └── widgets/             # Reusable components
```

### **Data Flow**

```
UI (Page)
  ↓ watch/read
Provider (Riverpod)
  ↓
Controller (Notifier / AsyncNotifier)
  ↓
Repository (Interface + Implementation)
  ↓
Datasource (SQLite / Supabase)
  ↓
Database / API
```

### **Key Architectural Decisions**

| Decision | Rationale |
|----------|-----------|
| SQLite as primary storage | Offline-first, privacy-focused |
| Supabase for auth only | Minimize cloud dependency |
| Gemini AI for meal plans | Personalized nutrition recommendations |
| Riverpod Notifier (Gen 3) | Type-safe, modern state management |
| Feature-first structure | Better scalability & maintaiNability |

---

## 🚀 Getting Started

### **Prerequisites**

- Flutter SDK: `>=3.9.2`
- Dart SDK: `>=3.0.0`
- Android Studio / VS Code
- Git

### **1. Clone Repository**

```bash
git clone https://github.com/your-org/nano_app.git
cd nano_app
```

### **2. Install Dependencies**

```bash
flutter pub get
```

### **3. Setup Environment**

Copy the environment template:

```bash
cp .env.example .env
```

Edit `.env` and add your API keys:

```env
# Supabase (Get from: https://supabase.com/dashboard)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key

# Google Gemini AI (Get from: https://makersuite.google.com/app/apikey)
GEMINI_API_KEY=your-gemini-api-key
GEMINI_PLAN_MODEL=gemini-3.1-flash-lite
GEMINI_PLAN_FALLBACK_MODELS=gemini-3.5-flash,gemini-2.5-flash-lite,gemini-2.5-flash
GEMINI_PLAN_OVERFLOW_MODELS=
```

### **4. Run the App**

```bash
# Debug mode
flutter run

# Release mode
flutter run --release

# Specific device
flutter run -d chrome        # Web
flutter run -d android       # Android
flutter run -d ios           # iOS
```

### **5. Build**

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

---

## 📁 Project Structure

```
nano_app/
├── .kiro/                   # Kiro AI specs & documentation
│   ├── specs/               # Feature specifications
│   └── steering/            # AI steering files
│
├── android/                 # Android platform files
├── ios/                     # iOS platform files
├── web/                     # Web platform files
│
├── assets/                  # Static assets
│   ├── fonts/               # Custom fonts
│   ├── icons/               # App icons
│   └── animations/          # Animation files
│
├── lib/                     # Main source code
│   ├── main.dart            # Entry point
│   ├── app/                 # App configuration
│   ├── core/                # Core utilities
│   ├── features/            # Feature modules
│   ├── services/            # External services
│   └── shared/              # Shared widgets
│
├── test/                    # Unit & widget tests
├── integration_test/        # Integration tests
│
├── docs/                    # Additional documentation
│   ├── issues/              # Known issues
│   └── changelog/           # Change history
│
├── .env.example             # Environment template
├── .gitignore               # Git ignore rules
├── pubspec.yaml             # Dependencies
├── analysis_options.yaml    # Lint rules
├── README.md                # This file
└── SECURITY.md              # Security guidelines
```

---

## 🎨 Design System

BioAI sử dụng **3-layer token architecture** mới:

### **Layer 1: Foundation Tokens**
Primitive, immutable values:
- Colors: 28 colors
- Spacing: Base-8 scale (10 values)
- Radius: 7 levels
- Shadows: 5 definitions
- Typography: Font scale
- Motion: Durations & curves
- Gradients: 5 gradients

### **Layer 2: Semantic Tokens**
Context-aware mappings:
- Color tokens: 29 mappings (light/dark)
- Spacing tokens: 15 tokens
- Component tokens: Radius, shadow, motion, text styles

### **Layer 3: Primitive Components**
Reusable UI building blocks:
- `AppButton` (5 variants)
- `AppCard` (3 variants)
- `AppChip` (3 variants)
- `AppInput` (3 variants)
- `AppBadge` (3 variants + 5 statuses)
- `SectionHeader`
- `EmptyState`, `LoadingState`, `ErrorState`

### **Usage**

```dart
import 'package:nano_app/core/theme/design_system.dart';

// Use semantic tokens
Container(
  color: AppColorTokens.surface,
  padding: EdgeInsets.all(AppSpacingTokens.pagePadding),
  child: AppButton(
    variant: ButtonVariant.primary,
    onPressed: () {},
    child: Text('Click Me'),
  ),
)
```

📚 **Documentation**: See `lib/core/theme/IMPLEMENTATION_STATUS.md`

🎨 **Demo Page**: `lib/core/theme/design_system_demo_page.dart`

---

## 💻 Development

### **Code Style**

This project follows [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines.

```bash
# Format code
flutter format .

# Analyze code
flutter analyze

# Run linter
dart fix --apply
```

### **Git Workflow**

```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Commit with conventional commits
git commit -m "feat: add new feature"
git commit -m "fix: resolve bug"
git commit -m "docs: update readme"

# Push and create PR
git push origin feature/your-feature-name
```

### **Conventional Commits**

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting)
- `refactor:` - Code refactoring
- `test:` - Adding tests
- `chore:` - Maintenance tasks

### **Hot Reload & Hot Restart**

```bash
# Hot reload (r)
r

# Hot restart (R)
R

# Quit (q)
q
```

---

## 🧪 Testing

### **Run Tests**

```bash
# All tests
flutter test

# Specific test file
flutter test test/features/auth/auth_test.dart

# With coverage
flutter test --coverage

# Integration tests
flutter test integration_test/app_test.dart
```

### **Test Structure**

```
test/
├── features/
│   ├── auth/
│   │   ├── auth_repository_test.dart
│   │   └── auth_controller_test.dart
│   └── onboarding/
├── services/
│   └── ai_service_test.dart
└── widgets/
    └── button_test.dart
```

### **Writing Tests**

```dart
void main() {
  group('AuthRepository', () {
    late AuthRepository repository;
    
    setUp(() {
      repository = AuthRepositoryImpl();
    });
    
    test('should login successfully', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';
      
      // Act
      final result = await repository.login(email, password);
      
      // Assert
      expect(result, isA<Success>());
    });
  });
}
```

---

## 🚀 Deployment

### **Android**

1. **Setup Signing**:
   - Create `android/key.properties`
   - Add signing config to `android/app/build.gradle`

2. **Build**:
   ```bash
   flutter build appbundle --release
   ```

3. **Upload to Play Store**:
   - Use `android/app/build/outputs/bundle/release/app-release.aab`

### **iOS**

1. **Setup**:
   - Configure signing in Xcode
   - Set up provisioning profiles

2. **Build**:
   ```bash
   flutter build ios --release
   ```

3. **Upload to App Store**:
   - Archive in Xcode
   - Upload via App Store Connect

### **Web**

```bash
flutter build web --release
```

Deploy to:
- Firebase Hosting
- Netlify
- Vercel
- GitHub Pages

---

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

### **1. Fork & Clone**

```bash
git clone https://github.com/your-username/nano_app.git
```

### **2. Create Branch**

```bash
git checkout -b feature/your-feature
```

### **3. Make Changes**

- Follow code style guidelines
- Add tests for new features
- Update documentation

### **4. Test**

```bash
flutter test
flutter analyze
```

### **5. Commit & Push**

```bash
git commit -m "feat: add your feature"
git push origin feature/your-feature
```

### **6. Create Pull Request**

- Describe your changes
- Link related issues
- Wait for review

### **Code Review Checklist**

- [ ] Code follows style guidelines
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No breaking changes (or documented)
- [ ] Passes all CI checks

---

## 📚 Documentation

- **Architecture**: `.codex/architecture.md`
- **Features**: `.codex/features.md`
- **Design System**: `lib/core/theme/IMPLEMENTATION_STATUS.md`
- **Security**: `SECURITY.md`
- **Codex**: `.codex/` (AI-readable project documentation)

---

## 🔐 Security

**⚠️ NEVER commit:**
- `.env` files
- `*.db` database files
- API keys or secrets
- Signing certificates

See `SECURITY.md` for detailed security guidelines.

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👥 Team

- **Project Lead**: [Your Name]
- **Developers**: [Team Members]
- **Designers**: [Design Team]

---

## 📞 Contact & Support

- **Issues**: [GitHub Issues](https://github.com/your-org/nano_app/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-org/nano_app/discussions)
- **Email**: support@bioai.com

---

## 🙏 Acknowledgments

- [Flutter Team](https://flutter.dev) - Amazing framework
- [Riverpod](https://riverpod.dev) - State management
- [Supabase](https://supabase.com) - Backend services
- [Google AI](https://ai.google.dev) - Gemini AI

---

## 📊 Project Status

- **Version**: 0.1.0
- **Status**: 🟢 Active Development
- **Last Updated**: 2026-06-13

### **Roadmap**

- [x] Authentication
- [x] Onboarding flow
- [x] Dashboard
- [x] AI Meal Planning
- [x] Design System
- [ ] AI Chat
- [ ] Sleep Tracking
- [ ] Stress Management
- [ ] Community Features

---

<div align="center">

**Made with ❤️ using Flutter**

[⬆ Back to Top](#-bioai---ai-powered-health-tracking-application)

</div>
